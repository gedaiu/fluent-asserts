module fluentasserts.core.operations.instanceOf;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;
import std.algorithm;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable instanceOfDescription = "Asserts that the tested value is related to a type.";

///
void instanceOf(ref Evaluation evaluation) @safe nothrow {
  string expectedType = evaluation.expectedValue.strValue[1 .. $-1];
  string currentType = evaluation.currentValue.typeNames[0];

  evaluation.result.addText(". ");

  auto existingTypes = findAmong(evaluation.currentValue.typeNames, [expectedType]);

  auto isExpected = existingTypes.length > 0;

  if(evaluation.isNegated) {
    isExpected = !isExpected;
  }

  if(isExpected) {
    return;
  }

  evaluation.result.addValue(evaluation.currentValue.strValue);
  evaluation.result.addText(" is instance of ");
  evaluation.result.addValue(currentType);
  evaluation.result.addText(".");

  evaluation.result.expected = "typeof " ~ expectedType;
  evaluation.result.actual = "typeof " ~ currentType;
  evaluation.result.negated = evaluation.isNegated;
}