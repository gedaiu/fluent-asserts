module fluentasserts.operations.comparison.lessThan;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.core.toNumeric;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import fluentasserts.core.base : should, TestException;
  import fluentasserts.core.lifecycle;
}

static immutable lessThanDescription = "Asserts that the tested value is less than the tested value. However, it's often best to assert that the target is equal to its expected value.";

/// Asserts that a value is strictly less than the expected value.
void lessThan(T)(ref Evaluation evaluation) @safe nothrow @nogc {
  evaluation.result.addText(".");

  auto expectedParsed = toNumeric!T(evaluation.expectedValue.strValue);
  auto currentParsed = toNumeric!T(evaluation.currentValue.strValue);

  if (!expectedParsed.success || !currentParsed.success) {
    evaluation.result.expected.put("valid ");
    evaluation.result.expected.put(T.stringof);
    evaluation.result.expected.put(" values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  auto result = currentParsed.value < expectedParsed.value;

  lessThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

///
void lessThanDuration(ref Evaluation evaluation) @safe nothrow @nogc {
  evaluation.result.addText(".");

  auto expectedParsed = toNumeric!ulong(evaluation.expectedValue.strValue);
  auto currentParsed = toNumeric!ulong(evaluation.currentValue.strValue);

  if (!expectedParsed.success || !currentParsed.success) {
    evaluation.result.expected.put("valid Duration values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  Duration expectedValue = dur!"nsecs"(expectedParsed.value);
  Duration currentValue = dur!"nsecs"(currentParsed.value);

  auto result = currentValue < expectedValue;

  lessThanResults(result, evaluation.expectedValue.niceValue, evaluation.currentValue.niceValue, evaluation);
}

///
void lessThanSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  SysTime expectedValue;
  SysTime currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
  } catch(Exception e) {
    evaluation.result.expected.put("valid SysTime values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  auto result = currentValue < expectedValue;

  lessThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

/// Generic lessThan using proxy values - works for any comparable type
void lessThanGeneric(ref Evaluation evaluation) @safe nothrow @nogc {
  evaluation.result.addText(".");

  bool result = false;

  if (evaluation.currentValue.proxyValue !is null && evaluation.expectedValue.proxyValue !is null) {
    result = evaluation.currentValue.proxyValue.isLessThan(evaluation.expectedValue.proxyValue);
  }

  lessThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private void lessThanResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow @nogc {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is less than ");
    evaluation.result.expected.put("greater than or equal to ");
    evaluation.result.expected.put(niceExpectedValue);
  } else {
    evaluation.result.addText(" is greater than or equal to ");
    evaluation.result.expected.put("less than ");
    evaluation.result.expected.put(niceExpectedValue);
  }

  evaluation.result.actual.put(niceCurrentValue);
  evaluation.result.negated = evaluation.isNegated;

  evaluation.result.addValue(niceExpectedValue);
  evaluation.result.addText(".");
}

@("lessThan passes when current value is less than expected")
unittest {
  5.should.be.lessThan(6);
}

@("5 lessThan 4 reports error with expected and actual")
unittest {
  auto evaluation = ({
    5.should.be.lessThan(4);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less than 4");
  expect(evaluation.result.actual[]).to.equal("5");
}

@("5 lessThan 5 reports error with expected and actual")
unittest {
  auto evaluation = ({
    5.should.be.lessThan(5);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less than 5");
  expect(evaluation.result.actual[]).to.equal("5");
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
    int opCmp(Money other) const @safe nothrow @nogc {
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

@("haveExecutionTime passes for fast code")
unittest {
  ({

  }).should.haveExecutionTime.lessThan(1.seconds);
}

@("haveExecutionTime reports error when code takes too long")
unittest {
  import core.thread;

  auto evaluation = ({
    ({
      Thread.sleep(2.msecs);
    }).should.haveExecutionTime.lessThan(1.msecs);
  }).recordEvaluation;

  expect(evaluation.result.hasContent()).to.equal(true);
}
