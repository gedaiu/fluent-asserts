module fluentasserts.core.operations.equal;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import fluentasserts.core.message;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable equalDescription = "Asserts that the target is strictly == equal to the given val.";

static immutable isEqualTo = Message(Message.Type.info, " is equal to ");
static immutable isNotEqualTo = Message(Message.Type.info, " is not equal to ");
static immutable endSentence = Message(Message.Type.info, ". ");

///
IResult[] equal(ref Evaluation evaluation) @safe nothrow {
  EvaluationResult evaluationResult;

  evaluation.message.add(endSentence);

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
    evaluation.message.add(Message(Message.Type.value, evaluation.currentValue.strValue));

    if(evaluation.isNegated) {
      evaluation.message.add(isEqualTo);
    } else {
      evaluation.message.add(isNotEqualTo);
    }

    evaluation.message.add(Message(Message.Type.value, evaluation.expectedValue.strValue));
    evaluation.message.add(endSentence);

    evaluationResult.addDiff(evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
    try results ~= new DiffResult(evaluation.expectedValue.strValue, evaluation.currentValue.strValue); catch(Exception) {}
  }

  evaluationResult.addExpected(evaluation.isNegated, evaluation.expectedValue.strValue);
  evaluationResult.addResult(evaluation.currentValue.strValue);

  return evaluationResult.toException;
}
