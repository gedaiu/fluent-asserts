module fluentasserts.core.operations.arrayEqual;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable arrayEqualDescription = "Asserts that the target is strictly == equal to the given val.";

///
IResult[] arrayEqual(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");
  bool result = true;

  EquableValue[] expectedPieces = evaluation.expectedValue.proxyValue.toArray;
  EquableValue[] testData = evaluation.currentValue.proxyValue.toArray;

  if(testData.length == expectedPieces.length) {
    foreach(index, testedValue; testData) {
      if(testedValue !is null && !testedValue.isEqualTo(expectedPieces[index])) {
        result = false;
        break;
      }
    }
  } else {
    result = false;
  }

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
