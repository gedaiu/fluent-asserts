module bdd.string;

public import bdd.base;

import std.string;
import std.conv;
import std.algorithm;

struct ShouldString {
  private const string testData;

  mixin ShouldCommons;

  void equal(const string someString, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("equal");
    addMessage("`" ~ someString.to!string ~ "`");
    beginCheck;

    auto isSame = testData == someString;

    result(isSame, "`" ~ testData ~ "`" ~ (isSame ? " is equal" : " is not equal") ~ " to `" ~ someString ~"`.", file, line);
  }

  void contain(const string[] someStrings, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("contain");
    addMessage("`" ~ someStrings.to!string ~ "`");
    beginCheck;

    someStrings.each!(value => contain(value, file, line));
  }

  void contain(const string someString, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("contain");
    addMessage("`" ~ someString ~ "`");
    beginCheck;

    auto index = testData.indexOf(someString);
    auto isPresent = index >= 0;

    result(isPresent, "`" ~ someString ~ "`" ~
      (isPresent ? " was found on position `" ~ index.to!string ~ "`." : " was not found in `" ~ testData ~"`."), file, line);
  }

  void contain(const char someChar, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ someChar.to!string ~ "`";

    addMessage("contain");
    addMessage(strVal);
    beginCheck;

    auto index = testData.indexOf(someChar);
    auto isPresent = index >= 0;

    result(isPresent, strVal ~ (isPresent ? " is present" : " is not present") ~ " in `" ~ testData ~"`.", file, line);
  }
}

@("string contain")
unittest {
  should.not.throwAnyException({
    "test string".should.contain(["string", "test"]);
  });

  should.not.throwAnyException({
    "test string".should.contain("string");
  });

  should.not.throwAnyException({
    "test string".should.contain('s');
  });

  should.throwException!TestException({
    "test string".should.contain(["other", "message"]);
  }).msg.should.contain("`other` was not found in `test string`");

  should.throwException!TestException({
    "test string".should.contain("other");
  }).msg.should.contain("`other` was not found in `test string`");

  should.throwException!TestException({
    "test string".should.contain('o');
  }).msg.should.contain("`o` is not present in `test string`");
}

@("string equal")
unittest {
  should.not.throwAnyException({
    "test string".should.equal("test string");
  });

  should.not.throwAnyException({
    "test string".should.not.equal("test");
  });

  should.throwException!TestException({
    "test string".should.equal("test");
  }).msg.should.contain("`test string` is not equal to `test`");

  should.throwException!TestException({
    "test string".should.not.equal("test string");
  }).msg.should.contain("`test string` is equal to `test string`");
}
