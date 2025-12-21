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

void lessThan(T)(ref Evaluation evaluation) @safe nothrow @nogc {
  auto expected = toNumeric!T(evaluation.expectedValue.strValue);
  auto current = toNumeric!T(evaluation.currentValue.strValue);

  if (!expected.success || !current.success) {
    evaluation.conversionError(T.stringof);
    return;
  }

  evaluation.check(
    current.value < expected.value,
    "less than ",
    evaluation.expectedValue.strValue[],
    "greater than or equal to "
  );
}

void lessThanDuration(ref Evaluation evaluation) @safe nothrow @nogc {
  Duration currentDur, expectedDur;
  if (!evaluation.parseDurations(currentDur, expectedDur)) {
    return;
  }

  evaluation.check(
    currentDur < expectedDur,
    "less than ",
    evaluation.expectedValue.niceValue[],
    "greater than or equal to "
  );
}

void lessThanSysTime(ref Evaluation evaluation) @safe nothrow {
  SysTime currentTime, expectedTime;
  if (!evaluation.parseSysTimes(currentTime, expectedTime)) {
    return;
  }

  evaluation.check(
    currentTime < expectedTime,
    "less than ",
    evaluation.expectedValue.strValue[],
    "greater than or equal to "
  );
}

void lessThanGeneric(ref Evaluation evaluation) @safe nothrow @nogc {
  bool result = false;

  if (!evaluation.currentValue.proxyValue.isNull() && !evaluation.expectedValue.proxyValue.isNull()) {
    result = evaluation.currentValue.proxyValue.isLessThan(evaluation.expectedValue.proxyValue);
  }

  evaluation.check(
    result,
    "less than ",
    evaluation.expectedValue.strValue[],
    "greater than or equal to "
  );
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
