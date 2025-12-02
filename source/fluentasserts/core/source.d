/// Source code analysis and token parsing for fluent-asserts.
/// Provides functionality to extract and display source code context for assertion failures.
module fluentasserts.core.source;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.exception;
import std.typecons;

import dparse.lexer;
import dparse.parser;

import fluentasserts.core.message;
import fluentasserts.core.results : ResultPrinter;

@safe:

/// Source code location and token-based source retrieval.
/// Provides methods to extract and format source code context for assertion failures.
struct SourceResult {
  static private {
    const(Token)[][string] fileTokens;
  }

  /// The source file path
  string file;

  /// The line number in the source file
  size_t line;

  /// Tokens representing the relevant source code
  const(Token)[] tokens;

  /// Creates a SourceResult by parsing the source file and extracting relevant tokens.
  /// Params:
  ///   fileName = Path to the source file
  ///   line = Line number to extract context for
  /// Returns: A SourceResult with the extracted source context
  static SourceResult create(string fileName, size_t line) nothrow @trusted {
    SourceResult data;
    data.file = fileName;
    data.line = line;

    if (!fileName.exists) {
      return data;
    }

    try {
      updateFileTokens(fileName);
      auto result = getScope(fileTokens[fileName], line);

      auto begin = getPreviousIdentifier(fileTokens[fileName], result.begin);
      auto end = getFunctionEnd(fileTokens[fileName], begin) + 1;

      data.tokens = fileTokens[fileName][begin .. end];
    } catch (Throwable t) {
    }

    return data;
  }

  /// Updates the token cache for a file if not already cached.
  static void updateFileTokens(string fileName) {
    if (fileName !in fileTokens) {
      fileTokens[fileName] = [];
      splitMultilinetokens(fileToDTokens(fileName), fileTokens[fileName]);
    }
  }

  /// Extracts the value expression from the source tokens.
  /// Returns: The value expression as a string
  string getValue() {
    size_t begin;
    size_t end = getShouldIndex(tokens, line);

    if (end != 0) {
      begin = tokens.getPreviousIdentifier(end - 1);
      return tokens[begin .. end - 1].tokensToString.strip;
    }

    auto beginAssert = getAssertIndex(tokens, line);

    if (beginAssert > 0) {
      begin = beginAssert + 4;
      end = getParameter(tokens, begin);
      return tokens[begin .. end].tokensToString.strip;
    }

    return "";
  }

  /// Converts the source result to a string representation.
  string toString() nothrow {
    auto separator = leftJustify("", 20, '-');
    string result = "\n" ~ separator ~ "\n" ~ file ~ ":" ~ line.to!string ~ "\n" ~ separator;

    if (tokens.length == 0) {
      return result ~ "\n";
    }

    size_t currentLine = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach (token; tokens.filter!(token => token != tok!"whitespace")) {
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
  void print(ResultPrinter printer) {
    if (tokens.length == 0) {
      return;
    }

    printer.primary("\n");
    printer.info(file ~ ":" ~ line.to!string);

    size_t currentLine = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach (token; tokens.filter!(token => token != tok!"whitespace")) {
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

// ---------------------------------------------------------------------------
// Token parsing helper functions
// ---------------------------------------------------------------------------

/// Converts an array of tokens to a string representation.
string tokensToString(const(Token)[] tokens) {
  string result;

  foreach (token; tokens.filter!(a => str(a.type) != "comment")) {
    if (str(token.type) == "whitespace" && token.text == "") {
      result ~= "\n";
    } else {
      result ~= token.text == "" ? str(token.type) : token.text;
    }
  }

  return result;
}

/// Finds the scope boundaries containing a specific line.
auto getScope(const(Token)[] tokens, size_t line) nothrow {
  bool foundScope;
  bool foundAssert;
  size_t beginToken;
  size_t endToken = tokens.length;

  int paranthesisCount = 0;
  int scopeLevel;
  size_t[size_t] paranthesisLevels;

  foreach (i, token; tokens) {
    string type = str(token.type);

    if (type == "{") {
      paranthesisLevels[paranthesisCount] = i;
      paranthesisCount++;
    }

    if (type == "}") {
      paranthesisCount--;
    }

    if (line == token.line) {
      foundScope = true;
    }

    if (foundScope) {
      if (token.text == "should" || token.text == "Assert" || type == "assert" || type == ";") {
        foundAssert = true;
        scopeLevel = paranthesisCount;
      }

      if (type == "}" && paranthesisCount <= scopeLevel) {
        beginToken = paranthesisLevels[paranthesisCount];
        endToken = i + 1;

        break;
      }
    }
  }

  return const Tuple!(size_t, "begin", size_t, "end")(beginToken, endToken);
}

/// Finds the end of a function starting at a given token index.
size_t getFunctionEnd(const(Token)[] tokens, size_t start) {
  int paranthesisCount;
  size_t result = start;

  foreach (i, token; tokens[start .. $]) {
    string type = str(token.type);

    if (type == "(") {
      paranthesisCount++;
    }

    if (type == ")") {
      paranthesisCount--;
    }

    if (type == "{" && paranthesisCount == 0) {
      result = start + i;
      break;
    }

    if (type == ";" && paranthesisCount == 0) {
      return start + i;
    }
  }

  paranthesisCount = 0;

  foreach (i, token; tokens[result .. $]) {
    string type = str(token.type);

    if (type == "{") {
      paranthesisCount++;
    }

    if (type == "}") {
      paranthesisCount--;

      if (paranthesisCount == 0) {
        result = result + i;
        break;
      }
    }
  }

  return result;
}

/// Finds the previous identifier token before a given index.
size_t getPreviousIdentifier(const(Token)[] tokens, size_t startIndex) {
  enforce(startIndex > 0);
  enforce(startIndex < tokens.length);

  int paranthesisCount;
  bool foundIdentifier;

  foreach (i; 0 .. startIndex) {
    auto index = startIndex - i - 1;
    auto type = str(tokens[index].type);

    if (type == "(") {
      paranthesisCount--;
    }

    if (type == ")") {
      paranthesisCount++;
    }

    if (paranthesisCount < 0) {
      return getPreviousIdentifier(tokens, index - 1);
    }

    if (paranthesisCount != 0) {
      continue;
    }

    if (type == "unittest") {
      return index;
    }

    if (type == "{" || type == "}") {
      return index + 1;
    }

    if (type == ";") {
      return index + 1;
    }

    if (type == "=") {
      return index + 1;
    }

    if (type == ".") {
      foundIdentifier = false;
    }

    if (type == "identifier" && foundIdentifier) {
      foundIdentifier = true;
      continue;
    }

    if (foundIdentifier) {
      return index;
    }
  }

  return 0;
}

/// Finds the index of an Assert structure in the tokens.
size_t getAssertIndex(const(Token)[] tokens, size_t startLine) {
  auto assertTokens = tokens
    .enumerate
    .filter!(a => a[1].text == "Assert")
    .filter!(a => a[1].line <= startLine)
    .array;

  if (assertTokens.length == 0) {
    return 0;
  }

  return assertTokens[assertTokens.length - 1].index;
}

/// Gets the end index of a parameter in the token list.
auto getParameter(const(Token)[] tokens, size_t startToken) {
  size_t paranthesisCount;

  foreach (i; startToken .. tokens.length) {
    string type = str(tokens[i].type);

    if (type == "(" || type == "[") {
      paranthesisCount++;
    }

    if (type == ")" || type == "]") {
      if (paranthesisCount == 0) {
        return i;
      }

      paranthesisCount--;
    }

    if (paranthesisCount > 0) {
      continue;
    }

    if (type == ",") {
      return i;
    }
  }

  return 0;
}

/// Finds the index of the should call in the tokens.
size_t getShouldIndex(const(Token)[] tokens, size_t startLine) {
  auto shouldTokens = tokens
    .enumerate
    .filter!(a => a[1].text == "should")
    .filter!(a => a[1].line <= startLine)
    .array;

  if (shouldTokens.length == 0) {
    return 0;
  }

  return shouldTokens[shouldTokens.length - 1].index;
}

/// Converts a file to D tokens provided by libDParse.
const(Token)[] fileToDTokens(string fileName) nothrow @trusted {
  try {
    auto f = File(fileName);
    immutable auto fileSize = f.size();
    ubyte[] fileBytes = new ubyte[](fileSize.to!size_t);

    if (f.rawRead(fileBytes).length != fileSize) {
      return [];
    }

    StringCache cache = StringCache(StringCache.defaultBucketCount);

    LexerConfig config;
    config.stringBehavior = StringBehavior.source;
    config.fileName = fileName;
    config.commentBehavior = CommentBehavior.intern;

    auto lexer = DLexer(fileBytes, config, &cache);
    const(Token)[] tokens = lexer.array;

    return tokens.map!(token => const Token(token.type, token.text.idup, token.line, token.column, token.index)).array;
  } catch (Throwable) {
    return [];
  }
}

/// Splits multiline tokens into multiple single line tokens with the same type.
void splitMultilinetokens(const(Token)[] tokens, ref const(Token)[] result) nothrow @trusted {
  try {
    foreach (token; tokens) {
      auto pieces = token.text.idup.split("\n");

      if (pieces.length <= 1) {
        result ~= const Token(token.type, token.text.dup, token.line, token.column, token.index);
      } else {
        size_t line = token.line;
        size_t column = token.column;

        foreach (textPiece; pieces) {
          result ~= const Token(token.type, textPiece, line, column, token.index);
          line++;
          column = 1;
        }
      }
    }
  } catch (Throwable) {
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

version (unittest) {
  import fluentasserts.core.base;
}

@("getScope returns the spec function and scope that contains a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 101);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].tokensToString.strip.should.equal("it(\"should throw an exception if we request 2 android devices\", {
      ({
        auto result = [ device1.idup, device2.idup ].filterBy(RunOptions(\"\", \"android\", 2)).array;
      }).should.throwException!DeviceException.withMessage.equal(\"You requested 2 `androdid` devices, but there is only 1 healthy.\");
    }");
}

@("getScope returns a method scope and signature")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/class.d"), tokens);

  auto result = getScope(tokens, 10);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].tokensToString.strip.should.equal("void bar() {
        assert(false);
    }");
}

@("getScope returns a method scope without assert")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/class.d"), tokens);

  auto result = getScope(tokens, 14);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].tokensToString.strip.should.equal("void bar2() {
        enforce(false);
    }");
}

@("getFunctionEnd returns the end of a spec function with a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 101);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);
  auto functionEnd = getFunctionEnd(tokens, identifierStart);

  tokens[identifierStart .. functionEnd].tokensToString.strip.should.equal("it(\"should throw an exception if we request 2 android devices\", {
      ({
        auto result = [ device1.idup, device2.idup ].filterBy(RunOptions(\"\", \"android\", 2)).array;
      }).should.throwException!DeviceException.withMessage.equal(\"You requested 2 `androdid` devices, but there is only 1 healthy.\");
    })");
}

@("getFunctionEnd returns the end of an unittest function with a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 81);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);
  auto functionEnd = getFunctionEnd(tokens, identifierStart) + 1;

  tokens[identifierStart .. functionEnd].tokensToString.strip.should.equal("unittest {
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

}");
}

@("getScope returns tokens from a scope that contains a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 81);

  tokens[result.begin .. result.end].tokensToString.strip.should.equal(`{
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

}`);
}

@("getPreviousIdentifier returns the previous unittest identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 81);

  auto result = getPreviousIdentifier(tokens, scopeResult.begin);

  tokens[result .. scopeResult.begin].tokensToString.strip.should.equal(`unittest`);
}

@("getPreviousIdentifier returns the previous paranthesis identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 63);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`(5, (11))`);
}

@("getPreviousIdentifier returns the previous function call identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 75);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`found(4)`);
}

@("getPreviousIdentifier returns the previous map identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 85);

  auto end = scopeResult.end - 12;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`[1, 2, 3].map!"a"`);
}

@("getAssertIndex returns the index of the Assert structure identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getAssertIndex(tokens, 55);

  tokens[result .. result + 4].tokensToString.strip.should.equal(`Assert.equal(`);
}

@("getParameter returns the first parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 57) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].tokensToString.strip.should.equal(`(5, (11))`);
}

@("getParameter returns the first list parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 89) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].tokensToString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

@("getPreviousIdentifier returns the previous array identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 4);
  auto end = scopeResult.end - 13;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`[1, 2, 3]`);
}

@("getPreviousIdentifier returns the previous array of instances identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 90);
  auto end = scopeResult.end - 16;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

@("getShouldIndex returns the index of the should call")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getShouldIndex(tokens, 4);

  auto token = tokens[result];
  token.line.should.equal(3);
  token.text.should.equal(`should`);
  str(token.type).text.should.equal(`identifier`);
}
