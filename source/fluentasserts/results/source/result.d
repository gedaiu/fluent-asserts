/// Source code context extraction for assertion failures.
module fluentasserts.results.source.result;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;

import dparse.lexer;

import fluentasserts.results.message;
import fluentasserts.results.printer : ResultPrinter;
import fluentasserts.results.source.pathcleaner;
import fluentasserts.results.source.tokens;
import fluentasserts.results.source.scopes;

@safe:

// Thread-local cache to avoid races when running tests in parallel.
// Module-level static variables in D are TLS by default.
private const(Token)[][string] fileTokensCache;

/// Source code location and token-based source retrieval.
/// Provides methods to extract and format source code context for assertion failures.
/// Uses lazy initialization to avoid expensive source parsing until actually needed.
struct SourceResult {
  /// The source file path
  string file;

  /// The line number in the source file
  size_t line;

  /// Internal storage for tokens (lazy-loaded)
  private const(Token)[] _tokens;
  private bool _tokensLoaded;

  /// Tokens representing the relevant source code (lazy-loaded)
  const(Token)[] tokens() nothrow @trusted {
    ensureTokensLoaded();
    return _tokens;
  }

  /// Creates a SourceResult with lazy token loading.
  /// Parsing is deferred until tokens are actually accessed.
  static SourceResult create(string fileName, size_t line) nothrow @trusted {
    SourceResult data;
    auto cleanedPath = fileName.cleanMixinPath;
    data.file = cleanedPath;
    data.line = line;
    data._tokensLoaded = false;
    return data;
  }

  /// Loads tokens if not already loaded (lazy initialization)
  private void ensureTokensLoaded() nothrow @trusted {
    if (_tokensLoaded) {
      return;
    }

    _tokensLoaded = true;

    string pathToUse = file.exists ? file : file;

    if (!pathToUse.exists) {
      return;
    }

    try {
      updateFileTokens(pathToUse);
      auto result = getScope(fileTokensCache[pathToUse], line);

      auto begin = getPreviousIdentifier(fileTokensCache[pathToUse], result.begin);
      begin = extendToLineStart(fileTokensCache[pathToUse], begin);
      auto end = getFunctionEnd(fileTokensCache[pathToUse], begin) + 1;

      _tokens = fileTokensCache[pathToUse][begin .. end];
    } catch (Throwable t) {
    }
  }

  /// Updates the token cache for a file if not already cached.
  static void updateFileTokens(string fileName) {
    if (fileName !in fileTokensCache) {
      fileTokensCache[fileName] = [];
      splitMultilinetokens(fileToDTokens(fileName), fileTokensCache[fileName]);
    }
  }

  /// Extracts the value expression from the source tokens.
  /// Returns: The value expression as a string
  string getValue() {
    auto toks = tokens;
    size_t begin;
    size_t end = getShouldIndex(toks, line);

    if (end != 0) {
      begin = toks.getPreviousIdentifier(end - 1);
      return toks[begin .. end - 1].tokensToString.strip;
    }

    auto beginAssert = getAssertIndex(toks, line);

    if (beginAssert > 0) {
      begin = beginAssert + 4;
      end = getParameter(toks, begin);
      return toks[begin .. end].tokensToString.strip;
    }

    return "";
  }

  /// Converts the source result to a string representation.
  string toString() nothrow {
    auto separator = leftJustify("", 20, '-');
    string result = "\n" ~ separator ~ "\n" ~ file ~ ":" ~ line.to!string ~ "\n" ~ separator;

    auto toks = tokens;

    if (toks.length == 0) {
      return result ~ "\n";
    }

    size_t currentLine = toks[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach (token; toks.filter!(token => token != tok!"whitespace")) {
      string prefix = "";

      foreach (lineNumber; currentLine .. token.line) {
        if (lineNumber < line - 1 || afterErrorLine) {
          prefix ~= "\n" ~ rightJustify((lineNumber + 1).to!string, 6, ' ') ~ ": ";
        } else {
          prefix ~= "\n>" ~ rightJustify((lineNumber + 1).to!string, 5, ' ') ~ ": ";
        }
      }

      if (token.line != currentLine) {
        column = 1;
      }

      if (token.column > column) {
        prefix ~= ' '.repeat.take(token.column - column).array;
      }

      auto stringRepresentation = token.text == "" ? str(token.type) : token.text;
      auto lines = stringRepresentation.split("\n");

      result ~= prefix ~ lines[0];
      currentLine = token.line;
      column = token.column + stringRepresentation.length;

      if (token.line >= line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    return result;
  }

  /// Converts the source result to an array of messages.
  immutable(Message)[] toMessages() nothrow {
    return [Message(Message.Type.info, toString())];
  }

  /// Prints the source result using the provided printer.
  void print(ResultPrinter printer) @safe nothrow {
    auto toks = tokens;

    if (toks.length == 0) {
      return;
    }

    printer.primary("\n");
    printer.info(file ~ ":" ~ line.to!string);

    size_t currentLine = toks[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach (token; toks.filter!(token => token != tok!"whitespace")) {
      foreach (lineNumber; currentLine .. token.line) {
        printer.primary("\n");

        if (lineNumber < line - 1 || afterErrorLine) {
          printer.primary(rightJustify((lineNumber + 1).to!string, 6, ' ') ~ ":");
        } else {
          printer.dangerReverse(">" ~ rightJustify((lineNumber + 1).to!string, 5, ' ') ~ ":");
        }
      }

      if (token.line != currentLine) {
        column = 1;
      }

      if (token.column > column) {
        printer.primary(' '.repeat.take(token.column - column).array);
      }

      auto stringRepresentation = token.text == "" ? str(token.type) : token.text;

      if (token.text == "" && str(token.type) != "whitespace") {
        printer.info(str(token.type));
      } else if (str(token.type).indexOf("Literal") != -1) {
        printer.success(token.text);
      } else {
        printer.primary(token.text);
      }

      currentLine = token.line;
      column = token.column + stringRepresentation.length;

      if (token.line >= line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    printer.primary("\n");
  }
}
