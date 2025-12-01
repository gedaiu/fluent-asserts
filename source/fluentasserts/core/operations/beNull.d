module fluentasserts.core.operations.beNull;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import std.algorithm;

static immutable beNullDescription = "Asserts that the value is null.";

///
IResult[] beNull(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  auto result = evaluation.currentValue.typeNames.canFind("null") || evaluation.currentValue.strValue == "null";

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  evaluation.result.expected = "null";
  evaluation.result.actual = evaluation.currentValue.typeNames.length ? evaluation.currentValue.typeNames[0] : "unknown";
  evaluation.result.negated = evaluation.isNegated;

  return [];
}
