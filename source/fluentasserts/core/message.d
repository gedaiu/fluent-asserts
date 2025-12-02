/// Message types and display formatting for fluent-asserts.
/// Provides structures for representing and formatting assertion messages.
module fluentasserts.core.message;

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
  /// For value, insert, and delete types, special characters are replaced with glyphs.
  this(Type type, string text) nothrow {
    this.type = type;

    if (type == Type.value || type == Type.insert || type == Type.delete_) {
      this.text = text
        .replace("\r", ResultGlyphs.carriageReturn)
        .replace("\n", ResultGlyphs.newline)
        .replace("\0", ResultGlyphs.nullChar)
        .replace("\t", ResultGlyphs.tab);
    } else {
      this.text = text;
    }
  }

  /// Converts the message to a string representation.
  /// Titles and categories include newlines, inserts/deletes include markers.
  string toString() nothrow inout {
    switch (type) {
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
