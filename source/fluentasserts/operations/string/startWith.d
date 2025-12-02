module fluentasserts.operations.string.startWith;

import std.string;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.results.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable startWithDescription = "Tests that the tested string starts with the expected value.";

///
void startWith(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  auto index = evaluation.currentValue.strValue.cleanString.indexOf(evaluation.expectedValue.strValue.cleanString);
  auto doesStartWith = index == 0;

  if(evaluation.isNegated) {
    if(doesStartWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" starts with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to start with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
      evaluation.result.negated = true;
    }
  } else {
    if(!doesStartWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" does not start with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to start with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
    }
  }
}
