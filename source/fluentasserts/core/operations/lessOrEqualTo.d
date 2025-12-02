module fluentasserts.core.operations.lessOrEqualTo;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable lessOrEqualToDescription = "Asserts that the tested value is less or equal than the tested value. However, it's often best to assert that the target is equal to its expected value.";

///
void lessOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow {
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

  auto result = currentValue <= expectedValue;

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
    evaluation.result.expected = "greater than " ~ evaluation.expectedValue.niceValue;
  } else {
    evaluation.result.addText(" is greater than ");
    evaluation.result.expected = "less or equal to " ~ evaluation.expectedValue.niceValue;
  }

  evaluation.result.actual = evaluation.currentValue.niceValue;
  evaluation.result.negated = evaluation.isNegated;

  evaluation.result.addValue(evaluation.expectedValue.niceValue);
  evaluation.result.addText(".");
}
