module fluentasserts.operations.comparison.greaterOrEqualTo;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.core.conversion.tonumeric : toNumeric;

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

void greaterOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow @nogc {
  auto expected = toNumeric!T(evaluation.expectedValue.strValue);
  auto current = toNumeric!T(evaluation.currentValue.strValue);

  if (!expected.success || !current.success) {
    evaluation.conversionError(T.stringof);
    return;
  }

  evaluation.check(
    current.value >= expected.value,
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
