module fluentasserts.operations.equality.equal;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import fluentasserts.results.message;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable equalDescription = "Asserts that the target is strictly == equal to the given val.";

static immutable isEqualTo = Message(Message.Type.info, " is equal to ");
static immutable isNotEqualTo = Message(Message.Type.info, " is not equal to ");
static immutable endSentence = Message(Message.Type.info, ". ");

///
void equal(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.add(endSentence);

  bool isEqual = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;

  if(!isEqual && evaluation.currentValue.proxyValue !is null && evaluation.expectedValue.proxyValue !is null) {
    isEqual = evaluation.currentValue.proxyValue.isEqualTo(evaluation.expectedValue.proxyValue);
  }

  if(evaluation.isNegated) {
    isEqual = !isEqual;
  }

  if(isEqual) {
    return;
  }

  evaluation.result.expected = evaluation.expectedValue.strValue;
  evaluation.result.actual = evaluation.currentValue.strValue;
  evaluation.result.negated = evaluation.isNegated;

  if(evaluation.currentValue.typeName != "bool") {
    evaluation.result.add(Message(Message.Type.value, evaluation.currentValue.strValue));

    if(evaluation.isNegated) {
      evaluation.result.add(isEqualTo);
    } else {
      evaluation.result.add(isNotEqualTo);
    }

    evaluation.result.add(Message(Message.Type.value, evaluation.expectedValue.strValue));
    evaluation.result.add(endSentence);

    evaluation.result.computeDiff(evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  }
}
