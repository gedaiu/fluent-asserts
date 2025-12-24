/// Assertion result types for fluent-asserts.
/// Provides structures for representing assertion outcomes with diff support.
module fluentasserts.results.asserts;

import std.string;

import fluentasserts.core.diff.diff : computeDiff;
import fluentasserts.core.diff.types : EditOp;
import fluentasserts.results.message : Message, ResultGlyphs;
import fluentasserts.core.memory.heapstring : HeapString;
public import fluentasserts.core.array : FixedArray, FixedAppender, FixedStringArray;

@safe:

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

  /// Returns the message as a HeapString.
  HeapString messageString() nothrow @trusted @nogc inout {
    // Calculate total size needed
    size_t totalSize = 0;
    foreach (ref m; messages) {
      totalSize += m.text.length;
    }

    // Preallocate and copy
    HeapString result = HeapString.create(totalSize);
    foreach (ref m; messages) {
      result.put(m.text[]);
    }
    return result;
  }

  /// Converts the entire result to a displayable string.
  string toString() nothrow @trusted inout {
    return messageString()[].idup;
  }

  /// Adds a message to the result.
  void add(Message msg) nothrow @safe @nogc {
    if (_messageCount < _messages.length) {
      _messages[_messageCount++] = msg;
    }
  }

  /// Removes the last message (if any).
  void popMessage() nothrow @safe @nogc {
    if (_messageCount > 0) {
      _messageCount--;
    }
  }

  /// Adds text to the result, optionally as a value type.
  void add(bool isValue, string text) nothrow {
    add(Message(isValue ? Message.Type.value : Message.Type.info, text));
  }

  /// Adds a value to the result.
  void addValue(string text) nothrow @safe @nogc {
    add(Message(Message.Type.value, text));
  }

  /// Adds a value to the result (const(char)[] overload).
  void addValue(const(char)[] text) nothrow @trusted @nogc {
    add(Message(Message.Type.value, cast(string) text));
  }

  /// Adds informational text to the result.
  void addText(string text) nothrow @safe @nogc {
    if (text == "throwAnyException") {
      text = "throw any exception";
    }
    add(Message(Message.Type.info, text));
  }

  /// Adds informational text to the result (const(char)[] overload).
  void addText(const(char)[] text) nothrow @trusted @nogc {
    add(Message(Message.Type.info, cast(string) text));
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
  void setDiff(string expectedVal, string actualVal) nothrow @trusted {
    import fluentasserts.core.memory.heapstring : toHeapString;

    auto a = toHeapString(expectedVal);
    auto b = toHeapString(actualVal);
    auto diffResult = computeDiff(a, b);

    DiffSegment[] segments;

    foreach (i; 0 .. diffResult.length) {
      auto d = diffResult[i];
      DiffSegment.Operation op;

      final switch (d.op) {
        case EditOp.equal: op = DiffSegment.Operation.equal; break;
        case EditOp.insert: op = DiffSegment.Operation.insert; break;
        case EditOp.remove: op = DiffSegment.Operation.delete_; break;
      }

      segments ~= DiffSegment(op, d.text[].idup);
    }

    diff = cast(immutable(DiffSegment)[]) segments;
  }
}
