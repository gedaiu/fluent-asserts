module fluentasserts.operations.comparison.lessOrEqualTo;

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

static immutable lessOrEqualToDescription = "Asserts that the tested value is less or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

///
void lessOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow {
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

  auto result = currentValue <= expectedValue;

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is less or equal to ");
    evaluation.result.expected = "greater than " ~ evaluation.expectedValue.niceValue;
  } else {
    evaluation.result.addText(" is greater than ");
    evaluation.result.expected = "less or equal to " ~ evaluation.expectedValue.niceValue;
  }

  evaluation.result.actual = evaluation.currentValue.niceValue;
  evaluation.result.negated = evaluation.isNegated;

  evaluation.result.addValue(evaluation.expectedValue.niceValue);
  evaluation.result.addText(".");
}

///
void lessOrEqualToDuration(ref Evaluation evaluation) @safe nothrow {
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

  auto result = currentValue <= expectedValue;

  lessOrEqualToResults(result, niceExpectedValue, niceCurrentValue, evaluation);
}

///
void lessOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  SysTime expectedValue;
  SysTime currentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
  } catch(Exception e) {
    evaluation.result.expected = "valid SysTime values";
    evaluation.result.actual = "conversion error";
    return;
  }

  auto result = currentValue <= expectedValue;

  lessOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private void lessOrEqualToResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is less or equal to ");
    evaluation.result.expected = "greater than " ~ niceExpectedValue;
  } else {
    evaluation.result.addText(" is greater than ");
    evaluation.result.expected = "less or equal to " ~ niceExpectedValue;
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
    expect(smallValue).to.be.lessOrEqualTo(largeValue);
    expect(smallValue).to.be.lessOrEqualTo(smallValue);
  }

  @(Type.stringof ~ " compares two values using negation")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    expect(largeValue).not.to.be.lessOrEqualTo(smallValue);
  }

  @(Type.stringof ~ " throws error when comparison fails")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    auto msg = ({
      expect(largeValue).to.be.lessOrEqualTo(smallValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be less or equal to " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than " ~ smallValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:less or equal to " ~ smallValue.to!string);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
  }

  @(Type.stringof ~ " throws error when negated comparison fails")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    auto msg = ({
      expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.to!string ~ " should not be less or equal to " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less or equal to " ~ largeValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:not greater than " ~ largeValue.to!string);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
  }
}

@("Duration compares two values")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  expect(smallValue).to.be.lessOrEqualTo(largeValue);
  expect(smallValue).to.be.lessOrEqualTo(smallValue);
}

@("Duration compares two values using negation")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  expect(largeValue).not.to.be.lessOrEqualTo(smallValue);
}

@("Duration throws error when comparison fails")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  auto msg = ({
    expect(largeValue).to.be.lessOrEqualTo(smallValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be less or equal to " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than " ~ smallValue.to!string ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:less or equal to " ~ smallValue.to!string);
  msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
}

@("Duration throws error when negated comparison fails")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  auto msg = ({
    expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(smallValue.to!string ~ " should not be less or equal to " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less or equal to " ~ largeValue.to!string ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:not greater than " ~ largeValue.to!string);
  msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
}

@("SysTime compares two values")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  expect(smallValue).to.be.lessOrEqualTo(largeValue);
  expect(smallValue).to.be.lessOrEqualTo(smallValue);
}

@("SysTime compares two values using negation")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  expect(largeValue).not.to.be.lessOrEqualTo(smallValue);
}

@("SysTime throws error when comparison fails")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  auto msg = ({
    expect(largeValue).to.be.lessOrEqualTo(smallValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(largeValue.toISOExtString ~ " should be less or equal to " ~ smallValue.toISOExtString ~ ". " ~ largeValue.toISOExtString ~ " is greater than " ~ smallValue.toISOExtString ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:less or equal to " ~ smallValue.toISOExtString);
  msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.toISOExtString);
}

@("SysTime throws error when negated comparison fails")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  auto msg = ({
    expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(smallValue.toISOExtString ~ " should not be less or equal to " ~ largeValue.toISOExtString ~ ". " ~ smallValue.toISOExtString ~ " is less or equal to " ~ largeValue.toISOExtString ~ ".");
  msg.split("\n")[1].strip.should.equal("Expected:not greater than " ~ largeValue.toISOExtString);
  msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.toISOExtString);
}
