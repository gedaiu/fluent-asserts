module fluentasserts.operations.comparison.between;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import std.meta;
  import std.string;
}

static immutable betweenDescription = "Asserts that the target is a number or a date greater than or equal to the given number or date start, " ~
  "and less than or equal to the given number or date finish respectively. However, it's often best to assert that the target is equal to its expected value.";

///
void between(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");
  evaluation.result.addValue(evaluation.expectedValue.meta["1"]);
  evaluation.result.addText(". ");

  T currentValue;
  T limit1;
  T limit2;

  try {
    currentValue = evaluation.currentValue.strValue.to!T;
    limit1 = evaluation.expectedValue.strValue.to!T;
    limit2 = evaluation.expectedValue.meta["1"].to!T;
  } catch(Exception e) {
    evaluation.result.expected = "valid " ~ T.stringof ~ " values";
    evaluation.result.actual = "conversion error";
    return;
  }

  betweenResults(currentValue, limit1, limit2, evaluation);
}


///
void betweenDuration(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");

  Duration currentValue;
  Duration limit1;
  Duration limit2;

  try {
    currentValue = dur!"nsecs"(evaluation.currentValue.strValue.to!size_t);
    limit1 = dur!"nsecs"(evaluation.expectedValue.strValue.to!size_t);
    limit2 = dur!"nsecs"(evaluation.expectedValue.meta["1"].to!size_t);

    evaluation.result.addValue(limit2.to!string);
  } catch(Exception e) {
    evaluation.result.expected = "valid Duration values";
    evaluation.result.actual = "conversion error";
    return;
  }

  evaluation.result.addText(". ");

  betweenResults(currentValue, limit1, limit2, evaluation);
}

///
void betweenSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");

  SysTime currentValue;
  SysTime limit1;
  SysTime limit2;

  try {
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
    limit1 = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    limit2 = SysTime.fromISOExtString(evaluation.expectedValue.meta["1"]);

    evaluation.result.addValue(limit2.toISOExtString);
  } catch(Exception e) {
    evaluation.result.expected = "valid SysTime values";
    evaluation.result.actual = "conversion error";
    return;
  }

  evaluation.result.addText(". ");

  betweenResults(currentValue, limit1, limit2, evaluation);
}

private void betweenResults(T)(T currentValue, T limit1, T limit2, ref Evaluation evaluation) {
  T min = limit1 < limit2 ? limit1 : limit2;
  T max = limit1 > limit2 ? limit1 : limit2;

  auto isLess = currentValue <= min;
  auto isGreater = currentValue >= max;
  auto isBetween = !isLess && !isGreater;

  string interval;

  try {
    if (evaluation.isNegated) {
      interval = "a value outside (" ~ min.to!string ~ ", " ~ max.to!string ~ ") interval";
    } else {
      interval = "a value inside (" ~ min.to!string ~ ", " ~ max.to!string ~ ") interval";
    }
  } catch(Exception) {
    interval = evaluation.isNegated ? "a value outside the interval" : "a value inside the interval";
  }

  if(!evaluation.isNegated) {
    if(!isBetween) {
      evaluation.result.addValue(evaluation.currentValue.niceValue);

      if(isGreater) {
        evaluation.result.addText(" is greater than or equal to ");
        try evaluation.result.addValue(max.to!string);
        catch(Exception) {}
      }

      if(isLess) {
        evaluation.result.addText(" is less than or equal to ");
        try evaluation.result.addValue(min.to!string);
        catch(Exception) {}
      }

      evaluation.result.addText(".");

      evaluation.result.expected = interval;
      evaluation.result.actual = evaluation.currentValue.niceValue;
    }
  } else if(isBetween) {
    evaluation.result.expected = interval;
    evaluation.result.actual = evaluation.currentValue.niceValue;
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " value is inside an interval")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    Type middleValue = cast(Type) 45;
    expect(middleValue).to.be.between(smallValue, largeValue);
    expect(middleValue).to.be.between(largeValue, smallValue);
    expect(middleValue).to.be.within(smallValue, largeValue);
  }

  @(Type.stringof ~ " value is outside an interval")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    expect(largeValue).to.not.be.between(smallValue, largeValue);
    expect(largeValue).to.not.be.between(largeValue, smallValue);
    expect(largeValue).to.not.be.within(smallValue, largeValue);
  }

  @(Type.stringof ~ " throws error when value equals max of interval")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    auto msg = ({
      expect(largeValue).to.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
  }

  @(Type.stringof ~ " throws error when value equals min of interval")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    auto msg = ({
      expect(smallValue).to.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
  }

  @(Type.stringof ~ " throws error when negated assert fails")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    Type middleValue = cast(Type) 45;
    auto msg = ({
      expect(middleValue).to.not.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.startWith(middleValue.to!string ~ " should not be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    msg.split("\n")[2].strip.should.equal("Actual:" ~ middleValue.to!string);
  }
}

@("Duration value is inside an interval")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  Duration middleValue = 45.seconds;
  expect(middleValue).to.be.between(smallValue, largeValue);
  expect(middleValue).to.be.between(largeValue, smallValue);
  expect(middleValue).to.be.within(smallValue, largeValue);
}

@("Duration value is outside an interval")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  expect(largeValue).to.not.be.between(smallValue, largeValue);
  expect(largeValue).to.not.be.between(largeValue, smallValue);
  expect(largeValue).to.not.be.within(smallValue, largeValue);
}

@("Duration throws error when value equals max of interval")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  auto msg = ({
    expect(largeValue).to.be.between(smallValue, largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
  msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
}

@("Duration throws error when value equals min of interval")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  auto msg = ({
    expect(smallValue).to.be.between(smallValue, largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
  msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
}

@("Duration throws error when negated assert fails")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  Duration middleValue = 45.seconds;
  auto msg = ({
    expect(middleValue).to.not.be.between(smallValue, largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.startWith(middleValue.to!string ~ " should not be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
  msg.split("\n")[2].strip.should.equal("Actual:" ~ middleValue.to!string);
}

@("SysTime value is inside an interval")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  SysTime middleValue = Clock.currTime + 35.seconds;
  expect(middleValue).to.be.between(smallValue, largeValue);
  expect(middleValue).to.be.between(largeValue, smallValue);
  expect(middleValue).to.be.within(smallValue, largeValue);
}

@("SysTime value is outside an interval")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  expect(largeValue).to.not.be.between(smallValue, largeValue);
  expect(largeValue).to.not.be.between(largeValue, smallValue);
  expect(largeValue).to.not.be.within(smallValue, largeValue);
}

@("SysTime throws error when value equals max of interval")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  auto msg = ({
    expect(largeValue).to.be.between(smallValue, largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(largeValue.toISOExtString ~ " should be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ". " ~ largeValue.toISOExtString ~ " is greater than or equal to " ~ largeValue.toISOExtString ~ ".");
}

@("SysTime throws error when value equals min of interval")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  auto msg = ({
    expect(smallValue).to.be.between(smallValue, largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(smallValue.toISOExtString ~ " should be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ". " ~ smallValue.toISOExtString ~ " is less than or equal to " ~ smallValue.toISOExtString ~ ".");
}

@("SysTime throws error when negated assert fails")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  SysTime middleValue = Clock.currTime + 35.seconds;
  auto msg = ({
    expect(middleValue).to.not.be.between(smallValue, largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.startWith(middleValue.toISOExtString ~ " should not be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ".");
}
