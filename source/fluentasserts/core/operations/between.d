module fluentasserts.core.operations.between;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] between(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(" and ");
  evaluation.message.addValue(evaluation.expectedValue.meta["1"]);
  evaluation.message.addText(". ");

  T currentValue;
  T limit1;
  T limit2;

  try {
    currentValue = evaluation.currentValue.strValue.to!T;
    limit1 = evaluation.expectedValue.strValue.to!T;
    limit2 = evaluation.expectedValue.meta["1"].to!T;
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to " ~ T.stringof) ];
  }

  T min = limit1 < limit2 ? limit1 : limit2;
  T max = limit1 > limit2 ? limit1 : limit2;

  auto isLess = currentValue <= min;
  auto isGreater = currentValue >= max;
  auto isBetween = !isLess && !isGreater;

  string interval;

  try {
    interval = "a value " ~ (evaluation.isNegated ? "outside" : "inside") ~ " (" ~ min.to!string ~ ", " ~ max.to!string ~ ") interval";
  } catch(Exception) {
    interval = "a value " ~ (evaluation.isNegated ? "outside" : "inside") ~ " the interval";
  }

  IResult[] results = [];

  if(!evaluation.isNegated) {
    if(!isBetween) {
      evaluation.message.addValue(evaluation.currentValue.strValue);

      if(isGreater) {
        evaluation.message.addText(" is greater than or equal to ");
        try evaluation.message.addValue(max.to!string);
        catch(Exception) {}
      }

      if(isLess) {
        evaluation.message.addText(" is less than or equal to ");
        try evaluation.message.addValue(min.to!string);
        catch(Exception) {}
      }

      evaluation.message.addText(".");

      results ~= new ExpectedActualResult(interval, evaluation.currentValue.strValue);
    }
  } else if(isBetween) {
    results ~= new ExpectedActualResult(interval, evaluation.currentValue.strValue);
  }



  return results;
}
