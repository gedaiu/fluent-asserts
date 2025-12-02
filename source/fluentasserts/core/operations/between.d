module fluentasserts.core.operations.between;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable betweenDescription = "Asserts that the target is a number or a date greater than or equal to the given number or date start, " ~
  "and less than or equal to the given number or date finish respectively. However, it's often best to assert that the target is equal to its expected value.";

///
void between(T)(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");
  evaluation.result.addValue(evaluation.expectedValue.meta["1"]);
  evaluation.result.addText(". ");

  T currentValue;
  T limit1;
  T limit2;

  try {
    currentValue = evaluation.currentValue.strValue.to!T;
    limit1 = evaluation.expectedValue.strValue.to!T;
    limit2 = evaluation.expectedValue.meta["1"].to!T;
  } catch(Exception e) {
    evaluation.result.expected = "valid " ~ T.stringof ~ " values";
    evaluation.result.actual = "conversion error";
    return;
  }

  betweenResults(currentValue, limit1, limit2, evaluation);
}


///
void betweenDuration(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");

  Duration currentValue;
  Duration limit1;
  Duration limit2;

  try {
    currentValue = dur!"nsecs"(evaluation.currentValue.strValue.to!size_t);
    limit1 = dur!"nsecs"(evaluation.expectedValue.strValue.to!size_t);
    limit2 = dur!"nsecs"(evaluation.expectedValue.meta["1"].to!size_t);

    evaluation.result.addValue(limit2.to!string);
  } catch(Exception e) {
    evaluation.result.expected = "valid Duration values";
    evaluation.result.actual = "conversion error";
    return;
  }

  evaluation.result.addText(". ");

  betweenResults(currentValue, limit1, limit2, evaluation);
}

///
void betweenSysTime(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(" and ");

  SysTime currentValue;
  SysTime limit1;
  SysTime limit2;

  try {
    currentValue = SysTime.fromISOExtString(evaluation.currentValue.strValue);
    limit1 = SysTime.fromISOExtString(evaluation.expectedValue.strValue);
    limit2 = SysTime.fromISOExtString(evaluation.expectedValue.meta["1"]);

    evaluation.result.addValue(limit2.toISOExtString);
  } catch(Exception e) {
    evaluation.result.expected = "valid SysTime values";
    evaluation.result.actual = "conversion error";
    return;
  }

  evaluation.result.addText(". ");

  betweenResults(currentValue, limit1, limit2, evaluation);
}

private void betweenResults(T)(T currentValue, T limit1, T limit2, ref Evaluation evaluation) {
  T min = limit1 < limit2 ? limit1 : limit2;
  T max = limit1 > limit2 ? limit1 : limit2;

  auto isLess = currentValue <= min;
  auto isGreater = currentValue >= max;
  auto isBetween = !isLess && !isGreater;

  string interval;

  try {
    if (evaluation.isNegated) {
      interval = "a value outside (" ~ min.to!string ~ ", " ~ max.to!string ~ ") interval";
    } else {
      interval = "a value inside (" ~ min.to!string ~ ", " ~ max.to!string ~ ") interval";
    }
  } catch(Exception) {
    interval = evaluation.isNegated ? "a value outside the interval" : "a value inside the interval";
  }

  if(!evaluation.isNegated) {
    if(!isBetween) {
      evaluation.result.addValue(evaluation.currentValue.niceValue);

      if(isGreater) {
        evaluation.result.addText(" is greater than or equal to ");
        try evaluation.result.addValue(max.to!string);
        catch(Exception) {}
      }

      if(isLess) {
        evaluation.result.addText(" is less than or equal to ");
        try evaluation.result.addValue(min.to!string);
        catch(Exception) {}
      }

      evaluation.result.addText(".");

      evaluation.result.expected = interval;
      evaluation.result.actual = evaluation.currentValue.niceValue;
    }
  } else if(isBetween) {
    evaluation.result.expected = interval;
    evaluation.result.actual = evaluation.currentValue.niceValue;
  }
}
