module fluentasserts.core.asserts;

import std.string;
import std.conv;
import ddmp.diff;

import fluentasserts.core.message : Message, ResultGlyphs;

@safe:

struct DiffSegment {
  enum Operation { equal, insert, delete_ }

  Operation operation;
  string text;

  string toString() nothrow inout {
    auto displayText = text
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\0", ResultGlyphs.nullChar)
      .replace("\t", ResultGlyphs.tab);

    final switch(operation) {
      case Operation.equal:
        return displayText;
      case Operation.insert:
        return "[+" ~ displayText ~ "]";
      case Operation.delete_:
        return "[-" ~ displayText ~ "]";
    }
  }
}

struct AssertResult {
  immutable(Message)[] message;
  string expected;
  string actual;
  bool negated;
  immutable(DiffSegment)[] diff;
  string[] extra;
  string[] missing;

  bool hasContent() nothrow @safe inout {
    return expected.length > 0 || actual.length > 0
      || diff.length > 0 || extra.length > 0 || missing.length > 0;
  }

  string formatValue(string value) nothrow inout {
    return value
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\0", ResultGlyphs.nullChar)
      .replace("\t", ResultGlyphs.tab);
  }

  string messageString() nothrow @trusted inout {
    string result;
    foreach(m; message) {
      result ~= m.text;
    }
    return result;
  }

  string toString() nothrow @trusted inout {
    string result = messageString();

    if(diff.length > 0) {
      result ~= "\n\nDiff:\n";
      foreach(segment; diff) {
        result ~= segment.toString();
      }
    }

    if(expected.length > 0) {
      result ~= "\n Expected:";
      if(negated) {
        result ~= "not ";
      }
      result ~= formatValue(expected);
    }

    if(actual.length > 0) {
      result ~= "\n   Actual:" ~ formatValue(actual);
    }

    if(extra.length > 0) {
      result ~= "\n    Extra:";
      foreach(i, item; extra) {
        if(i > 0) result ~= ",";
        result ~= formatValue(item);
      }
    }

    if(missing.length > 0) {
      result ~= "\n  Missing:";
      foreach(i, item; missing) {
        if(i > 0) result ~= ",";
        result ~= formatValue(item);
      }
    }

    return result;
  }

  void add(immutable(Message) msg) nothrow @safe {
    message ~= msg;
  }

  void add(bool isValue, string text) nothrow {
    message ~= Message(isValue ? Message.Type.value : Message.Type.info, text
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\0", ResultGlyphs.nullChar)
      .replace("\t", ResultGlyphs.tab));
  }

  void addValue(string text) nothrow @safe {
    add(true, text);
  }

  void addText(string text) nothrow @safe {
    if(text == "throwAnyException") {
      text = "throw any exception";
    }
    message ~= Message(Message.Type.info, text);
  }

  void prependText(string text) nothrow @safe {
    message = Message(Message.Type.info, text) ~ message;
  }

  void prependValue(string text) nothrow @safe {
    message = Message(Message.Type.value, text) ~ message;
  }

  void startWith(string text) nothrow @safe {
    message = Message(Message.Type.info, text) ~ message;
  }

  void computeDiff(string expectedVal, string actualVal) nothrow @trusted {
    import ddmp.diff : diff_main, Operation;

    try {
      auto diffResult = diff_main(expectedVal, actualVal);
      DiffSegment[] segments;

      foreach(d; diffResult) {
        DiffSegment.Operation op;
        final switch(d.operation) {
          case Operation.EQUAL: op = DiffSegment.Operation.equal; break;
          case Operation.INSERT: op = DiffSegment.Operation.insert; break;
          case Operation.DELETE: op = DiffSegment.Operation.delete_; break;
        }
        segments ~= DiffSegment(op, d.text.to!string);
      }

      diff = cast(immutable(DiffSegment)[]) segments;
    } catch(Exception) {
    }
  }
}
