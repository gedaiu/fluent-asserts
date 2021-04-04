module fluentasserts.core.operations.between;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

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

  return betweenResults(currentValue, limit1, limit2, evaluation);
}


///
IResult[] betweenDuration(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(" and ");

  Duration currentValue;
  Duration limit1;
  Duration limit2;

  try {
    currentValue = dur!"nsecs"(evaluation.currentValue.strValue.to!size_t);
    limit1 = dur!"nsecs"(evaluation.expectedValue.strValue.to!size_t);
    limit2 = dur!"nsecs"(evaluation.expectedValue.meta["1"].to!size_t);

    evaluation.message.addValue(limit2.to!string);
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to Duration") ];
  }

  evaluation.message.addText(". ");

  return betweenResults(currentValue, limit1, limit2, evaluation);
}

///
IResult[] betweenSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(" and ");

  SysTime currentValue;
  SysTime limit1;
  SysTime limit2;

  try {
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
    limit1 = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    limit2 = SysTime.fromISOExtString(evaluation.expectedValue.meta["1"]);

    evaluation.message.addValue(limit2.toISOExtString);
  } catch(Exception e) {
    return [ new MessageResult("Can't convert the values to Duration") ];
  }

  evaluation.message.addText(". ");

  return betweenResults(currentValue, limit1, limit2, evaluation);
}

private IResult[] betweenResults(T)(T currentValue, T limit1, T limit2, ref Evaluation evaluation) {
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
      evaluation.message.addValue(evaluation.currentValue.niceValue);

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

      results ~= new ExpectedActualResult(interval, evaluation.currentValue.niceValue);
    }
  } else if(isBetween) {
    results ~= new ExpectedActualResult(interval, evaluation.currentValue.niceValue);
  }

  return results;
}
