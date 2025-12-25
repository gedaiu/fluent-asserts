/// Scope analysis for finding code boundaries in token streams.
module fluentasserts.results.source.scopes;

import std.typecons;
import std.string;
import dparse.lexer;

@safe:

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

version(unittest) {
  import fluent.asserts;
  import fluentasserts.results.source.tokens;
}

@("getScope returns the spec function and scope that contains a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

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
  splitMultilinetokens(fileToDTokens("testdata/class.d"), tokens);

  auto result = getScope(tokens, 10);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].tokensToString.strip.should.equal("void bar() {
        assert(false);
    }");
}

@("getScope returns a method scope without assert")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/class.d"), tokens);

  auto result = getScope(tokens, 14);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].tokensToString.strip.should.equal("void bar2() {
        enforce(false);
    }");
}

@("getScope returns tokens from a scope that contains a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("testdata/values.d"), tokens);

  auto result = getScope(tokens, 81);

  tokens[result.begin .. result.end].tokensToString.strip.should.equal(`{
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

}`);
}
