module fluentasserts.core.string;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.conv;
import std.algorithm;
import std.array;

struct ShouldString {
  private const string testData;

  mixin ShouldCommons;

  auto equal(const string someString, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" equal `");
    addValue(someString.to!string);
    addMessage("`");
    beginCheck;

    auto isSame = testData == someString;

    auto msg = "`" ~ testData ~ "` is" ~ (expectedValue ? " not" : "") ~ " equal to `" ~ someString ~ "`.";

    return result(isSame, msg, cast(IResult[])[ new DiffResult(someString, testData) , new ExpectedActualResult(someString, testData) ], file, line);
  }

  auto contain(const string[] someStrings, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" contain `");
    addValue(someStrings.to!string);
    addMessage("`");
    beginCheck;

    if(expectedValue) {
      auto missingValues = someStrings.filter!(a => testData.indexOf(a) == -1).array;
      auto msg = missingValues.to!string ~ " are missing from `" ~ testData ~ "`.";

      return result(missingValues.length == 0, msg, new ExpectedActualResult("to contain all " ~ someStrings.to!string, testData), file, line);
    } else {
      auto presentValues = someStrings.filter!(a => testData.indexOf(a) != -1).array;
      auto msg = presentValues.to!string ~ " are present in `" ~ testData ~ "`.";

      return result(presentValues.length != 0, msg, new ExpectedActualResult("to not contain any " ~ someStrings.to!string, testData), file, line);
    }
  }

  auto contain(const string someString, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" contain `");
    addValue(someString);
    addMessage("`");
    beginCheck;

    auto index = testData.indexOf(someString);
    auto isPresent = index >= 0;

    auto msg = expectedValue ? "`" ~ someString ~ "` is missing from `" ~ testData ~ "`." : "`" ~ someString ~ "` is present in `" ~ testData ~ "`.";
    auto mode = expectedValue ? "to contain" : "to not contain";

    return result(isPresent, msg, new ExpectedActualResult(mode ~ " `" ~ someString ~ "`", testData), file, line);
  }

  auto contain(const char someChar, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ someChar.to!string ~ "`";

    addMessage(" contain `");
    addValue(someChar.to!string);
    addMessage("`");
    beginCheck;

    auto index = testData.indexOf(someChar);
    auto isPresent = index >= 0;
    auto msg = strVal ~ (isPresent ? " is present" : " is not present") ~ " in `" ~ testData ~"`.";
    auto mode = expectedValue ? "to contain" : "to not contain";

    return result(isPresent, msg, new ExpectedActualResult(mode ~ " `" ~ someChar ~ "`", testData), file, line);
  }

  auto startWith(T)(const T someString, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ someString.to!string ~ "`";

    addMessage(" start with `");
    addValue(strVal);
    addMessage("`");
    beginCheck;

    auto index = testData.indexOf(someString);
    auto doesStartWith = index == 0;
    auto msg = "`" ~ testData ~ "`" ~ (doesStartWith ? " does start with " : " does not start with ") ~ strVal;
    auto mode = expectedValue ? "to start with " : "to not start with ";

    return result(doesStartWith, msg, new ExpectedActualResult(mode ~ strVal, testData), file, line);
  }

  auto endWith(T)(const T someString, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ someString.to!string ~ "`";

    addMessage(" end with `");
    addValue(someString.to!string);
    addMessage("`");
    beginCheck;

    auto index = testData.lastIndexOf(someString);

    static if(is(T == string)) {
      auto doesEndWith = index == testData.length - someString.length;
    } else {
      auto doesEndWith = index == testData.length - 1;
    }
    auto msg = "`" ~ testData ~ "`" ~ (doesEndWith ? " does end with " : " does not end with ") ~ strVal;
    auto mode = expectedValue ? "to end with " : "to not end with ";

    return result(doesEndWith, msg, new ExpectedActualResult(mode ~ strVal, testData), file, line);
  }
}

@("string startWith")
unittest {
  ({
    "test string".should.startWith("test");
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.startWith("other");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does not start with `other`");
  msg.split("\n")[2].strip.should.equal("Expected:to start with `other`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.not.startWith("other");
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.startWith("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does start with `test`");
  msg.split("\n")[2].strip.should.equal("Expected:to not start with `test`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.startWith('t');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.startWith('o');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does not start with `o`");
  msg.split("\n")[2].strip.should.equal("Expected:to start with `o`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.not.startWith('o');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.startWith('t');
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.contain("`test string` does start with `t`");
  msg.split("\n")[2].strip.should.equal("Expected:to not start with `t`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");
}

@("string endWith")
unittest {
  ({
    "test string".should.endWith("string");
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.endWith("other");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does not end with `other`");
  msg.split("\n")[2].strip.should.equal("Expected:to end with `other`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.not.endWith("other");
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.endWith("string");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should not end with `string`. `test string` does end with `string`");
  msg.split("\n")[2].strip.should.equal("Expected:to not end with `string`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.endWith('g');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.endWith('t');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does not end with `t`");
  msg.split("\n")[2].strip.should.equal("Expected:to end with `t`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.not.endWith('w');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.endWith('g');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does end with `g`");
  msg.split("\n")[2].strip.should.equal("Expected:to not end with `g`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");
}

@("string contain")
unittest {
  ({
    "test string".should.contain(["string", "test"]);
    "test string".should.not.contain(["other", "message"]);
  }).should.not.throwAnyException;

  ({
    "test string".should.contain("string");
    "test string".should.not.contain("other");
  }).should.not.throwAnyException;

  ({
    "test string".should.contain('s');
    "test string".should.not.contain('z');
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.contain(["other", "message"]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should contain `[\"other\", \"message\"]`. [\"other\", \"message\"] are missing from `test string`.");
  msg.split("\n")[2].strip.should.equal("Expected:to contain all [\"other\", \"message\"]");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain(["test", "string"]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should not contain `[\"test\", \"string\"]`. [\"test\", \"string\"] are present in `test string`.");
  msg.split("\n")[2].strip.should.equal("Expected:to not contain any [\"test\", \"string\"]");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.contain("other");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should contain `other`. `other` is missing from `test string`.");
  msg.split("\n")[2].strip.should.equal("Expected:to contain `other`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should not contain `test`. `test` is present in `test string`.");
  msg.split("\n")[2].strip.should.equal("Expected:to not contain `test`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.contain('o');
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.contain("`o` is not present in `test string`");
  msg.split("\n")[2].strip.should.equal("Expected:to contain `o`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain('t');
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.equal("\"test string\" should not contain `t`. `t` is present in `test string`.");
  msg.split("\n")[2].strip.should.equal("Expected:to not contain `t`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");
}

@("string equal")
unittest {
  ({
    "test string".should.equal("test string");
  }).should.not.throwAnyException;

  ({
    "test string".should.not.equal("test");
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.equal("test");
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.equal("\"test string\" should equal `test`. `test string` is not equal to `test`.");

  msg = ({
    "test string".should.not.equal("test string");
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.equal("\"test string\" should not equal `test string`. `test string` is equal to `test string`.");
}
