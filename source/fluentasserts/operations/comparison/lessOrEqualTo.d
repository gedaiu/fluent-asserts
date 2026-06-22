module fluentasserts.operations.comparison.lessOrEqualTo;

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

static immutable lessOrEqualToDescription = "Asserts that the tested value is less or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

void lessOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow @nogc if (isComparableNumeric!T) {
  auto cmp = compareNumeric(
    evaluation.currentValue.typeName, evaluation.currentValue.strValue,
    evaluation.expectedValue.typeName, evaluation.expectedValue.strValue);

  if (!cmp.success) {
    evaluation.conversionError(T.stringof);
    return;
  }

  evaluation.check(
    cmp.order <= 0,
    "less or equal to ",
    evaluation.expectedValue.strValue[],
    "greater than "
  );
}

void lessOrEqualToDuration(ref Evaluation evaluation) @safe nothrow @nogc {
  Duration currentDur, expectedDur;
  if (!evaluation.parseDurations(currentDur, expectedDur)) {
    return;
  }

  evaluation.check(
    currentDur <= expectedDur,
    "less or equal to ",
    evaluation.expectedValue.niceValue[],
    "greater than "
  );
}

void lessOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  SysTime currentTime, expectedTime;
  if (!evaluation.parseSysTimes(currentTime, expectedTime)) {
    return;
  }

  evaluation.check(
    currentTime <= expectedTime,
    "less or equal to ",
    evaluation.expectedValue.strValue[],
    "greater than "
  );
}

// ---------------------------------------------------------------------------
// Unit tests
// Issue #93: lessOrEqualTo operation for numeric types
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

  @(Type.stringof ~ " 50 lessOrEqualTo 40 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(largeValue).to.be.lessOrEqualTo(smallValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("less or equal to " ~ smallValue.to!string);
    expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
  }

  @(Type.stringof ~ " 40 not lessOrEqualTo 50 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("greater than " ~ largeValue.to!string);
    expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
  }
}

@("lessOrEqualTo compares a double actual with an int expected")
unittest {
  expect(cast(double) 2.5).to.be.lessOrEqualTo(3);
}

@("lessOrEqualTo compares an equal int actual with a double expected")
unittest {
  expect(3).to.be.lessOrEqualTo(3.0);
}

@("lessOrEqualTo compares a negative signed value with an unsigned value by true value")
unittest {
  expect(-1).to.be.lessOrEqualTo(1u);
}

@("lessOrEqualTo keeps precision for ulong values near the maximum")
unittest {
  expect(ulong.max - 1).to.be.lessOrEqualTo(ulong.max);
}

@("lessOrEqual is an alias for lessOrEqualTo")
unittest {
  expect(2).to.be.lessOrEqual(5);
  expect(5).to.be.lessOrEqual(5);
  expect(5).not.to.be.lessOrEqual(2);
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

@("Duration 50s lessOrEqualTo 40s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;

  auto evaluation = ({
    expect(largeValue).to.be.lessOrEqualTo(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less or equal to " ~ smallValue.to!string);
  expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
}

@("Duration 40s not lessOrEqualTo 50s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;

  auto evaluation = ({
    expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("greater than " ~ largeValue.to!string);
  expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
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

@("SysTime larger lessOrEqualTo smaller reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;

  auto evaluation = ({
    expect(largeValue).to.be.lessOrEqualTo(smallValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("less or equal to " ~ smallValue.toISOExtString);
  expect(evaluation.result.actual[]).to.equal(largeValue.toISOExtString);
}

@("SysTime smaller not lessOrEqualTo larger reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = smallValue + 4.seconds;

  auto evaluation = ({
    expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("greater than " ~ largeValue.toISOExtString);
  expect(evaluation.result.actual[]).to.equal(smallValue.toISOExtString);
}
