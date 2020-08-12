module fluentasserts.core.operations.greaterThan;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] greaterThan(T)(ref Evaluation evaluation) @safe nothrow {
  Lifecycle.instance.addText(".");

  T expectedValue;
  T currentValue;

  try {
    expectedValue = evaluation.expectedValue.strValue.to!T;
    currentValue = evaluation.currentValue.strValue.to!T;
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to " ~ T.stringof) ];
  }

  auto result = currentValue > expectedValue;

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  Lifecycle.instance.addText(" ");
  Lifecycle.instance.addValue(evaluation.currentValue.strValue);

  IResult[] results = [];

  if(evaluation.isNegated) {
    Lifecycle.instance.addText(" is greater than ");
    results ~= new ExpectedActualResult("less than or equal to " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  } else {
    Lifecycle.instance.addText(" is less than or equal to ");
    results ~= new ExpectedActualResult("greater than " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  }


  Lifecycle.instance.addValue(evaluation.expectedValue.strValue);
  Lifecycle.instance.addText(".");


  return results;
}
