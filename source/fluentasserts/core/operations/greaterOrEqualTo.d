module fluentasserts.core.operations.greaterOrEqualTo;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] greaterOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  T expectedValue;
  T currentValue;

  try {
    expectedValue = evaluation.expectedValue.strValue.to!T;
    currentValue = evaluation.currentValue.strValue.to!T;
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to " ~ T.stringof) ];
  }

  auto result = currentValue >= expectedValue;

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  evaluation.message.addText(" ");
  evaluation.message.addValue(evaluation.currentValue.strValue);

  IResult[] results = [];

  if(evaluation.isNegated) {
    evaluation.message.addText(" is greater or equal than ");
    results ~= new ExpectedActualResult("less than " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  } else {
    evaluation.message.addText(" is less than ");
    results ~= new ExpectedActualResult("greater or equal than " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  }

  evaluation.message.addValue(evaluation.expectedValue.strValue);
  evaluation.message.addText(".");

  return results;
}
