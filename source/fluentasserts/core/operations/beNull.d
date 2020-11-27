module fluentasserts.core.operations.beNull;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

///
IResult[] beNull(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  auto result = evaluation.currentValue.typeName == "null";

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  IResult[] results = [];

  try results ~= new ExpectedActualResult((evaluation.isNegated ? "not null" : "null"), evaluation.currentValue.typeName); catch(Exception) {}

  return results;
}
