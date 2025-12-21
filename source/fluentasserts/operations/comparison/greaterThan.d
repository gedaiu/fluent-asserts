module fluentasserts.operations.comparison.greaterThan;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.core.toNumeric;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.meta;
  import std.string;
}

static immutable greaterThanDescription = "Asserts that the tested value is greater than the tested value. However, it's often best to assert that the target is equal to its expected value.";

void greaterThan(T)(ref Evaluation evaluation) @safe nothrow @nogc {
  auto expected = toNumeric!T(evaluation.expectedValue.strValue);
  auto current = toNumeric!T(evaluation.currentValue.strValue);

  if (!expected.success || !current.success) {
    evaluation.conversionError(T.stringof);
    return;
  }

  evaluation.check(
    current.value > expected.value,
    "greater than ",
    evaluation.expectedValue.strValue[],
    "less than or equal to "
  );
}

void greaterThanDuration(ref Evaluation evaluation) @safe nothrow @nogc {
  auto expected = toNumeric!ulong(evaluation.expectedValue.strValue);
  auto current = toNumeric!ulong(evaluation.currentValue.strValue);

  if (!expected.success || !current.success) {
    evaluation.conversionError("Duration");
    return;
  }

  Duration expectedDur = dur!"nsecs"(expected.value);
  Duration currentDur = dur!"nsecs"(current.value);

  evaluation.check(
    currentDur > expectedDur,
    "greater than ",
    evaluation.expectedValue.niceValue[],
    "less than or equal to "
  );
}

void greaterThanSysTime(ref Evaluation evaluation) @safe nothrow {
  SysTime expectedTime;
  SysTime currentTime;

  try {
    expectedTime = SysTime.fromISOExtString(evaluation.expectedValue.strValue[]);
    currentTime = SysTime.fromISOExtString(evaluation.currentValue.strValue[]);
  } catch (Exception e) {
    evaluation.conversionError("SysTime");
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
