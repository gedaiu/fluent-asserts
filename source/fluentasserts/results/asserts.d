/// Assertion result types for fluent-asserts.
/// Provides structures for representing assertion outcomes with diff support.
module fluentasserts.results.asserts;

import std.string;
import std.conv;
import ddmp.diff;

import fluentasserts.results.message : Message, ResultGlyphs;

@safe:

/// A fixed-size array for storing elements without GC allocation.
/// Useful for @nogc contexts where dynamic arrays would normally be used.
/// Template parameter T is the element type (e.g., char for strings, string for string arrays).
struct FixedArray(T, size_t N = 512) {
  private {
    T[N] _data = T.init;
    size_t _length;
  }

  /// Returns the current length.
  size_t length() @nogc nothrow @safe const {
    return _length;
  }

  /// Appends an element to the array.
  void opOpAssign(string op : "~")(T s) @nogc nothrow @safe {
    if (_length < N) {
      _data[_length++] = s;
    }
  }

  /// Returns the contents as a slice.
  inout(T)[] opSlice() @nogc nothrow @safe inout {
    return _data[0 .. _length];
  }

  /// Index operator.
  inout(T) opIndex(size_t i) @nogc nothrow @safe inout {
    return _data[i];
  }

  /// Clears the array.
  void clear() @nogc nothrow @safe {
    _length = 0;
  }

  /// Returns true if the array is empty.
  bool empty() @nogc nothrow @safe const {
    return _length == 0;
  }

  /// Returns the current length (for $ in slices).
  size_t opDollar() @nogc nothrow @safe const {
    return _length;
  }

  // Specializations for char type (string building)
  static if (is(T == char)) {
    /// Appends a string slice to the buffer (char specialization).
    void put(const(char)[] s) @nogc nothrow @safe {
      import std.algorithm : min;
      auto copyLen = min(s.length, N - _length);
      _data[_length .. _length + copyLen] = s[0 .. copyLen];
      _length += copyLen;
    }

    /// Assigns from a string (char specialization).
    void opAssign(const(char)[] s) @nogc nothrow @safe {
      clear();
      put(s);
    }

    /// Returns the current contents as a string slice.
    const(char)[] toString() @nogc nothrow @safe const {
      return _data[0 .. _length];
    }
  }
}

/// Alias for backward compatibility - fixed char buffer for string building
alias FixedAppender(size_t N = 512) = FixedArray!(char, N);

/// Alias for backward compatibility - fixed string reference array
alias FixedStringArray(size_t N = 32) = FixedArray!(string, N);

/// Represents a segment of a diff between expected and actual values.
struct DiffSegment {
  /// The type of diff operation
  enum Operation {
    /// Text is the same in both values
    equal,
    /// Text was inserted (present in actual but not expected)
    insert,
    /// Text was deleted (present in expected but not actual)
    delete_
  }

  /// The operation type for this segment
  Operation operation;

  /// The text content of this segment
  string text;

  /// Converts the segment to a displayable string with markers for inserts/deletes.
  string toString() nothrow inout {
    auto displayText = text
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\0", ResultGlyphs.nullChar)
      .replace("\t", ResultGlyphs.tab);

    final switch (operation) {
      case Operation.equal:
        return displayText;
      case Operation.insert:
        return "[+" ~ displayText ~ "]";
      case Operation.delete_:
        return "[-" ~ displayText ~ "]";
    }
  }
}

/// Holds the result of an assertion including expected/actual values and diff.
struct AssertResult {
  /// The message segments (stored as fixed array, accessed via messages())
  private {
    Message[32] _messages;
    size_t _messageCount;
  }

  /// Returns the active message segments as a slice
  inout(Message)[] messages() return inout nothrow @safe @nogc {
    return _messages[0 .. _messageCount];
  }

  /// The expected value as a fixed-size buffer
  FixedAppender!512 expected;

  /// The actual value as a fixed-size buffer
  FixedAppender!512 actual;

  /// Whether the assertion was negated
  bool negated;

  /// Diff segments between expected and actual
  immutable(DiffSegment)[] diff;

  /// Extra items found (for collection assertions)
  FixedStringArray!32 extra;

  /// Missing items (for collection assertions)
  FixedStringArray!32 missing;

  /// Returns true if the result has any content indicating a failure.
  bool hasContent() nothrow @safe @nogc const {
    return !expected.empty || !actual.empty
      || diff.length > 0 || extra.length > 0 || missing.length > 0;
  }

  /// Formats a value for display, replacing special characters with glyphs.
  string formatValue(string value) nothrow inout {
    return value
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\0", ResultGlyphs.nullChar)
      .replace("\t", ResultGlyphs.tab);
  }

  /// Returns the message as a plain string.
  string messageString() nothrow @trusted inout {
    string result;
    foreach (m; messages) {
      result ~= m.text;
    }
    return result;
  }

  /// Converts the entire result to a displayable string.
  string toString() nothrow @trusted inout {
    return messageString();
  }

  /// Adds a message to the result.
  void add(Message msg) nothrow @safe @nogc {
    if (_messageCount < _messages.length) {
      _messages[_messageCount++] = msg;
    }
  }

  /// Adds text to the result, optionally as a value type.
  void add(bool isValue, string text) nothrow {
    add(Message(isValue ? Message.Type.value : Message.Type.info, text));
  }

  /// Adds a value to the result.
  void addValue(string text) nothrow @safe {
    add(Message(Message.Type.value, text));
  }

  /// Adds informational text to the result.
  void addText(string text) nothrow @safe {
    if (text == "throwAnyException") {
      text = "throw any exception";
    }
    add(Message(Message.Type.info, text));
  }

  /// Prepends a message to the result (shifts existing messages).
  private void prepend(Message msg) nothrow @safe @nogc {
    if (_messageCount < _messages.length) {
      // Shift all existing messages to the right
      for (size_t i = _messageCount; i > 0; i--) {
        _messages[i] = _messages[i - 1];
      }
      _messages[0] = msg;
      _messageCount++;
    }
  }

  /// Prepends informational text to the result.
  void prependText(string text) nothrow @safe {
    prepend(Message(Message.Type.info, text));
  }

  /// Prepends a value to the result.
  void prependValue(string text) nothrow @safe {
    prepend(Message(Message.Type.value, text));
  }

  /// Starts the message with the given text.
  void startWith(string text) nothrow @safe {
    prepend(Message(Message.Type.info, text));
  }

  /// Computes the diff between expected and actual values.
  void computeDiff(string expectedVal, string actualVal) nothrow @trusted {
    import ddmp.diff : diff_main, Operation;

    try {
      auto diffResult = diff_main(expectedVal, actualVal);
      DiffSegment[] segments;

      foreach (d; diffResult) {
        DiffSegment.Operation op;
        final switch (d.operation) {
          case Operation.EQUAL: op = DiffSegment.Operation.equal; break;
          case Operation.INSERT: op = DiffSegment.Operation.insert; break;
          case Operation.DELETE: op = DiffSegment.Operation.delete_; break;
        }
        segments ~= DiffSegment(op, d.text.to!string);
      }

      diff = cast(immutable(DiffSegment)[]) segments;
    } catch (Exception) {
    }
  }
}
