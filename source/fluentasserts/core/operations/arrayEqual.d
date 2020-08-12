module fluentasserts.core.operations.arrayEqual;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] arrayEqual(ref Evaluation evaluation) @safe nothrow {
  Lifecycle.instance.addText(".");

  auto result = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  IResult[] results = [];

  if(evaluation.isNegated) {
    try results ~= new ExpectedActualResult("not " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}
  } else {
    try results ~= new DiffResult(evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}
    try results ~= new ExpectedActualResult(evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}
  }

  return results;
}
