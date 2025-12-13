module fluentasserts.operations.comparison.lessOrEqualTo;

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

static immutable lessOrEqualToDescription = "Asserts that the tested value is less or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

/// Asserts that a value is less than or equal to the expected value.
void lessOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow @nogc {
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

  auto result = currentParsed.value <= expectedParsed.value;

  lessOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

/// Asserts that a Duration value is less than or equal to the expected Duration.
void lessOrEqualToDuration(ref Evaluation evaluation) @safe nothrow @nogc {
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

  auto result = currentValue <= expectedValue;

  lessOrEqualToResults(result, evaluation.expectedValue.niceValue, evaluation.currentValue.niceValue, evaluation);
}

/// Asserts that a SysTime value is less than or equal to the expected SysTime.
void lessOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  SysTime expectedValue;
  SysTime currentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
  } catch(Exception e) {
    evaluation.result.expected.put("valid SysTime values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  auto result = currentValue <= expectedValue;

  lessOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private void lessOrEqualToResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow @nogc {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is less or equal to ");
    evaluation.result.expected.put("greater than ");
    evaluation.result.expected.put(niceExpectedValue);
  } else {
    evaluation.result.addText(" is greater than ");
    evaluation.result.expected.put("less or equal to ");
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
