module fluentasserts.core.basetype;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.conv;
import std.algorithm;

@trusted:

struct ShouldBaseType(T) {
  private const T testData;

  this(U)(U value) {
    valueEvaluation = value.evaluation;
    testData = value.value;
  }

  mixin ShouldCommons;
  mixin ShouldThrowableCommons;

  alias above = typeof(this).greaterThan;
  alias below = typeof(this).lessThan;
  alias within = typeof(this).between;

  auto equal(const T someValue, const string file = __FILE__, const size_t line = __LINE__) {
    validateException;

    addMessage(" equal `");
    addValue(someValue.to!string);
    addMessage("`");
    beginCheck;

    auto isSame = testData == someValue;

    static if(is( T == bool )) {
      auto expected = expectedValue ? someValue.to!string : (!someValue).to!string;
    } else {
      auto expected = expectedValue ? someValue.to!string : ("not " ~ someValue.to!string);
    }

    return result(isSame, new ExpectedActualResult(expected, testData.to!string), file, line);
  }

  auto greaterThan()(const T someValue, const string file = __FILE__, const size_t line = __LINE__)
  if(!is(T == bool))
  {
    validateException;

    addMessage(" greater than `");
    addValue(someValue.to!string);
    addMessage("`");
    beginCheck;

    auto isGreater = testData > someValue;
    auto mode = isGreater ? "greater than" : "less than or equal to";
    auto expectedMode = isGreater ? "less than or equal to" : "greater than";

    Message[] msg = [
      Message(false, "`"),
      Message(true, testData.to!string),
      Message(false, "` is " ~ mode ~ " `"),
      Message(true, someValue.to!string),
      Message(false, "`.")
    ];

    return result(isGreater, msg, new ExpectedActualResult(expectedMode  ~ " `" ~ someValue.to!string ~ "`", testData.to!string), file, line);
  }

  auto lessThan()(const T someValue, const string file = __FILE__, const size_t line = __LINE__)
  if(!is(T == bool))
  {
    validateException;

    addMessage(" less than `");
    addValue(someValue.to!string);
    addMessage("`");
    beginCheck;

    auto isLess = testData < someValue;

    Message[] msg = [
      Message(false, "`"),
      Message(true, testData.to!string),
      Message(false, isLess ? "` is less than `" : "` is greater or equal to `"),
      Message(true, someValue.to!string),
      Message(false, "`.")
    ];

    auto expectedMode = isLess ? "greater or equal to" : "less than";

    return result(isLess, msg, new ExpectedActualResult(expectedMode ~ " `" ~ someValue.to!string ~ "`", testData.to!string), file, line);
  }

  auto between()(const T limit1, const T limit2, const string file = __FILE__, const size_t line = __LINE__)
  if(!is(T == bool))
  {
    validateException;

    T min = limit1 < limit2 ? limit1 : limit2;
    T max = limit1 > limit2 ? limit1 : limit2;

    addMessage(" between `");
    addValue(min.to!string);
    addMessage("` and `");
    addValue(max.to!string);
    addMessage("`");
    beginCheck;

    auto isLess = testData <= min;
    auto isGreater = testData >= max;
    auto isBetween = !isLess && !isGreater;

    Message[] msg;

    auto interval = "a value " ~ (expectedValue ? "inside" : "outside") ~ " (" ~ min.to!string ~ ", " ~ max.to!string ~ ") interval";

    if(expectedValue) {
      msg ~= [ Message(false, "`"), Message(true, testData.to!string), Message(false, "`") ];

      if(isLess) {
        msg ~= [ Message(false, " is less than or equal to `"), Message(true, min.to!string), Message(false, "`.") ];
      }

      if(isGreater) {
        msg ~= [ Message(false, " is greater than or equal to `"), Message(true, max.to!string), Message(false, "`.") ];
      }
    }

    return result(isBetween, msg, new ExpectedActualResult(interval, testData.to!string), file, line);
  }

  auto approximately()(const T someValue, const T delta, const string file = __FILE__, const size_t line = __LINE__)
  if(!is(T == bool))
  {
    validateException;

    addMessage(" equal `");
    addValue(someValue.to!string ~ "±" ~ delta.to!string);
    addMessage("`");
    beginCheck;

    return between(someValue - delta, someValue + delta, file, line);
  }
}

/// When there is a lazy number that throws an it should throw that exception
unittest {
  int someLazyInt() {
    throw new Exception("This is it.");
  }

  ({
    someLazyInt.should.equal(3);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.greaterThan(3);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.lessThan(3);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.between(3, 4);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.approximately(3, 4);
  }).should.throwAnyException.withMessage("This is it.");
}

@("numbers equal")
unittest {
  ({
    5.should.equal(5);
    5.should.not.equal(6);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.equal(6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should equal `6`.");
  msg.split("\n")[2].strip.should.equal("Expected:6");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.equal(5);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should not equal `5`.");
  msg.split("\n")[2].strip.should.equal("Expected:not 5");
  msg.split("\n")[3].strip.should.equal("Actual:5");
}

@("bools equal")
unittest {
  ({
    true.should.equal(true);
    true.should.not.equal(false);
  }).should.not.throwAnyException;

  auto msg = ({
    true.should.equal(false);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("true should equal `false`.");
  msg.split("\n")[2].strip.should.equal("Expected:false");
  msg.split("\n")[3].strip.should.equal("Actual:true");

  msg = ({
    true.should.not.equal(true);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("true should not equal `true`.");
  msg.split("\n")[2].strip.should.equal("Expected:false");
  msg.split("\n")[3].strip.should.equal("Actual:true");
}

@("numbers greater than")
unittest {
  ({
    5.should.be.greaterThan(4);
    5.should.not.be.greaterThan(6);

    5.should.be.above(4);
    5.should.not.be.above(6);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.be.greaterThan(5);
    5.should.be.above(5);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be greater than `5`. `5` is less than or equal to `5`.");
  msg.split("\n")[2].strip.should.equal("Expected:greater than `5`");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.greaterThan(4);
    5.should.not.be.above(4);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should not be greater than `4`. `5` is greater than `4`.");
  msg.split("\n")[2].strip.should.equal("Expected:less than or equal to `4`");
  msg.split("\n")[3].strip.should.equal("Actual:5");
}

@("numbers less than")
unittest {
  ({
    5.should.be.lessThan(6);
    5.should.not.be.lessThan(4);

    5.should.be.below(6);
    5.should.not.be.below(4);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.be.lessThan(4);
    5.should.be.below(4);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be less than `4`. `5` is greater or equal to `4`.");
  msg.split("\n")[2].strip.should.equal("Expected:less than `4`");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.lessThan(6);
    5.should.not.be.below(6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should not be less than `6`. `5` is less than `6`.");
}

@("numbers between")
unittest {
  ({
    5.should.be.between(4, 6);
    5.should.be.between(6, 4);
    5.should.not.be.between(5, 6);
    5.should.not.be.between(4, 5);

    5.should.be.within(4, 6);
    5.should.be.within(6, 4);
    5.should.not.be.within(5, 6);
    5.should.not.be.within(4, 5);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.be.between(5, 6);
    5.should.be.within(5, 6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be between `5` and `6`. `5` is less than or equal to `5`.");
  msg.split("\n")[2].strip.should.equal("Expected:a value inside (5, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.be.between(4, 5);
    5.should.be.within(4, 5);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be between `4` and `5`. `5` is greater than or equal to `5`.");
  msg.split("\n")[2].strip.should.equal("Expected:a value inside (4, 5) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.between(4, 6);
    5.should.not.be.within(4, 6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("5 should not be between `4` and `6`.");
  msg.split("\n")[2].strip.should.equal("Expected:a value outside (4, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.between(6, 4);
    5.should.not.be.within(6, 4);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("5 should not be between `4` and `6`.");
  msg.split("\n")[2].strip.should.equal("Expected:a value outside (4, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");
}

/// numbers approximately
unittest {
  ({
    (10f/3f).should.be.approximately(3, 0.34);
    (10f/3f).should.not.be.approximately(3, 0.24);
  }).should.not.throwAnyException;

  auto msg = ({
    (10f/3f).should.be.approximately(3, 0.3);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("(10f/3f) should be equal `3±0.3`. `3.33333` is greater than or equal to `3.3`.");
  msg.split("\n")[2].strip.should.equal("Expected:a value inside (2.7, 3.3) interval");
  msg.split("\n")[3].strip.should.equal("Actual:3.33333");

  msg = ({
    (10f/3f).should.not.be.approximately(3, 0.34);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("(10f/3f) should not be equal `3±0.34`.");
  msg.split("\n")[2].strip.should.equal("Expected:a value outside (2.66, 3.34) interval");
  msg.split("\n")[3].strip.should.equal("Actual:3.33333");
}

/// should throw exceptions for delegates that return basic types
unittest {
  int value() {
    throw new Exception("not implemented");
  }

  void voidValue() {
    throw new Exception("not implemented");
  }

  void noException() { }

  value().should.throwAnyException.withMessage.equal("not implemented");
  voidValue().should.throwAnyException.withMessage.equal("not implemented");

  bool thrown;

  try {
    noException.should.throwAnyException;
  } catch (TestException e) {
    e.msg.should.startWith("noException should throw any exception. Nothing was thrown.");
    thrown = true;
  }
  thrown.should.equal(true);

  thrown = false;

  try {
    voidValue().should.not.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[0].should.equal("voidValue() should not throw any exception. An exception of type `object.Exception` saying `not implemented` was thrown.");
  }

  thrown.should.equal(true);
}

/// it should compile const comparison
unittest
{
  const actual = 42;
  actual.should.equal(42);
}
