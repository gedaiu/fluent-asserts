module fluentasserts.core.basetype;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.conv;
import std.algorithm;

struct ShouldBaseType(T) {
  private const T testData;

  mixin ShouldCommons;

  alias above = this.greaterThan;
  alias below = this.lessThan;
  alias within = this.between;

  auto equal(const T someValue, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("equal");
    addMessage("`" ~ someValue.to!string ~ "`");
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
    addMessage("be greater than");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isGreater = testData > someValue;
    auto mode = isGreater ? "greater than" : "less than or equal to";
    auto expectedMode = isGreater ? "less than or equal to" : "greater than";

    auto msg = "`" ~ testData.to!string ~ "` is " ~ mode ~ " `" ~ someValue.to!string ~"`.";

    return result(isGreater, msg, new ExpectedActualResult(expectedMode  ~ " `" ~ someValue.to!string ~ "`", testData.to!string), file, line);
  }

  auto lessThan()(const T someValue, const string file = __FILE__, const size_t line = __LINE__)
  if(!is(T == bool))
  {
    addMessage("be less than");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isLess = testData < someValue;

    auto msg = "`" ~ testData.to!string ~ "`" ~ (isLess ? " is less than" : " is greater or equal to") ~ " `" ~ someValue.to!string ~ "`.";
    auto expectedMode = isLess ? "greater or equal to" : "less than";

    return result(isLess, msg, new ExpectedActualResult(expectedMode ~ " `" ~ someValue.to!string ~ "`", testData.to!string), file, line);
  }

  auto between()(const T limit1, const T limit2, const string file = __FILE__, const size_t line = __LINE__) 
  if(!is(T == bool))
  {
    T min = limit1 < limit2 ? limit1 : limit2;
    T max = limit1 > limit2 ? limit1 : limit2;

    addMessage("be between `" ~ min.to!string ~ "` and `" ~ max.to!string ~ "`");
    beginCheck;

    auto isLess = testData <= min;
    auto isGreater = testData >= max;
    auto isBetween = !isLess && !isGreater;

    string msg;
    auto interval = "a number " ~ (expectedValue ? "inside" : "outside") ~ " (" ~ min.to!string ~ ", " ~ max.to!string ~ ") interval";

    if(expectedValue) {
      msg = "`" ~ testData.to!string ~ "`";

      if(isLess) {
        msg ~= " is less than or equal to `" ~ min.to!string ~ "`.";
      }

      if(isGreater) {
        msg ~= " is greater than or equal to `" ~ max.to!string ~ "`.";
      }
    }

    return result(isBetween, msg, new ExpectedActualResult(interval, testData.to!string), file, line);
  }

  auto approximately()(const T someValue, const T delta, const string file = __FILE__, const size_t line = __LINE__)
  if(!is(T == bool))
  {
    addMessage("equal `" ~ someValue.to!string ~ "±" ~ delta.to!string ~ "`");
    beginCheck;

    return between(someValue - delta, someValue + delta, file, line);
  }
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
  msg.split("\n")[2].strip.should.equal("Expected:a number inside (5, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.be.between(4, 5);
    5.should.be.within(4, 5);
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].should.equal("5 should be between `4` and `5`. `5` is greater than or equal to `5`.");
  msg.split("\n")[2].strip.should.equal("Expected:a number inside (4, 5) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.between(4, 6);
    5.should.not.be.within(4, 6);
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].strip.should.equal("5 should not be between `4` and `6`.");
  msg.split("\n")[2].strip.should.equal("Expected:a number outside (4, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.between(6, 4);
    5.should.not.be.within(6, 4);
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].strip.should.equal("5 should not be between `4` and `6`.");
  msg.split("\n")[2].strip.should.equal("Expected:a number outside (4, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");
}

@("numbers approximately")
unittest {
  ({
    (10f/3f).should.be.approximately(3, 0.34);
    (10f/3f).should.not.be.approximately(3, 0.24);
  }).should.not.throwAnyException;

  auto msg = ({
    (10f/3f).should.be.approximately(3, 0.3);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("(10f/3f) should equal `3±0.3`. `3.33333` is greater than or equal to `3.3`.");
  msg.split("\n")[2].strip.should.equal("Expected:a number inside (2.7, 3.3) interval");
  msg.split("\n")[3].strip.should.equal("Actual:3.33333");

  msg = ({
    (10f/3f).should.not.be.approximately(3, 0.34);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("(10f/3f) should not equal `3±0.34`.");
  msg.split("\n")[2].strip.should.equal("Expected:a number outside (2.66, 3.34) interval");
  msg.split("\n")[3].strip.should.equal("Actual:3.33333");
}
