module fluentasserts.core.operations.greaterOrEqualTo;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

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

  return greaterOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

IResult[] greaterOrEqualToDuration(ref Evaluation evaluation) @safe nothrow {
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

  auto result = currentValue >= expectedValue;

  return greaterOrEqualToResults(result, niceExpectedValue, niceCurrentValue, evaluation);
}

IResult[] greaterOrEqualToSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  SysTime expectedValue;
  SysTime currentValue;
  string niceExpectedValue;
  string niceCurrentValue;

  try {
    expectedValue = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to SysTime") ];
  }

  auto result = currentValue >= expectedValue;

  return greaterOrEqualToResults(result, evaluation.expectedValue.strValue, evaluation.currentValue.strValue, evaluation);
}

private IResult[] greaterOrEqualToResults(bool result, string niceExpectedValue, string niceCurrentValue, ref Evaluation evaluation) @safe nothrow {
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
    evaluation.message.addText(" is greater or equal than ");
    results ~= new ExpectedActualResult("less than " ~ niceExpectedValue, niceCurrentValue);
  } else {
    evaluation.message.addText(" is less than ");
    results ~= new ExpectedActualResult("greater or equal than " ~ niceExpectedValue, niceCurrentValue);
  }

  evaluation.message.addValue(niceExpectedValue);
  evaluation.message.addText(".");

  return results;
}
