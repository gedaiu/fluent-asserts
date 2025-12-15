module fluentasserts.operations.comparison.greaterOrEqualTo;

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

static immutable greaterOrEqualToDescription = "Asserts that the tested value is greater or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

/// Asserts that a value is greater than or equal to the expected value.
void greaterOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow @nogc {
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

  auto result = currentParsed.value >= expectedParsed.value;

  greaterOrEqualToResults(result, evaluation.expectedValue.strValue[], evaluation.currentValue.strValue[], evaluation);
}

void greaterOrEqualToDuration(ref Evaluation evaluation) @safe nothrow @nogc {
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

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, evaluation.expectedValue.niceValue[], evaluation.currentValue.niceValue[], evaluation);
}

void greaterOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  SysTime expectedValue;
  SysTime currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue[]);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue[]);
  } catch(Exception e) {
    evaluation.result.expected.put("valid SysTime values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, evaluation.expectedValue.strValue[], evaluation.currentValue.strValue[], evaluation);
}

private void greaterOrEqualToResults(bool result, const(char)[] niceExpectedValue, const(char)[] niceCurrentValue, ref Evaluation evaluation) @safe nothrow @nogc {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue[]);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is greater or equal than ");
    evaluation.result.expected.put("less than ");
    evaluation.result.expected.put(niceExpectedValue);
  } else {
    evaluation.result.addText(" is less than ");
    evaluation.result.expected.put("greater or equal than ");
    evaluation.result.expected.put(niceExpectedValue);
  }

  evaluation.result.actual.put(niceCurrentValue);
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
