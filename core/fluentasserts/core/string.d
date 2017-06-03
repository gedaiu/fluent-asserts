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

  void equal(const string someString, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("equal");
    addMessage("`" ~ someString.to!string ~ "`");
    beginCheck;

    auto isSame = testData == someString;

    result(isSame, new DiffResult(someString, testData), file, line);
  }

  void contain(const string[] someStrings, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("contain");
    addMessage("`" ~ someStrings.to!string ~ "`");
    beginCheck;

    if(expectedValue) {
      auto missingValues = someStrings.filter!(a => testData.indexOf(a) == -1).array;
      auto msg = missingValues.to!string ~ " are missing from `" ~ testData ~ "`.";

      result(missingValues.length == 0, msg, new ExpectedActualResult("to contain all " ~ someStrings.to!string, testData), file, line);
    } else {
      auto presentValues = someStrings.filter!(a => testData.indexOf(a) != -1).array;
      auto msg = presentValues.to!string ~ " are present in `" ~ testData ~ "`.";

      result(presentValues.length != 0, msg, new ExpectedActualResult("to not contain any " ~ someStrings.to!string, testData), file, line);
    }
  }

  void contain(const string someString, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("contain");
    addMessage("`" ~ someString ~ "`");
    beginCheck;

    auto index = testData.indexOf(someString);
    auto isPresent = index >= 0;

    auto msg = expectedValue ? "`" ~ someString ~ "` is missing from `" ~ testData ~ "`." : "`" ~ someString ~ "` is present in `" ~ testData ~ "`.";
    auto mode = expectedValue ? "to contain" : "to not contain";

    result(isPresent, msg, new ExpectedActualResult(mode ~ " `" ~ someString ~ "`", testData), file, line);
  }

  void contain(const char someChar, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ someChar.to!string ~ "`";

    addMessage("contain");
    addMessage(strVal);
    beginCheck;

    auto index = testData.indexOf(someChar);
    auto isPresent = index >= 0;
    auto msg = strVal ~ (isPresent ? " is present" : " is not present") ~ " in `" ~ testData ~"`.";
    auto mode = expectedValue ? "to contain" : "to not contain";

    result(isPresent, msg, new ExpectedActualResult(mode ~ " `" ~ someChar ~ "`", testData), file, line);
  }

  void startWith(T)(const T someString, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ someString.to!string ~ "`";

    addMessage("start with");
    addMessage(strVal);
    beginCheck;

    auto index = testData.indexOf(someString);
    auto doesStartWith = index == 0;
    auto msg = "`" ~ testData ~ "`" ~ (doesStartWith ? " does start with " : " does not start with ") ~ strVal;
    auto mode = expectedValue ? "to start with " : "to not start with ";

    result(doesStartWith, msg, new ExpectedActualResult(mode ~ strVal, testData), file, line);
  }

  void endWith(T)(const T someString, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ someString.to!string ~ "`";

    addMessage("end with");
    addMessage(strVal);
    beginCheck;

    auto index = testData.lastIndexOf(someString);

    static if(is(T == string)) {
      auto doesEndWith = index == testData.length - someString.length;
    } else {
      auto doesEndWith = index == testData.length - 1;
    }
    auto msg = "`" ~ testData ~ "`" ~ (doesEndWith ? " does end with " : " does not end with ") ~ strVal;
    auto mode = expectedValue ? "to end with " : "to not end with ";

    result(doesEndWith, msg, new ExpectedActualResult(mode ~ strVal, testData), file, line);
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
  msg.split("\n")[2].should.contain("Expected:to start with `other`");
  msg.split("\n")[3].should.contain("Actual:test string");

  ({
    "test string".should.not.startWith("other");
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.startWith("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does start with `test`");
  msg.split("\n")[2].should.equal("Expected:to not start with `test`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.startWith('t');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.startWith('o');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does not start with `o`");
  msg.split("\n")[2].should.equal("Expected:to start with `o`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.not.startWith('o');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.startWith('t');
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.contain("`test string` does start with `t`");
  msg.split("\n")[2].should.equal("Expected:to not start with `t`");
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
  msg.split("\n")[2].should.equal("Expected:to end with `other`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.not.endWith("other");
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.endWith("string");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should not end with `string`. `test string` does end with `string`");
  msg.split("\n")[2].should.equal("Expected:to not end with `string`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.endWith('g');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.endWith('t');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does not end with `t`");
  msg.split("\n")[2].should.equal("Expected:to end with `t`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  ({
    "test string".should.not.endWith('w');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.endWith('g');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain("`test string` does end with `g`");
  msg.split("\n")[2].should.equal("Expected:to not end with `g`");
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
  msg.split("\n")[2].should.equal("Expected:to contain all [\"other\", \"message\"]");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain(["test", "string"]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should not contain `[\"test\", \"string\"]`. [\"test\", \"string\"] are present in `test string`.");
  msg.split("\n")[2].should.equal("Expected:to not contain any [\"test\", \"string\"]");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.contain("other");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should contain `other`. `other` is missing from `test string`.");
  msg.split("\n")[2].should.equal("Expected:to contain `other`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("\"test string\" should not contain `test`. `test` is present in `test string`.");
  msg.split("\n")[2].should.equal("Expected:to not contain `test`");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.contain('o');
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.contain("`o` is not present in `test string`");
  msg.split("\n")[2].should.contain("Expected:to contain `o`");
  msg.split("\n")[3].should.contain("Actual:test string");

  msg = ({
    "test string".should.not.contain('t');
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.equal("\"test string\" should not contain `t`. `t` is present in `test string`.");
  msg.split("\n")[2].should.contain("Expected:to not contain `t`");
  msg.split("\n")[3].should.contain("Actual:test string");
}

@("string equal")
unittest {
  ({
    "test string".should.equal("test string");
  }).should.not.throwAnyException;

  ({
    "test string".should.not.equal("test");
  }).should.not.throwAnyException;

  ({
    "test string".should.equal("test");
  }).should.throwException!TestException.msg.should.contain("`test string` is not equal to `test`");

  ({
    "test string".should.not.equal("test string");
  }).should.throwException!TestException.msg.should.contain("`test string` is equal to `test string`");
}
