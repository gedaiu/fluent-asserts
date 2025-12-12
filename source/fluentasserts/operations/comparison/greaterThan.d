module fluentasserts.operations.comparison.greaterThan;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

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

///
void greaterThan(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  T expectedValue;
  T currentValue;

  try {
    expectedValue = evaluation.expectedValue.strValue.to!T;
    currentValue = evaluation.currentValue.strValue.to!T;
  } catch(Exception e) {
    evaluation.result.expected.put("valid ");
    evaluation.result.expected.put(T.stringof);
    evaluation.result.expected.put(" values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  auto result = currentValue > expectedValue;

  greaterThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

///
void greaterThanDuration(ref Evaluation evaluation) @safe nothrow {
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
    evaluation.result.expected.put("valid Duration values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  auto result = currentValue > expectedValue;

  greaterThanResults(result, niceExpectedValue, niceCurrentValue, evaluation);
}

///
void greaterThanSysTime(ref Evaluation evaluation) @safe nothrow {
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

  auto result = currentValue > expectedValue;

  greaterThanResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private void greaterThanResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow @nogc {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is greater than ");
    evaluation.result.expected.put("less than or equal to ");
    evaluation.result.expected.put(niceExpectedValue);
  } else {
    evaluation.result.addText(" is less than or equal to ");
    evaluation.result.expected.put("greater than ");
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
