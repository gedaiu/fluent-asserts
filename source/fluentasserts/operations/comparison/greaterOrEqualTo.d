module fluentasserts.operations.comparison.greaterOrEqualTo;

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

static immutable greaterOrEqualToDescription = "Asserts that the tested value is greater or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

///
void greaterOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  T expectedValue;
  T currentValue;

  try {
    expectedValue = evaluation.expectedValue.strValue.to!T;
    currentValue = evaluation.currentValue.strValue.to!T;
  } catch(Exception e) {
    evaluation.result.expected = "valid " ~ T.stringof ~ " values";
    evaluation.result.actual = "conversion error";
    return;
  }

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

void greaterOrEqualToDuration(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  Duration expectedValue;
  Duration currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = dur!"nsecs"(evaluation.expectedValue.strValue.to!size_t);
    currentValue = dur!"nsecs"(evaluation.currentValue.strValue.to!size_t);

    niceExpectedValue = expectedValue.to!string;
    niceCurrentValue = currentValue.to!string;
  } catch(Exception e) {
    evaluation.result.expected = "valid Duration values";
    evaluation.result.actual = "conversion error";
    return;
  }

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, niceExpectedValue, niceCurrentValue, evaluation);
}

void greaterOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  SysTime expectedValue;
  SysTime currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
  } catch(Exception e) {
    evaluation.result.expected = "valid SysTime values";
    evaluation.result.actual = "conversion error";
    return;
  }

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private void greaterOrEqualToResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is greater or equal than ");
    evaluation.result.expected = "less than " ~ niceExpectedValue;
  } else {
    evaluation.result.addText(" is less than ");
    evaluation.result.expected = "greater or equal than " ~ niceExpectedValue;
  }

  evaluation.result.actual = niceCurrentValue;
  evaluation.result.negated = evaluation.isNegated;

  evaluation.result.addValue(niceExpectedValue);
  evaluation.result.addText(".");
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " compares two values")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    expect(largeValue).to.be.greaterOrEqualTo(smallValue);
    expect(largeValue).to.be.greaterOrEqualTo(largeValue);
  }

  @(Type.stringof ~ " compares two values using negation")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    expect(smallValue).not.to.be.greaterOrEqualTo(largeValue);
  }

  @(Type.stringof ~ " throws error when comparison fails")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    auto msg = ({
      expect(smallValue).to.be.greaterOrEqualTo(largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be greater or equal to " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than " ~ largeValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:greater or equal than " ~ largeValue.to!string);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
  }

  @(Type.stringof ~ " throws error when negated comparison fails")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    auto msg = ({
      expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(largeValue.to!string ~ " should not be greater or equal to " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater or equal than " ~ smallValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:not less than " ~ smallValue.to!string);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
  }
}

@("Duration compares two values")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 41.seconds;
  expect(largeValue).to.be.greaterOrEqualTo(smallValue);
}

@("Duration compares two values using negation")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 41.seconds;
  expect(smallValue).not.to.be.greaterOrEqualTo(largeValue);
}

@("Duration does not throw when compared with itself")
unittest {
  Duration smallValue = 40.seconds;
  expect(smallValue).to.be.greaterOrEqualTo(smallValue);
}

@("Duration throws error when negated comparison fails")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 41.seconds;
  auto msg = ({
    expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(largeValue.to!string ~ " should not be greater or equal to " ~ smallValue.to!string ~ ". " ~
    largeValue.to!string ~ " is greater or equal than " ~ smallValue.to!string ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:not less than " ~ smallValue.to!string);
  msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
}

@("SysTime compares two values")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  expect(largeValue).to.be.greaterOrEqualTo(smallValue);
  expect(largeValue).to.be.above(smallValue);
}

@("SysTime compares two values using negation")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  expect(smallValue).not.to.be.greaterOrEqualTo(largeValue);
  expect(smallValue).not.to.be.above(largeValue);
}

@("SysTime does not throw when compared with itself")
unittest {
  SysTime smallValue = Clock.currTime;
  expect(smallValue).to.be.greaterOrEqualTo(smallValue);
}

@("SysTime throws error when negated comparison fails")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  auto msg = ({
    expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(largeValue.toISOExtString ~ " should not be greater or equal to " ~ smallValue.toISOExtString ~ ". " ~
    largeValue.toISOExtString ~ " is greater or equal than " ~ smallValue.toISOExtString ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:not less than " ~ smallValue.toISOExtString);
  msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.toISOExtString);
}
