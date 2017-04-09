module fluentasserts.core.numeric;

public import fluentasserts.core.base;

import std.string;
import std.conv;
import std.algorithm;

struct ShouldNumeric(T) {
  private const T testData;

  mixin ShouldCommons;

  void equal(const T someValue, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("equal");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isSame = testData == someValue;

    result(isSame, "`" ~ testData.to!string ~ "`" ~ (isSame ? " is equal" : " is not equal") ~ " to `" ~ someValue.to!string ~"`.", file, line);
  }

  void greaterThan(const T someValue, const string file = __FILE__, const size_t line = __LINE__){
    addMessage("be greater then");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isGreater = testData > someValue;

    result(isGreater, "`" ~ testData.to!string ~ "`" ~ (isGreater ? " is greater" : " is not greater") ~ " than `" ~ someValue.to!string ~"`.", file, line);
  }
}

@("numbers equal")
unittest {
  should.not.throwAnyException({
    5.should.equal(5);
    5.should.not.equal(6);
  });

  should.throwException!TestException({
    5.should.equal(6);
  }).msg.should.startWith("5 should equal `6`. `5` is not equal to `6`.");

  should.throwException!TestException({
    5.should.not.equal(5);
  }).msg.should.startWith("5 should not equal `5`. `5` is equal to `5`.");
}

@("bools equal")
unittest {
  should.not.throwAnyException({
    true.should.equal(true);
    true.should.not.equal(false);
  });

  should.throwException!TestException({
    true.should.equal(false);
  }).msg.should.startWith("true should equal `false`. `true` is not equal to `false`.");

  should.throwException!TestException({
    true.should.not.equal(true);
  }).msg.should.startWith("true should not equal `true`. `true` is equal to `true`.");
}

@("numbers greater than")
unittest {
  should.not.throwAnyException({
    5.should.be.greaterThan(4);
    5.should.not.be.greaterThan(6);
  });

  should.throwException!TestException({
    5.should.be.greaterThan(5);
  }).msg.should.startWith("5 should be greater then `5`. `5` is not greater than `5`.");

  should.throwException!TestException({
    5.should.not.be.greaterThan(4);
  }).msg.should.startWith("5 should not be greater then `4`. `5` is greater than `4`.");
}