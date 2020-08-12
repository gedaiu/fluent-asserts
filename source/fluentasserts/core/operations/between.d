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
  Lifecycle.instance.addText(" and ");
  Lifecycle.instance.addValue(evaluation.expectedValue.meta["1"]);
  Lifecycle.instance.addText(". ");

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
      Lifecycle.instance.addValue(evaluation.currentValue.strValue);

      if(isGreater) {
        Lifecycle.instance.addText(" is greater than or equal to ");
        try Lifecycle.instance.addValue(max.to!string);
        catch(Exception) {}
      }

      if(isLess) {
        Lifecycle.instance.addText(" is less than or equal to ");
        try Lifecycle.instance.addValue(min.to!string);
        catch(Exception) {}
      }

      Lifecycle.instance.addText(".");

      results ~= new ExpectedActualResult(interval, evaluation.currentValue.strValue);
    }
  } else if(isBetween) {
    results ~= new ExpectedActualResult(interval, evaluation.currentValue.strValue);
  }



  return results;
}
