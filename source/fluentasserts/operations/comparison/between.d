module fluentasserts.operations.comparison.between;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.core.toNumeric;
import fluentasserts.core.heapdata : toHeapString;

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

static immutable betweenDescription = "Asserts that the target is a number or a date greater than or equal to the given number or date start, " ~
  "and less than or equal to the given number or date finish respectively. However, it's often best to assert that the target is equal to its expected value.";

/// Asserts that a value is strictly between two bounds (exclusive).
void between(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");
  evaluation.result.addValue(evaluation.expectedValue.meta["1"]);
  evaluation.result.addText(". ");

  auto currentParsed = toNumeric!T(evaluation.currentValue.strValue);
  auto limit1Parsed = toNumeric!T(evaluation.expectedValue.strValue);
  auto limit2Parsed = toNumeric!T(toHeapString(evaluation.expectedValue.meta["1"]));

  if (!currentParsed.success || !limit1Parsed.success || !limit2Parsed.success) {
    evaluation.result.expected.put("valid ");
    evaluation.result.expected.put(T.stringof);
    evaluation.result.expected.put(" values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  betweenResults(currentParsed.value, limit1Parsed.value, limit2Parsed.value,
      evaluation.expectedValue.strValue[], evaluation.expectedValue.meta["1"], evaluation);
}


/// Asserts that a Duration value is strictly between two bounds (exclusive).
void betweenDuration(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");

  auto currentParsed = toNumeric!ulong(evaluation.currentValue.strValue);
  auto limit1Parsed = toNumeric!ulong(evaluation.expectedValue.strValue);
  auto limit2Parsed = toNumeric!ulong(toHeapString(evaluation.expectedValue.meta["1"]));

  if (!currentParsed.success || !limit1Parsed.success || !limit2Parsed.success) {
    evaluation.result.expected.put("valid Duration values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  Duration currentValue = dur!"nsecs"(currentParsed.value);
  Duration limit1 = dur!"nsecs"(limit1Parsed.value);
  Duration limit2 = dur!"nsecs"(limit2Parsed.value);

  // Format Duration values nicely (requires allocation, can't be @nogc)
  string strLimit1, strLimit2;
  try {
    strLimit1 = limit1.to!string;
    strLimit2 = limit2.to!string;
  } catch (Exception) {
    evaluation.result.expected.put("valid Duration values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  evaluation.result.addValue(strLimit2);
  evaluation.result.addText(". ");

  betweenResultsDuration(currentValue, limit1, limit2, strLimit1, strLimit2, evaluation);
}

/// Asserts that a SysTime value is strictly between two bounds (exclusive).
void betweenSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");

  SysTime currentValue;
  SysTime limit1;
  SysTime limit2;

  try {
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue[]);
    limit1 = SysTime.fromISOExtString(evaluation.expectedValue.strValue[]);
    limit2 = SysTime.fromISOExtString(evaluation.expectedValue.meta["1"]);

    evaluation.result.addValue(limit2.toISOExtString);
  } catch(Exception e) {
    evaluation.result.expected.put("valid SysTime values");
    evaluation.result.actual.put("conversion error");
    return;
  }

  evaluation.result.addText(". ");

  betweenResults(currentValue, limit1, limit2,
      evaluation.expectedValue.strValue[], evaluation.expectedValue.meta["1"], evaluation);
}

/// Helper for Duration between - separate because Duration formatting can't be @nogc
private void betweenResultsDuration(Duration currentValue, Duration limit1, Duration limit2,
    string strLimit1, string strLimit2, ref Evaluation evaluation) @safe nothrow {
  Duration min = limit1 < limit2 ? limit1 : limit2;
  Duration max = limit1 > limit2 ? limit1 : limit2;

  auto isLess = currentValue <= min;
  auto isGreater = currentValue >= max;
  auto isBetween = !isLess && !isGreater;

  string minStr = limit1 < limit2 ? strLimit1 : strLimit2;
  string maxStr = limit1 > limit2 ? strLimit1 : strLimit2;

  if (!evaluation.isNegated) {
    if (!isBetween) {
      evaluation.result.addValue(evaluation.currentValue.niceValue[]);

      if (isGreater) {
        evaluation.result.addText(" is greater than or equal to ");
        evaluation.result.addValue(maxStr);
      }

      if (isLess) {
        evaluation.result.addText(" is less than or equal to ");
        evaluation.result.addValue(minStr);
      }

      evaluation.result.addText(".");

      evaluation.result.expected.put("a value inside (");
      evaluation.result.expected.put(minStr);
      evaluation.result.expected.put(", ");
      evaluation.result.expected.put(maxStr);
      evaluation.result.expected.put(") interval");
      evaluation.result.actual.put(evaluation.currentValue.niceValue[]);
    }
  } else if (isBetween) {
    evaluation.result.expected.put("a value outside (");
    evaluation.result.expected.put(minStr);
    evaluation.result.expected.put(", ");
    evaluation.result.expected.put(maxStr);
    evaluation.result.expected.put(") interval");
    evaluation.result.actual.put(evaluation.currentValue.niceValue[]);
    evaluation.result.negated = true;
  }
}

private void betweenResults(T)(T currentValue, T limit1, T limit2,
    const(char)[] strMin, const(char)[] strMax, ref Evaluation evaluation) @safe nothrow @nogc {
  T min = limit1 < limit2 ? limit1 : limit2;
  T max = limit1 > limit2 ? limit1 : limit2;

  auto isLess = currentValue <= min;
  auto isGreater = currentValue >= max;
  auto isBetween = !isLess && !isGreater;

  // Determine which string is min/max based on value comparison
  const(char)[] minStr = limit1 < limit2 ? strMin : strMax;
  const(char)[] maxStr = limit1 > limit2 ? strMin : strMax;

  if (!evaluation.isNegated) {
    if (!isBetween) {
      evaluation.result.addValue(evaluation.currentValue.niceValue[]);

      if (isGreater) {
        evaluation.result.addText(" is greater than or equal to ");
        evaluation.result.addValue(maxStr);
      }

      if (isLess) {
        evaluation.result.addText(" is less than or equal to ");
        evaluation.result.addValue(minStr);
      }

      evaluation.result.addText(".");

      evaluation.result.expected.put("a value inside (");
      evaluation.result.expected.put(minStr);
      evaluation.result.expected.put(", ");
      evaluation.result.expected.put(maxStr);
      evaluation.result.expected.put(") interval");
      evaluation.result.actual.put(evaluation.currentValue.niceValue[]);
    }
  } else if (isBetween) {
    evaluation.result.expected.put("a value outside (");
    evaluation.result.expected.put(minStr);
    evaluation.result.expected.put(", ");
    evaluation.result.expected.put(maxStr);
    evaluation.result.expected.put(") interval");
    evaluation.result.actual.put(evaluation.currentValue.niceValue[]);
    evaluation.result.negated = true;
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " value is inside an interval")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    Type middleValue = cast(Type) 45;
    expect(middleValue).to.be.between(smallValue, largeValue);
    expect(middleValue).to.be.between(largeValue, smallValue);
    expect(middleValue).to.be.within(smallValue, largeValue);
  }

  @(Type.stringof ~ " value is outside an interval")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    expect(largeValue).to.not.be.between(smallValue, largeValue);
    expect(largeValue).to.not.be.between(largeValue, smallValue);
    expect(largeValue).to.not.be.within(smallValue, largeValue);
  }

  @(Type.stringof ~ " 50 between 40 and 50 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(largeValue).to.be.between(smallValue, largeValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
  }

  @(Type.stringof ~ " 40 between 40 and 50 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;

    auto evaluation = ({
      expect(smallValue).to.be.between(smallValue, largeValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
  }

  @(Type.stringof ~ " 45 not between 40 and 50 reports error with expected and actual")
  unittest {
    Type smallValue = cast(Type) 40;
    Type largeValue = cast(Type) 50;
    Type middleValue = cast(Type) 45;

    auto evaluation = ({
      expect(middleValue).to.not.be.between(smallValue, largeValue);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    expect(evaluation.result.actual[]).to.equal(middleValue.to!string);
    expect(evaluation.result.negated).to.equal(true);
  }
}

@("Duration value is inside an interval")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  Duration middleValue = 45.seconds;
  expect(middleValue).to.be.between(smallValue, largeValue);
  expect(middleValue).to.be.between(largeValue, smallValue);
  expect(middleValue).to.be.within(smallValue, largeValue);
}

@("Duration value is outside an interval")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  expect(largeValue).to.not.be.between(smallValue, largeValue);
  expect(largeValue).to.not.be.between(largeValue, smallValue);
  expect(largeValue).to.not.be.within(smallValue, largeValue);
}

@("Duration 50s between 40s and 50s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;

  auto evaluation = ({
    expect(largeValue).to.be.between(smallValue, largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
  expect(evaluation.result.actual[]).to.equal(largeValue.to!string);
}

@("Duration 40s between 40s and 50s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;

  auto evaluation = ({
    expect(smallValue).to.be.between(smallValue, largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
  expect(evaluation.result.actual[]).to.equal(smallValue.to!string);
}

@("Duration 45s not between 40s and 50s reports error with expected and actual")
unittest {
  Duration smallValue = 40.seconds;
  Duration largeValue = 50.seconds;
  Duration middleValue = 45.seconds;

  auto evaluation = ({
    expect(middleValue).to.not.be.between(smallValue, largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
  expect(evaluation.result.actual[]).to.equal(middleValue.to!string);
  expect(evaluation.result.negated).to.equal(true);
}

@("SysTime value is inside an interval")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  SysTime middleValue = Clock.currTime + 35.seconds;
  expect(middleValue).to.be.between(smallValue, largeValue);
  expect(middleValue).to.be.between(largeValue, smallValue);
  expect(middleValue).to.be.within(smallValue, largeValue);
}

@("SysTime value is outside an interval")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  expect(largeValue).to.not.be.between(smallValue, largeValue);
  expect(largeValue).to.not.be.between(largeValue, smallValue);
  expect(largeValue).to.not.be.within(smallValue, largeValue);
}

@("SysTime larger between smaller and larger reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;

  auto evaluation = ({
    expect(largeValue).to.be.between(smallValue, largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("a value inside (" ~ smallValue.toISOExtString ~ ", " ~ largeValue.toISOExtString ~ ") interval");
  expect(evaluation.result.actual[]).to.equal(largeValue.toISOExtString);
}

@("SysTime smaller between smaller and larger reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;

  auto evaluation = ({
    expect(smallValue).to.be.between(smallValue, largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("a value inside (" ~ smallValue.toISOExtString ~ ", " ~ largeValue.toISOExtString ~ ") interval");
  expect(evaluation.result.actual[]).to.equal(smallValue.toISOExtString);
}

@("SysTime middle not between smaller and larger reports error with expected and actual")
unittest {
  SysTime smallValue = Clock.currTime;
  SysTime largeValue = Clock.currTime + 40.seconds;
  SysTime middleValue = Clock.currTime + 35.seconds;

  auto evaluation = ({
    expect(middleValue).to.not.be.between(smallValue, largeValue);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("a value outside (" ~ smallValue.toISOExtString ~ ", " ~ largeValue.toISOExtString ~ ") interval");
  expect(evaluation.result.actual[]).to.equal(middleValue.toISOExtString);
  expect(evaluation.result.negated).to.equal(true);
}
