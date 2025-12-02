module fluentasserts.core.operations.greaterOrEqualTo;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable greaterOrEqualToDescription = "Asserts that the tested value is greater or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

///
void greaterOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  T expectedValue;
  T currentValue;

  try {
    expectedValue = evaluation.expectedValue.strValue.to!T;
    currentValue = evaluation.currentValue.strValue.to!T;
  } catch(Exception e) {
    evaluation.result.expected = "valid " ~ T.stringof ~ " values";
    evaluation.result.actual = "conversion error";
    return;
  }

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

void greaterOrEqualToDuration(ref Evaluation evaluation) @safe nothrow {
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
    evaluation.result.expected = "valid Duration values";
    evaluation.result.actual = "conversion error";
    return;
  }

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, niceExpectedValue, niceCurrentValue, evaluation);
}

void greaterOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  SysTime expectedValue;
  SysTime currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
  } catch(Exception e) {
    evaluation.result.expected = "valid SysTime values";
    evaluation.result.actual = "conversion error";
    return;
  }

  auto result = currentValue >= expectedValue;

  greaterOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private void greaterOrEqualToResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow {
  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.addText(" ");
  evaluation.result.addValue(evaluation.currentValue.niceValue);

  if(evaluation.isNegated) {
    evaluation.result.addText(" is greater or equal than ");
    evaluation.result.expected = "less than " ~ niceExpectedValue;
  } else {
    evaluation.result.addText(" is less than ");
    evaluation.result.expected = "greater or equal than " ~ niceExpectedValue;
  }

  evaluation.result.actual = niceCurrentValue;
  evaluation.result.negated = evaluation.isNegated;

  evaluation.result.addValue(niceExpectedValue);
  evaluation.result.addText(".");
}
