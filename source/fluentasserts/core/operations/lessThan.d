module fluentasserts.core.operations.lessThan;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version(unittest) {
  import fluentasserts.core.expect;
  import fluentasserts.core.base : should, TestException;
}

static immutable lessThanDescription = "Asserts that the tested value is less than the tested value. However, it's often best to assert that the target is equal to its expected value.";

///
IResult[] lessThan(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  T expectedValue;
  T currentValue;

  try {
    expectedValue = evaluation.expectedValue.strValue.to!T;
    currentValue = evaluation.currentValue.strValue.to!T;
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to " ~ T.stringof) ];
  }

  auto result = currentValue < expectedValue;

  return lessThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

///
IResult[] lessThanDuration(ref Evaluation evaluation) @safe nothrow {
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
    return [ new MessageResult("Can't convert the values to Duration") ];
  }

  auto result = currentValue < expectedValue;

  return lessThanResults(result, niceExpectedValue, niceCurrentValue, evaluation);
}

///
IResult[] lessThanSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  SysTime expectedValue;
  SysTime currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to SysTime") ];
  }

  auto result = currentValue < expectedValue;

  return lessThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

/// Generic lessThan using proxy values - works for any comparable type
IResult[] lessThanGeneric(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  bool result = false;

  if (evaluation.currentValue.proxyValue !is null && evaluation.expectedValue.proxyValue !is null) {
    result = evaluation.currentValue.proxyValue.isLessThan(evaluation.expectedValue.proxyValue);
  }

  return lessThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private IResult[] lessThanResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is less than ");
    evaluation.result.expected = "greater than or equal to " ~ niceExpectedValue;
  } else {
    evaluation.result.addText(" is greater than or equal to ");
    evaluation.result.expected = "less than " ~ niceExpectedValue;
  }

  evaluation.result.actual = niceCurrentValue;
  evaluation.result.negated = evaluation.isNegated;

  evaluation.result.addValue(niceExpectedValue);
  evaluation.result.addText(".");

  return [];
}

@("lessThan passes when current value is less than expected")
unittest {
  5.should.be.lessThan(6);
}

@("lessThan fails when current value is greater than expected")
unittest {
  ({
    5.should.be.lessThan(4);
  }).should.throwException!TestException;
}

@("lessThan fails when values are equal")
unittest {
  ({
    5.should.be.lessThan(5);
  }).should.throwException!TestException;
}

@("lessThan works with negation")
unittest {
  5.should.not.be.lessThan(4);
  5.should.not.be.lessThan(5);
}

@("lessThan works with floating point")
unittest {
  3.14.should.be.lessThan(3.15);
  3.15.should.not.be.lessThan(3.14);
}

@("lessThan works with custom comparable struct")
unittest {
  static struct Money {
    int cents;
    int opCmp(Money other) const @safe nothrow {
      return cents - other.cents;
    }
  }

  Money(100).should.be.lessThan(Money(200));
  Money(200).should.not.be.lessThan(Money(100));
  Money(100).should.not.be.lessThan(Money(100));
}

@("below is alias for lessThan")
unittest {
  5.should.be.below(6);
  5.should.not.be.below(4);
}

