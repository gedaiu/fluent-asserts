module fluentasserts.core.message;

import std.string;
import ddmp.diff;
import fluentasserts.core.results;
import std.algorithm;
import std.conv;

@safe:

/// Glyphs used to display special chars in the results
struct ResultGlyphs {
  static {
    /// Glyph for the tab char
    string tab;

    /// Glyph for the \r char
    string carriageReturn;

    /// Glyph for the \n char
    string newline;

    /// Glyph for the space char
    string space;

    /// Glyph for the \0 char
    string nullChar;

    /// Glyph that indicates the error line
    string sourceIndicator;

    /// Glyph that sepparates the line number
    string sourceLineSeparator;

    /// Glyph for the diff begin indicator
    string diffBegin;

    /// Glyph for the diff end indicator
    string diffEnd;

    /// Glyph that marks an inserted text in diff
    string diffInsert;

    /// Glyph that marks deleted text in diff
    string diffDelete;
  }

  /// Set the default values. The values are
  static resetDefaults() {
    version(windows) {
      ResultGlyphs.tab = `\t`;
      ResultGlyphs.carriageReturn = `\r`;
      ResultGlyphs.newline = `\n`;
      ResultGlyphs.space = ` `;
      ResultGlyphs.nullChar = `␀`;
    } else {
      ResultGlyphs.tab = `¤`;
      ResultGlyphs.carriageReturn = `←`;
      ResultGlyphs.newline = `↲`;
      ResultGlyphs.space = `᛫`;
      ResultGlyphs.nullChar = `\0`;
    }

    ResultGlyphs.sourceIndicator = ">";
    ResultGlyphs.sourceLineSeparator = ":";

    ResultGlyphs.diffBegin = "[";
    ResultGlyphs.diffEnd = "]";
    ResultGlyphs.diffInsert = "+";
    ResultGlyphs.diffDelete = "-";
  }
}

struct Message {
  enum Type {
    info,
    value,
    title,
    category,
    insert,
    delete_
  }

  Type type;
  string text;

  this(Type type, string text) nothrow {
    this.type = type;

    if(type == Type.value || type == Type.insert || type == Type.delete_) {
      this.text = text
        .replace("\r", ResultGlyphs.carriageReturn)
        .replace("\n", ResultGlyphs.newline)
        .replace("\0", ResultGlyphs.nullChar)
        .replace("\t", ResultGlyphs.tab);
    } else {
      this.text = text;
    }
  }

  string toString() nothrow inout {
    switch(type) {
      case Type.title:
        return "\n\n" ~ text ~ "\n";
      case Type.insert:
        return "[-" ~ text ~ "]";
      case Type.delete_:
        return "[+" ~ text ~ "]";
      case Type.category:
        return "\n" ~ text ~ "";
      default:
        return text;
    }
  }
}

public import fluentasserts.core.asserts : AssertResult, DiffSegment;

immutable(Message)[] toMessages(ref EvaluationResult result) nothrow {
  return result.messages;
}


struct EvaluationResult {
  private {
    immutable(Message)[] messages;
  }

  void add(immutable(Message) message) nothrow {
    messages ~= message;
  }

  string toString() nothrow {
    string result;

    foreach (message; messages) {
      result ~= message.toString;
    }

    return result;
  }

  void print(ResultPrinter printer) nothrow {
    foreach (message; messages) {
      printer.print(message);
    }
  }
}

static immutable actualTitle = Message(Message.Type.category, "Actual:");

void addResult(ref EvaluationResult result, string value) nothrow @trusted {
  result.add(actualTitle);

  result.add(Message(Message.Type.value, value));
}


static immutable expectedTitle = Message(Message.Type.category, "Expected:");
static immutable expectedNot = Message(Message.Type.info, "not ");

void addExpected(ref EvaluationResult result, bool isNegated, string value) nothrow @trusted {
  result.add(expectedTitle);

  if(isNegated) {
    result.add(expectedNot);
  }

  result.add(Message(Message.Type.value, value));
}


static immutable diffTitle = Message(Message.Type.title, "Diff:");

void addDiff(ref EvaluationResult result, string actual, string expected) nothrow @trusted {
  result.add(diffTitle);

  try {
    auto diffResult = diff_main(expected, actual);

    foreach(diff; diffResult) {
      if(diff.operation == Operation.EQUAL) {
        result.add(Message(Message.Type.info, diff.text.to!string));
      }

      if(diff.operation == Operation.INSERT) {
        result.add(Message(Message.Type.insert, diff.text.to!string));
      }

      if(diff.operation == Operation.DELETE) {
        result.add(Message(Message.Type.delete_, diff.text.to!string));
      }
    }
  } catch(Exception e) {
    return;
  }
}
