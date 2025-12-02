/// Result printing infrastructure for fluent-asserts.
/// Provides interfaces and implementations for formatting and displaying assertion results.
module fluentasserts.results.printer;

import std.stdio;
import std.algorithm;
import std.conv;
import std.range;
import std.string;

public import fluentasserts.results.message;
public import fluentasserts.results.source : SourceResult;

@safe:

/// Interface for printing assertion results.
/// Implementations can customize how different message types are displayed.
interface ResultPrinter {
  nothrow:
    /// Prints a structured message
    void print(Message);

    /// Prints primary/default text
    void primary(string);

    /// Prints informational text
    void info(string);

    /// Prints error/danger text
    void danger(string);

    /// Prints success text
    void success(string);

    /// Prints error text with reversed colors
    void dangerReverse(string);

    /// Prints success text with reversed colors
    void successReverse(string);
}

version (unittest) {
  /// Mock printer for testing purposes
  class MockPrinter : ResultPrinter {
    string buffer;

    void print(Message message) {
      import std.conv : to;

      try {
        buffer ~= "[" ~ message.type.to!string ~ ":" ~ message.text ~ "]";
      } catch (Exception) {
        buffer ~= "ERROR";
      }
    }

    void primary(string val) {
      buffer ~= "[primary:" ~ val ~ "]";
    }

    void info(string val) {
      buffer ~= "[info:" ~ val ~ "]";
    }

    void danger(string val) {
      buffer ~= "[danger:" ~ val ~ "]";
    }

    void success(string val) {
      buffer ~= "[success:" ~ val ~ "]";
    }

    void dangerReverse(string val) {
      buffer ~= "[dangerReverse:" ~ val ~ "]";
    }

    void successReverse(string val) {
      buffer ~= "[successReverse:" ~ val ~ "]";
    }
  }
}

/// Represents whitespace intervals in a string.
struct WhiteIntervals {
  /// Left whitespace count
  size_t left;

  /// Right whitespace count
  size_t right;
}

/// Gets the whitespace intervals (leading and trailing) in a string.
/// Params:
///   text = The text to analyze
/// Returns: WhiteIntervals with left and right whitespace positions
WhiteIntervals getWhiteIntervals(string text) {
  auto stripText = text.strip;

  if (stripText == "") {
    return WhiteIntervals(0, 0);
  }

  return WhiteIntervals(text.indexOf(stripText[0]), text.lastIndexOf(stripText[stripText.length - 1]));
}

/// Writes text to stdout without throwing exceptions.
void writeNoThrow(T)(T text) nothrow {
  try {
    write(text);
  } catch (Exception e) {
    assert(true, "Can't write to stdout!");
  }
}

/// Default implementation of ResultPrinter.
/// Prints all text types to stdout without formatting.
class DefaultResultPrinter : ResultPrinter {
  nothrow:

    void print(Message message) {
    }

    void primary(string text) {
      writeNoThrow(text);
    }

    void info(string text) {
      writeNoThrow(text);
    }

    void danger(string text) {
      writeNoThrow(text);
    }

    void success(string text) {
      writeNoThrow(text);
    }

    void dangerReverse(string text) {
      writeNoThrow(text);
    }

    void successReverse(string text) {
      writeNoThrow(text);
    }
}
