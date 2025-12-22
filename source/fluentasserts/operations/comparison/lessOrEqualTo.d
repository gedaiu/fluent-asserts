module fluentasserts.operations.comparison.lessOrEqualTo;

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

static immutable lessOrEqualToDescription = "Asserts that the tested value is less or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

void lessOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow @nogc {
  auto expected = toNumeric!T(evaluation.expectedValue.strValue);
  auto current = toNumeric!T(evaluation.currentValue.strValue);

  if (!expected.success || !current.success) {
    evaluation.conversionError(T.stringof);
    return;
  }

  evaluation.check(
    current.value <= expected.value,
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
