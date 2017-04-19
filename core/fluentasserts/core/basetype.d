module fluentasserts.core.basetype;

public import fluentasserts.core.base;

import std.string;
import std.conv;
import std.algorithm;

struct ShouldBaseType(T) {
  private const T testData;

  mixin ShouldCommons;

  alias above = this.greaterThan;
  alias below = this.lessThan;
  alias within = this.between;

  void equal(const T someValue, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("equal");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isSame = testData == someValue;

    result(isSame, testData.to!string, someValue.to!string, file, line);
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

  void between(const T limit1, const T limit2, const string file = __FILE__, const size_t line = __LINE__) {
    T min = limit1 < limit2 ? limit1 : limit2;
    T max = limit1 > limit2 ? limit1 : limit2;

    addMessage("be between `" ~ min.to!string ~ "` and `" ~ max.to!string ~ "`");

    auto isBetween = min < testData && max > testData;

    result(isBetween, "", file, line);
  }

  void approximately()(const T someValue, const T delta, const string file = __FILE__, const size_t line = __LINE__)
  if(!is(T == bool))
  {
    between(someValue - delta, someValue + delta, file, line);
  }
}

@("numbers equal")
unittest {
  ({
    5.should.equal(5);
    5.should.not.equal(6);
  }).should.not.throwAnyException;

  ({
    5.should.equal(6);
  }).should.throwException!TestException.msg.should.startWith("5 should equal `6`");

  ({
    5.should.not.equal(5);
  }).should.throwException!TestException.msg.should.startWith("5 should not equal `5`");
}

@("bools equal")
unittest {
  ({
    true.should.equal(true);
    true.should.not.equal(false);
  }).should.not.throwAnyException;

  ({
    true.should.equal(false);
  }).should.throwException!TestException.msg.should.startWith("true should equal `false`");

  ({
    true.should.not.equal(true);
  }).should.throwException!TestException.msg.should.startWith("true should not equal `true`");
}

@("numbers greater than")
unittest {
  ({
    5.should.be.greaterThan(4);
    5.should.not.be.greaterThan(6);

    5.should.be.above(4);
    5.should.not.be.above(6);
  }).should.not.throwAnyException;

  ({
    5.should.be.greaterThan(5);
    5.should.be.above(5);
  }).should.throwException!TestException.msg.should.startWith("5 should be greater than `5`. `5` is not greater than `5`.");

  ({
    5.should.not.be.greaterThan(4);
    5.should.not.be.above(4);
  }).should.throwException!TestException.msg.should.startWith("5 should not be greater than `4`. `5` is greater than `4`.");
}

@("numbers less than")
unittest {
  ({
    5.should.be.lessThan(6);
    5.should.not.be.lessThan(4);

    5.should.be.below(6);
    5.should.not.be.below(4);
  }).should.not.throwAnyException;

  ({
    5.should.be.lessThan(4);
    5.should.be.below(4);
  }).should.throwException!TestException.msg.should.startWith("5 should be less than `4`. `5` is not less than `4`.");

  ({
    5.should.not.be.lessThan(6);
    5.should.not.be.below(6);
  }).should.throwException!TestException.msg.should.startWith("5 should not be less than `6`. `5` is less than `6`.");
}

@("numbers between")
unittest {
  ({
    5.should.be.between(4, 6);
    5.should.be.between(6, 4);
    5.should.not.be.between(5, 6);
    5.should.not.be.between(4, 5);
  }).should.not.throwAnyException;

  ({
    5.should.be.between(5, 6);
  }).should.throwException!TestException.msg.should.startWith("5 should be between `5` and `6`");

  ({
    5.should.be.between(4, 5);
  }).should.throwException!TestException.msg.should.startWith("5 should be between `4` and `5`");

  ({
    5.should.not.be.between(4, 6);
  }).should.throwException!TestException.msg.should.startWith("5 should not be between `4` and `6`");

  ({
    5.should.not.be.between(6, 4);
  }).should.throwException!TestException.msg.should.startWith("5 should not be between `4` and `6`");
}

@("numbers within")
unittest {
  ({
    5.should.be.within(4, 6);
    5.should.be.within(6, 4);
    5.should.not.be.within(5, 6);
    5.should.not.be.within(4, 5);
  }).should.not.throwAnyException;

  ({
    5.should.be.within(5, 6);
  }).should.throwException!TestException.msg.should.startWith("5 should be between `5` and `6`");

  ({
    5.should.be.within(4, 5);
  }).should.throwException!TestException.msg.should.startWith("5 should be between `4` and `5`");

  ({
    5.should.not.be.within(4, 6);
  }).should.throwException!TestException.msg.should.startWith("5 should not be between `4` and `6`");

  ({
    5.should.not.be.within(6, 4);
  }).should.throwException!TestException.msg.should.startWith("5 should not be between `4` and `6`");
}

@("numbers approximately")
unittest {
  ({
    (10f/3f).should.be.approximately(3, 0.34);
    (10f/3f).should.not.be.approximately(3, 0.24);
  }).should.not.throwAnyException;

  ({
    (10f/3f).should.be.approximately(3, 0.3);
  }).should.throwException!TestException.msg.should.startWith("(10f/3f) should be between `2.7` and `3.3`.");

  ({
    (10f/3f).should.not.be.approximately(3, 0.34);
  }).should.throwException!TestException.msg.should.startWith("(10f/3f) should not be between `2.66` and `3.34");
}
