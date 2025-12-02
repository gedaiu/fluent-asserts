module fluentasserts.operations.string.endWith;

import std.string;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.results.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable endWithDescription = "Tests that the tested string ends with the expected value.";

///
void endWith(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  auto current = evaluation.currentValue.strValue.cleanString;
  auto expected = evaluation.expectedValue.strValue.cleanString;

  long index = -1;

  try {
    index = current.lastIndexOf(expected);
  } catch(Exception) { }

  auto doesEndWith = index >= 0 && index == current.length - expected.length;

  if(evaluation.isNegated) {
    if(doesEndWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" ends with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to end with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
      evaluation.result.negated = true;
    }
  } else {
    if(!doesEndWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" does not end with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to end with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
    }
  }
}
