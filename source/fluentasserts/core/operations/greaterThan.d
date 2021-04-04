module fluentasserts.core.operations.greaterThan;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] greaterThan(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

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

  evaluation.message.addText(" ");
  evaluation.message.addValue(evaluation.currentValue.strValue);

  IResult[] results = [];

  if(evaluation.isNegated) {
    evaluation.message.addText(" is greater than ");
    results ~= new ExpectedActualResult("less than or equal to " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  } else {
    evaluation.message.addText(" is less than or equal to ");
    results ~= new ExpectedActualResult("greater than " ~ evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  }


  evaluation.message.addValue(evaluation.expectedValue.strValue);
  evaluation.message.addText(".");


  return results;
}


IResult[] greaterThanDuration(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  Duration expectedValue;
  Duration currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = dur!"nsecs"(evaluation.expectedValue.strValue.to!size_t);
    currentValue = dur!"nsecs"(evaluation.currentValue.strValue.to!size_t);

    niceExpectedValue = expectedValue.to!string;
    niceCurrentValue = currentValue.to!string;
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to Duration") ];
  }

  auto result = currentValue > expectedValue;

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
    evaluation.message.addText(" is greater than ");
    results ~= new ExpectedActualResult("less than or equal to " ~ niceExpectedValue, niceCurrentValue);
  } else {
    evaluation.message.addText(" is less than or equal to ");
    results ~= new ExpectedActualResult("greater than " ~ niceExpectedValue, niceCurrentValue);
  }

  evaluation.message.addValue(niceExpectedValue);
  evaluation.message.addText(".");

  return results;
}