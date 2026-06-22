module fluentasserts.operations.comparison.greaterOrEqualTo;

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

static immutable greaterOrEqualToDescription = "Asserts that the tested value is greater or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

void greaterOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow @nogc if (isComparableNumeric!T) {
  auto cmp = compareNumeric(
    evaluation.currentValue.typeName, evaluation.currentValue.strValue,
    evaluation.expectedValue.typeName, evaluation.expectedValue.strValue);

  if (!cmp.success) {
    evaluation.conversionError(T.stringof);
    return;
  }

  evaluation.check(
    cmp.order >= 0,
    "greater or equal than ",
    evaluation.expectedValue.strValue[],
    "less than "
  );
}

void greaterOrEqualToDuration(ref Evaluation evaluation) @safe nothrow @nogc {
  Duration currentDur, expectedDur;
  if (!evaluation.parseDurations(currentDur, expectedDur)) {
    return;
  }

  evaluation.check(
    currentDur >= expectedDur,
    "greater or equal than ",
    evaluation.expectedValue.niceValue[],
    "less than "
  );
}

void greaterOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  SysTime currentTime, expectedTime;
  if (!evaluation.parseSysTimes(currentTime, expectedTime)) {
    return;
  }

  evaluation.check(
    currentTime >= expectedTime,
    "greater or equal than ",
    evaluation.expectedValue.strValue[],
    "less than "
  );
}

// ---------------------------------------------------------------------------
// Unit tests
// Issue #93: greaterOrEqualTo operation for numeric types
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

  @(Type.stringof ~ " 40 greaterOrEqualTo 50 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(smallValue).to.be.greaterOrEqualTo(largeValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("greater or equal than " ~ largeValue.to!string);
    expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
  }

  @(Type.stringof ~ " 50 not greaterOrEqualTo 40 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("less than " ~ smallValue.to!string);
    expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
  }
}

@("greaterOrEqualTo compares a double actual with an int expected")
unittest {
  expect(cast(double) 3.5).to.be.greaterOrEqualTo(3);
}

@("greaterOrEqualTo compares an equal int actual with a double expected")
unittest {
  expect(3).to.be.greaterOrEqualTo(3.0);
}

@("greaterOrEqualTo compares a negative signed value with an unsigned value by true value")
unittest {
  expect(-1).not.to.be.greaterOrEqualTo(1u);
}

@("greaterOrEqualTo keeps precision for ulong values near the maximum")
unittest {
  expect(ulong.max).to.be.greaterOrEqualTo(ulong.max);
}

@("greaterOrEqual is an alias for greaterOrEqualTo")
unittest {
  expect(5).to.be.greaterOrEqual(2);
  expect(5).to.be.greaterOrEqual(5);
  expect(2).not.to.be.greaterOrEqual(5);
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

@("Duration compares equal values")
unittest {
  Duration smallValue = 40.seconds;
  expect(smallValue).to.be.greaterOrEqualTo(smallValue);
}

@("Duration 41s not greaterOrEqualTo 40s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 41.seconds;

  auto evaluation = ({
    expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less than " ~ smallValue.to!string);
  expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
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

@("SysTime compares equal values")
unittest {
  SysTime smallValue = Clock.currTime;
  expect(smallValue).to.be.greaterOrEqualTo(smallValue);
}

@("SysTime larger not greaterOrEqualTo smaller reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;

  auto evaluation = ({
    expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less than " ~ smallValue.toISOExtString);
  expect(evaluation.result.actual[]).to.equal(largeValue.toISOExtString);
}
