module fluentasserts.core.operations.endWith;

import std.string;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;
import fluentasserts.core.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable endWithDescription = "Tests that the tested string ends with the expected value.";

///
IResult[] endWith(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  IResult[] results = [];
  auto current = evaluation.currentValue.strValue.cleanString;
  auto expected = evaluation.expectedValue.strValue.cleanString;

  long index = -1;

  try {
    index = current.lastIndexOf(expected);
  } catch(Exception) { }

  auto doesEndWith = index >= 0 && index == current.length - expected.length;

  if(evaluation.isNegated) {
    if(doesEndWith) {
      evaluation.message.addText(" ");
      evaluation.message.addValue(evaluation.currentValue.strValue);
      evaluation.message.addText(" ends with ");
      evaluation.message.addValue(evaluation.expectedValue.strValue);
      evaluation.message.addText(".");

      try results ~= new ExpectedActualResult("to not end with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  } else {
    if(!doesEndWith) {
      evaluation.message.addText(" ");
      evaluation.message.addValue(evaluation.currentValue.strValue);
      evaluation.message.addText(" does not end with ");
      evaluation.message.addValue(evaluation.expectedValue.strValue);
      evaluation.message.addText(".");

      try results ~= new ExpectedActualResult("to end with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  }

  return results;
}
