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
  Lifecycle.instance.addText(".");

  IResult[] results = [];

  auto index = evaluation.currentValue.strValue.cleanString.indexOf(evaluation.expectedValue.strValue.cleanString);
  auto doesStartWith = index == 0;

  if(evaluation.isNegated) {
    if(doesStartWith) {
      Lifecycle.instance.addText(" ");
      Lifecycle.instance.addValue(evaluation.currentValue.strValue);
      Lifecycle.instance.addText(" starts with ");
      Lifecycle.instance.addValue(evaluation.expectedValue.strValue);
      Lifecycle.instance.addText(".");

      try results ~= new ExpectedActualResult("to not start with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  } else {
    if(!doesStartWith) {
      Lifecycle.instance.addText(" ");
      Lifecycle.instance.addValue(evaluation.currentValue.strValue);
      Lifecycle.instance.addText(" does not start with ");
      Lifecycle.instance.addValue(evaluation.expectedValue.strValue);
      Lifecycle.instance.addText(".");

      try results ~= new ExpectedActualResult("to start with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  }

  return results;
}
