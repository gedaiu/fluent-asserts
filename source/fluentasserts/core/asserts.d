/// Assertion result types for fluent-asserts.
/// Provides structures for representing assertion outcomes with diff support.
module fluentasserts.core.asserts;

import std.string;
import std.conv;
import ddmp.diff;

import fluentasserts.core.message : Message, ResultGlyphs;

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
  /// The message segments describing the assertion
  immutable(Message)[] message;

  /// The expected value as a string
  string expected;

  /// The actual value as a string
  string actual;

  /// Whether the assertion was negated
  bool negated;

  /// Diff segments between expected and actual
  immutable(DiffSegment)[] diff;

  /// Extra items found (for collection assertions)
  string[] extra;

  /// Missing items (for collection assertions)
  string[] missing;

  /// Returns true if the result has any content indicating a failure.
  bool hasContent() nothrow @safe inout {
    return expected.length > 0 || actual.length > 0
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
    foreach (m; message) {
      result ~= m.text;
    }
    return result;
  }

  /// Converts the entire result to a displayable string.
  string toString() nothrow @trusted inout {
    string result = messageString();

    if (diff.length > 0) {
      result ~= "\n\nDiff:\n";
      foreach (segment; diff) {
        result ~= segment.toString();
      }
    }

    if (expected.length > 0) {
      result ~= "\n Expected:";
      if (negated) {
        result ~= "not ";
      }
      result ~= formatValue(expected);
    }

    if (actual.length > 0) {
      result ~= "\n   Actual:" ~ formatValue(actual);
    }

    if (extra.length > 0) {
      result ~= "\n    Extra:";
      foreach (i, item; extra) {
        if (i > 0) result ~= ",";
        result ~= formatValue(item);
      }
    }

    if (missing.length > 0) {
      result ~= "\n  Missing:";
      foreach (i, item; missing) {
        if (i > 0) result ~= ",";
        result ~= formatValue(item);
      }
    }

    return result;
  }

  /// Adds a message to the result.
  void add(immutable(Message) msg) nothrow @safe {
    message ~= msg;
  }

  /// Adds text to the result, optionally as a value type.
  void add(bool isValue, string text) nothrow {
    message ~= Message(isValue ? Message.Type.value : Message.Type.info, text
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\0", ResultGlyphs.nullChar)
      .replace("\t", ResultGlyphs.tab));
  }

  /// Adds a value to the result.
  void addValue(string text) nothrow @safe {
    add(true, text);
  }

  /// Adds informational text to the result.
  void addText(string text) nothrow @safe {
    if (text == "throwAnyException") {
      text = "throw any exception";
    }
    message ~= Message(Message.Type.info, text);
  }

  /// Prepends informational text to the result.
  void prependText(string text) nothrow @safe {
    message = Message(Message.Type.info, text) ~ message;
  }

  /// Prepends a value to the result.
  void prependValue(string text) nothrow @safe {
    message = Message(Message.Type.value, text) ~ message;
  }

  /// Starts the message with the given text.
  void startWith(string text) nothrow @safe {
    message = Message(Message.Type.info, text) ~ message;
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
