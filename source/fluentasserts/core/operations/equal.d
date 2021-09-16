module fluentasserts.core.operations.equal;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] equal(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  bool result = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;

  if(!result && evaluation.currentValue.proxyValue !is null && evaluation.expectedValue.proxyValue !is null) {
    result = evaluation.currentValue.proxyValue.isEqualTo(evaluation.expectedValue.proxyValue);
  }

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  IResult[] results = [];

  if(evaluation.currentValue.typeName != "bool") {
    evaluation.message.addText(" ");
    evaluation.message.addValue(evaluation.currentValue.strValue);

    if(evaluation.isNegated) {
      evaluation.message.addText(" is equal to ");
    } else {
      evaluation.message.addText(" is not equal to ");
    }

    evaluation.message.addValue(evaluation.expectedValue.strValue);
    evaluation.message.addText(".");

    try results ~= new DiffResult(evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}
  }

  try results ~= new ExpectedActualResult((evaluation.isNegated ? "not " : "") ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}

  return results;
}
