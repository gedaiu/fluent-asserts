module fluentasserts.operations.comparison.greaterThan;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.core.conversion.numericcompare : compareNumeric, isComparableNumeric;

import fluentasserts.core.lifecycle;

import std.datetime;
import std.meta : AliasSeq;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.conv : to;
  import std.meta;
  import std.string;
}

static immutable greaterThanDescription = "Asserts that the tested value is greater than the tested value. However, it's often best to assert that the target is equal to its expected value.";

void greaterThan(T)(ref Evaluation evaluation) @safe nothrow @nogc if (isComparableNumeric!T) {
  auto cmp = compareNumeric(
    evaluation.currentValue.typeName, evaluation.currentValue.strValue,
    evaluation.expectedValue.typeName, evaluation.expectedValue.strValue);

  if (!cmp.success) {
    evaluation.conversionError(T.stringof);
    return;
  }

  evaluation.check(
    cmp.order > 0,
    "greater than ",
    evaluation.expectedValue.strValue[],
    "less than or equal to "
  );
}

void greaterThanDuration(ref Evaluation evaluation) @safe nothrow @nogc {
  Duration currentDur, expectedDur;
  if (!evaluation.parseDurations(currentDur, expectedDur)) {
    return;
  }

  evaluation.check(
    currentDur > expectedDur,
    "greater than ",
    evaluation.expectedValue.niceValue[],
    "less than or equal to "
  );
}

void greaterThanSysTime(ref Evaluation evaluation) @safe nothrow {
  SysTime currentTime, expectedTime;
  if (!evaluation.parseSysTimes(currentTime, expectedTime)) {
    return;
  }

  evaluation.check(
    currentTime > expectedTime,
    "greater than ",
    evaluation.expectedValue.strValue[],
    "less than or equal to "
  );
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
    expect(largeValue).to.be.greaterThan(smallValue);
    expect(largeValue).to.be.above(smallValue);
  }

  @(Type.stringof ~ " compares two values using negation")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    expect(smallValue).not.to.be.greaterThan(largeValue);
    expect(smallValue).not.to.be.above(largeValue);
  }

  @(Type.stringof ~ " 40 greaterThan 40 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;

    auto evaluation = ({
      expect(smallValue).to.be.greaterThan(smallValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("greater than " ~ smallValue.to!string);
    expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
  }

  @(Type.stringof ~ " 40 greaterThan 50 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(smallValue).to.be.greaterThan(largeValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("greater than " ~ largeValue.to!string);
    expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
  }

  @(Type.stringof ~ " 50 not greaterThan 40 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(largeValue).not.to.be.greaterThan(smallValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("less than or equal to " ~ smallValue.to!string);
    expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
  }
}

@("greaterThan compares a double actual with an int expected")
unittest {
  expect(cast(double) 3.22681e+10).to.be.greaterThan(0);
}

@("greaterThan compares an int actual with a double expected")
unittest {
  expect(5).to.be.greaterThan(2.5);
}

@("greaterThan compares a negative signed value with an unsigned value by true value")
unittest {
  expect(-1).not.to.be.greaterThan(1u);
}

@("greaterThan keeps precision for ulong values near the maximum")
unittest {
  expect(ulong.max).to.be.greaterThan(ulong.max - 1);
}

@("greater is an alias for greaterThan")
unittest {
  expect(5).to.be.greater(2);
  expect(2).not.to.be.greater(5);
}

@("Duration compares two values")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 41.seconds;
  expect(largeValue).to.be.greaterThan(smallValue);
  expect(largeValue).to.be.above(smallValue);
}

@("Duration compares two values using negation")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 41.seconds;
  expect(smallValue).not.to.be.greaterThan(largeValue);
  expect(smallValue).not.to.be.above(largeValue);
}

@("Duration 40s greaterThan 40s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;

  auto evaluation = ({
    expect(smallValue).to.be.greaterThan(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("greater than " ~ smallValue.to!string);
  expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
}

@("Duration 41s not greaterThan 40s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 41.seconds;

  auto evaluation = ({
    expect(largeValue).not.to.be.greaterThan(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less than or equal to " ~ smallValue.to!string);
  expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
}

@("SysTime compares two values")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  expect(largeValue).to.be.greaterThan(smallValue);
  expect(largeValue).to.be.above(smallValue);
}

@("SysTime compares two values using negation")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;
  expect(smallValue).not.to.be.greaterThan(largeValue);
  expect(smallValue).not.to.be.above(largeValue);
}

@("SysTime greaterThan itself reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;

  auto evaluation = ({
    expect(smallValue).to.be.greaterThan(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("greater than " ~ smallValue.toISOExtString);
  expect(evaluation.result.actual[]).to.equal(smallValue.toISOExtString);
}

@("SysTime larger not greaterThan smaller reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;

  auto evaluation = ({
    expect(largeValue).not.to.be.greaterThan(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less than or equal to " ~ smallValue.toISOExtString);
  expect(evaluation.result.actual[]).to.equal(largeValue.toISOExtString);
}
