module fluentasserts.core.operations.approximately;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;
import fluentasserts.core.array;
import fluentasserts.core.serializers;
import fluentasserts.core.operations.contain;

import fluentasserts.core.lifecycle;

import std.algorithm;
import std.array;
import std.conv;
import std.math;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable approximatelyDescription = "Asserts that the target is a number that's within a given +/- `delta` range of the given number expected. However, it's often best to assert that the target is equal to its expected value.";

///
IResult[] approximately(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results = [];

  evaluation.result.addValue("±");
  evaluation.result.addValue(evaluation.expectedValue.meta["1"]);
  evaluation.result.addText(".");

  real current;
  real expected;
  real delta;

  try {
    current = evaluation.currentValue.strValue.to!real;
    expected = evaluation.expectedValue.strValue.to!real;
    delta = evaluation.expectedValue.meta["1"].to!real;
  } catch(Exception e) {
    results ~= new MessageResult("Can't parse the provided arguments!");

    return results;
  }

  string strExpected = evaluation.expectedValue.strValue ~ "±" ~ evaluation.expectedValue.meta["1"];
  string strCurrent = evaluation.currentValue.strValue;

  auto result = isClose(current, expected, 0, delta);

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return [];
  }

  if(evaluation.currentValue.typeName != "bool") {
    evaluation.result.addText(" ");
    evaluation.result.addValue(strCurrent);

    if(evaluation.isNegated) {
      evaluation.result.addText(" is approximately ");
    } else {
      evaluation.result.addText(" is not approximately ");
    }

    evaluation.result.addValue(strExpected);
    evaluation.result.addText(".");
  }

  evaluation.result.expected = strExpected;
  evaluation.result.actual = strCurrent;
  evaluation.result.negated = evaluation.isNegated;

  return [];
}

///
IResult[] approximatelyList(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addValue("±" ~ evaluation.expectedValue.meta["1"]);
  evaluation.result.addText(".");

  double maxRelDiff;
  real[] testData;
  real[] expectedPieces;

  try {
    testData = evaluation.currentValue.strValue.parseList.cleanString.map!(a => a.to!real).array;
    expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString.map!(a => a.to!real).array;
    maxRelDiff = evaluation.expectedValue.meta["1"].to!double;
  } catch(Exception e) {
    return [ new MessageResult("Can not perform the assert.") ];
  }

  auto comparison = ListComparison!real(testData, expectedPieces, maxRelDiff);

  auto missing = comparison.missing;
  auto extra = comparison.extra;
  auto common = comparison.common;

  IResult[] results = [];

  bool allEqual = testData.length == expectedPieces.length;

  if(allEqual) {
    foreach(i; 0..testData.length) {
      allEqual = allEqual && isClose(testData[i], expectedPieces[i], 0, maxRelDiff) && true;
    }
  }

  string strExpected;
  string strMissing;

  if(maxRelDiff == 0) {
    strExpected = evaluation.expectedValue.strValue;
    try strMissing = missing.length == 0 ? "" : missing.to!string;
    catch(Exception) {}
  } else try {
    strMissing = "[" ~ missing.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ") ~ "]";
    strExpected = "[" ~ expectedPieces.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ") ~ "]";
  } catch(Exception) {}

  if(!evaluation.isNegated) {
    if(!allEqual) {
      evaluation.result.expected = strExpected;
      evaluation.result.actual = evaluation.currentValue.strValue;

      if(extra.length > 0) {
        try {
          foreach(e; extra) {
            evaluation.result.extra ~= e.to!string ~ "±" ~ maxRelDiff.to!string;
          }
        } catch(Exception) {}
      }

      if(missing.length > 0) {
        try {
          foreach(m; missing) {
            evaluation.result.missing ~= m.to!string ~ "±" ~ maxRelDiff.to!string;
          }
        } catch(Exception) {}
      }
    }
  } else {
    if(allEqual) {
      evaluation.result.expected = strExpected;
      evaluation.result.actual = evaluation.currentValue.strValue;
      evaluation.result.negated = true;
    }
  }

  return [];
}
