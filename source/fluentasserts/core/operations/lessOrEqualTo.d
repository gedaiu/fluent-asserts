module fluentasserts.core.operations.lessOrEqualTo;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] lessOrEqualTo(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  T expectedValue;
  T currentValue;

  try {
    expectedValue = evaluation.expectedValue.strValue.to!T;
    currentValue = evaluation.currentValue.strValue.to!T;
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to " ~ T.stringof) ];
  }

  auto result = currentValue <= expectedValue;

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  evaluation.message.addText(" ");
  evaluation.message.addValue(evaluation.currentValue.niceValue);

  IResult[] results = [];

  if(evaluation.isNegated) {
    evaluation.message.addText(" is less or equal to ");
    results ~= new ExpectedActualResult("greater than " ~ evaluation.expectedValue.niceValue, evaluation.currentValue.niceValue);
  } else {
    evaluation.message.addText(" is greater than ");
    results ~= new ExpectedActualResult("less or equal to " ~ evaluation.expectedValue.niceValue, evaluation.currentValue.niceValue);
  }

  evaluation.message.addValue(evaluation.expectedValue.niceValue);
  evaluation.message.addText(".");

  return results;
}
