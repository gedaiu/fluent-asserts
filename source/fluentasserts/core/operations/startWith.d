module fluentasserts.core.operations.startWith;

import std.string;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;
import fluentasserts.core.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] startWith(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  IResult[] results = [];

  auto index = evaluation.currentValue.strValue.cleanString.indexOf(evaluation.expectedValue.strValue.cleanString);
  auto doesStartWith = index == 0;

  if(evaluation.isNegated) {
    if(doesStartWith) {
      evaluation.message.addText(" ");
      evaluation.message.addValue(evaluation.currentValue.strValue);
      evaluation.message.addText(" starts with ");
      evaluation.message.addValue(evaluation.expectedValue.strValue);
      evaluation.message.addText(".");

      try results ~= new ExpectedActualResult("to not start with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  } else {
    if(!doesStartWith) {
      evaluation.message.addText(" ");
      evaluation.message.addValue(evaluation.currentValue.strValue);
      evaluation.message.addText(" does not start with ");
      evaluation.message.addValue(evaluation.expectedValue.strValue);
      evaluation.message.addText(".");

      try results ~= new ExpectedActualResult("to start with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  }

  return results;
}
