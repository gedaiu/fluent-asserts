/// Message types and display formatting for fluent-asserts.
/// Provides structures for representing and formatting assertion messages.
module fluentasserts.results.message;

import std.string;

@safe:

/// Glyphs used to display special characters in the results.
/// These can be customized for different terminal environments.
struct ResultGlyphs {
  static {
    /// Glyph for the tab character
    string tab;

    /// Glyph for the carriage return character
    string carriageReturn;

    /// Glyph for the newline character
    string newline;

    /// Glyph for the space character
    string space;

    /// Glyph for the null character
    string nullChar;

    /// Glyph for the bell character
    string bell;

    /// Glyph for the backspace character
    string backspace;

    /// Glyph for the vertical tab character
    string verticalTab;

    /// Glyph for the form feed character
    string formFeed;

    /// Glyph for the escape character
    string escape;

    /// Glyph that indicates the error line in source display
    string sourceIndicator;

    /// Glyph that separates the line number from source code
    string sourceLineSeparator;

    /// Glyph for the diff begin indicator
    string diffBegin;

    /// Glyph for the diff end indicator
    string diffEnd;

    /// Glyph that marks inserted text in diff
    string diffInsert;

    /// Glyph that marks deleted text in diff
    string diffDelete;
  }

  /// Resets all glyphs to their default values.
  /// Windows uses ASCII-compatible glyphs, other platforms use Unicode.
  static resetDefaults() {
    version (windows) {
      ResultGlyphs.tab = `\t`;
      ResultGlyphs.carriageReturn = `\r`;
      ResultGlyphs.newline = `\n`;
      ResultGlyphs.space = ` `;
      ResultGlyphs.nullChar = `␀`;
      ResultGlyphs.bell = `\a`;
      ResultGlyphs.backspace = `\b`;
      ResultGlyphs.verticalTab = `\v`;
      ResultGlyphs.formFeed = `\f`;
      ResultGlyphs.escape = `\e`;
    } else {
      ResultGlyphs.tab = `\t`;
      ResultGlyphs.carriageReturn = `\r`;
      ResultGlyphs.newline = `\n`;
      ResultGlyphs.space = ` `;
      ResultGlyphs.nullChar = `\0`;
      ResultGlyphs.bell = `\a`;
      ResultGlyphs.backspace = `\b`;
      ResultGlyphs.verticalTab = `\v`;
      ResultGlyphs.formFeed = `\f`;
      ResultGlyphs.escape = `\e`;
    }

    ResultGlyphs.sourceIndicator = ">";
    ResultGlyphs.sourceLineSeparator = ":";

    ResultGlyphs.diffBegin = "[";
    ResultGlyphs.diffEnd = "]";
    ResultGlyphs.diffInsert = "+";
    ResultGlyphs.diffDelete = "-";
  }
}

/// Represents a single message segment with a type and text content.
/// Messages are used to build up assertion failure descriptions.
struct Message {
  /// The type of message content
  enum Type {
    /// Informational text
    info,
    /// A value being displayed
    value,
    /// A section title
    title,
    /// A category label
    category,
    /// Inserted text in a diff
    insert,
    /// Deleted text in a diff
    delete_
  }

  /// The type of this message
  Type type;

  /// The text content of this message
  string text;

  /// Constructs a message with the given type and text.
  this(Type type, string text) nothrow @nogc {
    this.type = type;
    this.text = text;
  }

  /// Returns the raw text content. Use formattedText() for display with special formatting.
  string toString() nothrow @nogc inout {
    return text;
  }

  /// Returns the text with special character replacements and type-specific formatting.
  /// This allocates memory and should be used only for display purposes.
  string formattedText() nothrow inout {
    string content = text;

    if (type == Type.value || type == Type.insert || type == Type.delete_) {
      content = content
        .replace("\r", ResultGlyphs.carriageReturn)
        .replace("\n", ResultGlyphs.newline)
        .replace("\0", ResultGlyphs.nullChar)
        .replace("\t", ResultGlyphs.tab);
    }

    switch (type) {
      case Type.title:
        return "\n\n" ~ text ~ "\n";
      case Type.insert:
        return "[-" ~ content ~ "]";
      case Type.delete_:
        return "[+" ~ content ~ "]";
      case Type.category:
        return "\n" ~ text ~ "";
      default:
        return content;
    }
  }
}
