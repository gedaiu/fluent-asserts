/// Token parsing and manipulation functions.
module fluentasserts.results.source.tokens;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.array;

import dparse.lexer;

@safe:

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

/// Extends a token index backwards to include all tokens from the start of the line.
/// Params:
///   tokens = The token array
///   index = The starting index
/// Returns: The index of the first token on the same line
size_t extendToLineStart(const(Token)[] tokens, size_t index) nothrow @nogc {
  if (index == 0 || index >= tokens.length) {
    return index;
  }

  auto targetLine = tokens[index].line;
  while (index > 0 && tokens[index - 1].line == targetLine) {
    index--;
  }
  return index;
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
  import std.exception : enforce;

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

version(unittest) {
  import fluent.asserts;
}

@("extendToLineStart returns same index for first token")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);
  extendToLineStart(tokens, 0).should.equal(0);
}

@("extendToLineStart extends to start of line")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);
  size_t testIndex = 10;
  auto result = extendToLineStart(tokens, testIndex);
  result.should.be.lessThan(testIndex + 1);
  if (result < testIndex) {
    tokens[result].line.should.equal(tokens[testIndex].line);
  }
}

@("getPreviousIdentifier returns the previous unittest identifier from a list of tokens")
unittest {
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto scopeResult = getScope(tokens, 81);
  auto result = getPreviousIdentifier(tokens, scopeResult.begin);

  tokens[result .. scopeResult.begin].tokensToString.strip.should.equal(`unittest`);
}

@("getPreviousIdentifier returns the previous paranthesis identifier from a list of tokens")
unittest {
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto scopeResult = getScope(tokens, 63);
  auto end = scopeResult.end - 11;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`(5, (11))`);
}

@("getPreviousIdentifier returns the previous function call identifier from a list of tokens")
unittest {
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto scopeResult = getScope(tokens, 75);
  auto end = scopeResult.end - 11;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`found(4)`);
}

@("getPreviousIdentifier returns the previous map identifier from a list of tokens")
unittest {
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto scopeResult = getScope(tokens, 85);
  auto end = scopeResult.end - 12;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`[1, 2, 3].map!"a"`);
}

@("getAssertIndex returns the index of the Assert structure identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto result = getAssertIndex(tokens, 55);

  tokens[result .. result + 4].tokensToString.strip.should.equal(`Assert.equal(`);
}

@("getParameter returns the first parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 57) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].tokensToString.strip.should.equal(`(5, (11))`);
}

@("getParameter returns the first list parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 89) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].tokensToString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

@("getPreviousIdentifier returns the previous array identifier from a list of tokens")
unittest {
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto scopeResult = getScope(tokens, 4);
  auto end = scopeResult.end - 13;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`[1, 2, 3]`);
}

@("getPreviousIdentifier returns the previous array of instances identifier from a list of tokens")
unittest {
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto scopeResult = getScope(tokens, 90);
  auto end = scopeResult.end - 16;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].tokensToString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

@("getShouldIndex returns the index of the should call")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto result = getShouldIndex(tokens, 4);

  auto token = tokens[result];
  token.line.should.equal(3);
  token.text.should.equal(`should`);
  str(token.type).text.should.equal(`identifier`);
}

@("getFunctionEnd returns the end of a spec function with a lambda")
unittest {
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

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
  import fluentasserts.results.source.scopes : getScope;
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto result = getScope(tokens, 81);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);
  auto functionEnd = getFunctionEnd(tokens, identifierStart) + 1;

  tokens[identifierStart .. functionEnd].tokensToString.strip.should.equal("unittest {
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

}");
}
