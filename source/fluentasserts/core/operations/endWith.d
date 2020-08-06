module fluentasserts.core.operations.endWith;

import std.string;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;
import fluentasserts.core.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] endWith(ref Evaluation evaluation) @safe nothrow {
  IResult[] results = [];
  auto current = evaluation.currentValue.strValue.cleanString;
  auto expected = evaluation.expectedValue.strValue.cleanString;

  auto index = current.indexOf(expected);
  auto doesEndWith = index >= 0 && index == current.length - expected.length;

  if(evaluation.isNegated) {
    if(doesEndWith) {
      Lifecycle.instance.addText(" ");
      Lifecycle.instance.addValue(evaluation.currentValue.strValue);
      Lifecycle.instance.addText(" ends with ");
      Lifecycle.instance.addValue(evaluation.expectedValue.strValue);
      Lifecycle.instance.addText(".");

      try results ~= new ExpectedActualResult("to not end with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  } else {
    if(!doesEndWith) {
      Lifecycle.instance.addText(" ");
      Lifecycle.instance.addValue(evaluation.currentValue.strValue);
      Lifecycle.instance.addText(" does not end with ");
      Lifecycle.instance.addValue(evaluation.expectedValue.strValue);
      Lifecycle.instance.addText(".");

      try results ~= new ExpectedActualResult("to end with " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
      catch(Exception e) {}
    }
  }

  return results;
}
