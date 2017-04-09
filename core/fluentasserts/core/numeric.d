module fluentasserts.core.numeric;

public import fluentasserts.core.base;

import std.string;
import std.conv;
import std.algorithm;

struct ShouldNumeric(T) {
  private const T testData;

  mixin ShouldCommons;

  alias above = this.greaterThan;
  alias below = this.lessThan;

  void equal(const T someValue, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("equal");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isSame = testData == someValue;

    result(isSame, "`" ~ testData.to!string ~ "`" ~ (isSame ? " is equal" : " is not equal") ~ " to `" ~ someValue.to!string ~"`.", file, line);
  }

  void greaterThan(const T someValue, const string file = __FILE__, const size_t line = __LINE__){
    addMessage("be greater than");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isGreater = testData > someValue;

    result(isGreater, "`" ~ testData.to!string ~ "`" ~ (isGreater ? " is greater" : " is not greater") ~ " than `" ~ someValue.to!string ~"`.", file, line);
  }

  void lessThan(const T someValue, const string file = __FILE__, const size_t line = __LINE__){
    addMessage("be less than");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isLess = testData < someValue;

    result(isLess, "`" ~ testData.to!string ~ "`" ~ (isLess ? " is less" : " is not less") ~ " than `" ~ someValue.to!string ~"`.", file, line);
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

    5.should.be.above(4);
    5.should.not.be.above(6);
  });

  should.throwException!TestException({
    5.should.be.greaterThan(5);
    5.should.be.above(5);
  }).msg.should.startWith("5 should be greater than `5`. `5` is not greater than `5`.");

  should.throwException!TestException({
    5.should.not.be.greaterThan(4);
    5.should.not.be.above(4);
  }).msg.should.startWith("5 should not be greater than `4`. `5` is greater than `4`.");
}

@("numbers less than")
unittest {
  should.not.throwAnyException({
    5.should.be.lessThan(6);
    5.should.not.be.lessThan(4);

    5.should.be.below(6);
    5.should.not.be.below(4);
  });

  should.throwException!TestException({
    5.should.be.lessThan(4);
    5.should.be.below(4);
  }).msg.should.startWith("5 should be less than `4`. `5` is not less than `4`.");

  should.throwException!TestException({
    5.should.not.be.lessThan(6);
    5.should.not.be.below(6);
  }).msg.should.startWith("5 should not be less than `6`. `5` is less than `6`.");
}