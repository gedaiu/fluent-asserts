module fluentasserts.core.operations.beNull;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import std.algorithm;

static immutable beNullDescription = "Asserts that the value is null.";

///
IResult[] beNull(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  auto result = evaluation.currentValue.typeNames.canFind("null") || evaluation.currentValue.strValue == "null";

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  IResult[] results = [];

  try results ~= new ExpectedActualResult(
    evaluation.isNegated ? "not null" : "null",
    evaluation.currentValue.typeNames.length ? evaluation.currentValue.typeNames[0] : "unknown");
  catch(Exception) {}

  return results;
}
