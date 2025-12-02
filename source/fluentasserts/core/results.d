module fluentasserts.core.results;

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

public import fluentasserts.core.message;

@safe:

///
interface ResultPrinter {
  nothrow:
    void print(Message);
    void primary(string);
    void info(string);
    void danger(string);
    void success(string);

    void dangerReverse(string);
    void successReverse(string);
}

version(unittest) {
  class MockPrinter : ResultPrinter {
    string buffer;

    void print(Message message) {
      import std.conv : to;
      try {
        buffer ~= "[" ~ message.type.to!string ~ ":" ~ message.text ~ "]";
      } catch(Exception) {
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

struct WhiteIntervals {
  size_t left;
  size_t right;
}

WhiteIntervals getWhiteIntervals(string text) {
  auto stripText = text.strip;

  if(stripText == "") {
    return WhiteIntervals(0, 0);
  }

  return WhiteIntervals(text.indexOf(stripText[0]), text.lastIndexOf(stripText[stripText.length - 1]));
}

void writeNoThrow(T)(T text) nothrow {
  try {
    write(text);
  } catch(Exception e) {
    assert(true, "Can't write to stdout!");
  }
}

/// This is the most simple implementation of a ResultPrinter.
/// All the plain data is printed to stdout
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

version (unittest) {
  import fluentasserts.core.base;
}

string toString(const(Token)[] tokens) {
  string result;

  foreach(token; tokens.filter!(a => str(a.type) != "comment")) {
    if(str(token.type) == "whitespace" && token.text == "") {
      result ~= "\n";
    } else {
     result ~= token.text == "" ? str(token.type) : token.text;
    }
  }

  return result;
}

auto getScope(const(Token)[] tokens, size_t line) nothrow {
  bool foundScope;
  bool foundAssert;
  size_t beginToken;
  size_t endToken = tokens.length;

  int paranthesisCount = 0;
  int scopeLevel;
  size_t[size_t] paranthesisLevels;

  foreach(i, token; tokens) {
    string type = str(token.type);

    if(type == "{") {
      paranthesisLevels[paranthesisCount] = i;
      paranthesisCount++;
    }

    if(type == "}") {
      paranthesisCount--;
    }

    if(line == token.line) {
      foundScope = true;
    }

    if(foundScope) {
      if(token.text == "should" || token.text == "Assert" || type == "assert" || type == ";") {
        foundAssert = true;
        scopeLevel = paranthesisCount;
      }

      if(type == "}" && paranthesisCount <= scopeLevel) {
        beginToken = paranthesisLevels[paranthesisCount];
        endToken = i + 1;

        break;
      }
    }
  }

  return const Tuple!(size_t, "begin", size_t, "end")(beginToken, endToken);
}

@("getScope returns the spec function and scope that contains a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 101);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].toString.strip.should.equal("it(\"should throw an exception if we request 2 android devices\", {
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

  tokens[identifierStart .. result.end].toString.strip.should.equal("void bar() {
        assert(false);
    }");
}

@("getScope returns a method scope without assert")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/class.d"), tokens);

  auto result = getScope(tokens, 14);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].toString.strip.should.equal("void bar2() {
        enforce(false);
    }");
}

size_t getFunctionEnd(const(Token)[] tokens, size_t start) {
  int paranthesisCount;
  size_t result = start;

  // iterate the parameters
  foreach(i, token; tokens[start .. $]) {
    string type = str(token.type);

    if(type == "(") {
      paranthesisCount++;
    }

    if(type == ")") {
      paranthesisCount--;
    }

    if(type == "{" && paranthesisCount == 0) {
      result = start + i;
      break;
    }

    if(type == ";" && paranthesisCount == 0) {
      return start + i;
    }
  }

  paranthesisCount = 0;
  // iterate the scope
  foreach(i, token; tokens[result .. $]) {
    string type = str(token.type);

    if(type == "{") {
      paranthesisCount++;
    }

    if(type == "}") {
      paranthesisCount--;

      if(paranthesisCount == 0) {
        result = result + i;
        break;
      }
    }
  }

  return result;
}

@("getFunctionEnd returns the end of a spec function with a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 101);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);
  auto functionEnd = getFunctionEnd(tokens, identifierStart);

  tokens[identifierStart .. functionEnd].toString.strip.should.equal("it(\"should throw an exception if we request 2 android devices\", {
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

  tokens[identifierStart .. functionEnd].toString.strip.should.equal("unittest {
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

  tokens[result.begin .. result.end].toString.strip.should.equal(`{
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

}`);
}

size_t getPreviousIdentifier(const(Token)[] tokens, size_t startIndex) {
  enforce(startIndex > 0);
  enforce(startIndex < tokens.length);

  int paranthesisCount;
  bool foundIdentifier;

  foreach(i; 0..startIndex) {
    auto index = startIndex - i - 1;
    auto type = str(tokens[index].type);

    if(type == "(") {
      paranthesisCount--;
    }

    if(type == ")") {
      paranthesisCount++;
    }

    if(paranthesisCount < 0) {
      return getPreviousIdentifier(tokens, index - 1);
    }

    if(paranthesisCount != 0) {
      continue;
    }

    if(type == "unittest") {
      return index;
    }

    if(type == "{" || type == "}") {
      return index + 1;
    }

    if(type == ";") {
      return index + 1;
    }

    if(type == "=") {
      return index + 1;
    }

    if(type == ".") {
      foundIdentifier = false;
    }

    if(type == "identifier" && foundIdentifier) {
      foundIdentifier = true;
      continue;
    }

    if(foundIdentifier) {
      return index;
    }
  }

  return 0;
}

@("getPreviousIdentifier returns the previous unittest identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 81);

  auto result = getPreviousIdentifier(tokens, scopeResult.begin);

  tokens[result .. scopeResult.begin].toString.strip.should.equal(`unittest`);
}

@("getPreviousIdentifier returns the previous paranthesis identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 63);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`(5, (11))`);
}

@("getPreviousIdentifier returns the previous function call identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 75);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`found(4)`);
}

@("getPreviousIdentifier returns the previous map identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 85);

  auto end = scopeResult.end - 12;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`[1, 2, 3].map!"a"`);
}

size_t getAssertIndex(const(Token)[] tokens, size_t startLine) {
  auto assertTokens = tokens
    .enumerate
    .filter!(a => a[1].text == "Assert")
    .filter!(a => a[1].line <= startLine)
    .array;

  if(assertTokens.length == 0) {
    return 0;
  }

  return assertTokens[assertTokens.length - 1].index;
}

@("getAssertIndex returns the index of the Assert structure identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getAssertIndex(tokens, 55);

  tokens[result .. result + 4].toString.strip.should.equal(`Assert.equal(`);
}

auto getParameter(const(Token)[] tokens, size_t startToken) {
  size_t paranthesisCount;

  foreach(i; startToken..tokens.length) {
    string type = str(tokens[i].type);

    if(type == "(" || type == "[") {
      paranthesisCount++;
    }

    if(type == ")" || type == "]") {
      if(paranthesisCount == 0) {
        return i;
      }

      paranthesisCount--;
    }

    if(paranthesisCount > 0) {
      continue;
    }

    if(type == ",") {
      return i;
    }
  }


  return 0;
}

@("getParameter returns the first parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 57) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].toString.strip.should.equal(`(5, (11))`);
}

@("getParameter returns the first list parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 89) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].toString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

@("getPreviousIdentifier returns the previous array identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 4);
  auto end = scopeResult.end - 13;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`[1, 2, 3]`);
}

@("getPreviousIdentifier returns the previous array of instances identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 90);
  auto end = scopeResult.end - 16;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

size_t getShouldIndex(const(Token)[] tokens, size_t startLine) {
  auto shouldTokens = tokens
    .enumerate
    .filter!(a => a[1].text == "should")
    .filter!(a => a[1].line <= startLine)
    .array;

  if(shouldTokens.length == 0) {
    return 0;
  }

  return shouldTokens[shouldTokens.length - 1].index;
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

/// Source result data stored as a struct for efficiency
struct SourceResult {
  static private {
    const(Token)[][string] fileTokens;
  }

  string file;
  size_t line;
  const(Token)[] tokens;

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

  static void updateFileTokens(string fileName) {
    if(fileName !in fileTokens) {
      fileTokens[fileName] = [];
      splitMultilinetokens(fileToDTokens(fileName), fileTokens[fileName]);
    }
  }

  string getValue() {
    size_t begin;
    size_t end = getShouldIndex(tokens, line);

    if(end != 0) {
      begin = tokens.getPreviousIdentifier(end - 1);
      return tokens[begin .. end - 1].toString.strip;
    }

    auto beginAssert = getAssertIndex(tokens, line);

    if(beginAssert > 0) {
      begin = beginAssert + 4;
      end = getParameter(tokens, begin);
      return tokens[begin .. end].toString.strip;
    }

    return "";
  }

  string toString() nothrow {
    auto separator = leftJustify("", 20, '-');
    string result = "\n" ~ separator ~ "\n" ~ file ~ ":" ~ line.to!string ~ "\n" ~ separator;

    if(tokens.length == 0) {
      return result ~ "\n";
    }

    size_t currentLine = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach(token; tokens.filter!(token => token != tok!"whitespace")) {
      string prefix = "";

      foreach(lineNumber; currentLine..token.line) {
        if(lineNumber < line - 1 || afterErrorLine) {
          prefix ~= "\n" ~ rightJustify((lineNumber+1).to!string, 6, ' ') ~ ": ";
        } else {
          prefix ~= "\n>" ~ rightJustify((lineNumber+1).to!string, 5, ' ') ~ ": ";
        }
      }

      if(token.line != currentLine) {
        column = 1;
      }

      if(token.column > column) {
        prefix ~= ' '.repeat.take(token.column - column).array;
      }

      auto stringRepresentation = token.text == "" ? str(token.type) : token.text;
      auto lines = stringRepresentation.split("\n");

      result ~= prefix ~ lines[0];
      currentLine = token.line;
      column = token.column + stringRepresentation.length;

      if(token.line >= line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    return result;
  }

  immutable(Message)[] toMessages() nothrow {
    return [Message(Message.Type.info, toString())];
  }

  void print(ResultPrinter printer) {
    if(tokens.length == 0) {
      return;
    }

    printer.primary("\n");
    printer.info(file ~ ":" ~ line.to!string);

    size_t currentLine = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach(token; tokens.filter!(token => token != tok!"whitespace")) {
      foreach(lineNumber; currentLine..token.line) {
        printer.primary("\n");

        if(lineNumber < line - 1 || afterErrorLine) {
          printer.primary(rightJustify((lineNumber+1).to!string, 6, ' ') ~ ":");
        } else {
          printer.dangerReverse(">" ~ rightJustify((lineNumber+1).to!string, 5, ' ') ~ ":");
        }
      }

      if(token.line != currentLine) {
        column = 1;
      }

      if(token.column > column) {
        printer.primary(' '.repeat.take(token.column - column).array);
      }

      auto stringRepresentation = token.text == "" ? str(token.type) : token.text;

      if(token.text == "" && str(token.type) != "whitespace") {
        printer.info(str(token.type));
      } else if(str(token.type).indexOf("Literal") != -1) {
        printer.success(token.text);
      } else {
        printer.primary(token.text);
      }

      currentLine = token.line;
      column = token.column + stringRepresentation.length;

      if(token.line >= line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    printer.primary("\n");
  }
}

/// Converts a file to D tokens provided by libDParse.
/// All the whitespaces are ignored
const(Token)[] fileToDTokens(string fileName) nothrow @trusted {
  try {
    auto f = File(fileName);
    immutable auto fileSize = f.size();
    ubyte[] fileBytes = new ubyte[](fileSize.to!size_t);

    if(f.rawRead(fileBytes).length != fileSize) {
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
  } catch(Throwable) {
    return [];
  }
}

/// split multiline tokens in multiple single line tokens with the same type
void splitMultilinetokens(const(Token)[] tokens, ref const(Token)[] result) nothrow @trusted {

  try {
    foreach(token; tokens) {
      auto pieces = token.text.idup.split("\n");

      if(pieces.length <= 1) {
        result ~= const Token(token.type, token.text.dup, token.line, token.column, token.index);
      } else {
        size_t line = token.line;
        size_t column = token.column;

        foreach(textPiece; pieces) {
          result ~= const Token(token.type, textPiece, line, column, token.index);
          line++;
          column = 1;
        }
      }
    }
  } catch(Throwable) {}
}
