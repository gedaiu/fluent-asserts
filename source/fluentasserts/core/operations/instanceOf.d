module fluentasserts.core.operations.instanceOf;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;
import std.algorithm;

version(unittest) {
  import fluentasserts.core.expect;
}

static immutable instanceOfDescription = "Asserts that the tested value is related to a type.";

///
IResult[] instanceOf(ref Evaluation evaluation) @safe nothrow {
  string expectedType = evaluation.expectedValue.strValue[1 .. $-1];
  string currentType = evaluation.currentValue.typeNames[0];

  evaluation.message.addText(". ");

  auto existingTypes = findAmong(evaluation.currentValue.typeNames, [expectedType]);

  import std.stdio;

  auto isExpected = existingTypes.length > 0;

  if(evaluation.isNegated) {
    isExpected = !isExpected;
  }

  IResult[] results = [];

  if(!isExpected) {
    evaluation.message.addValue(evaluation.currentValue.strValue);
    evaluation.message.addText(" is instance of ");
    evaluation.message.addValue(currentType);
    evaluation.message.addText(".");
  }

  if(!isExpected && !evaluation.isNegated) {
    try results ~= new ExpectedActualResult("typeof " ~ expectedType, "typeof " ~ currentType); catch(Exception) {}
  }

  if(!isExpected && evaluation.isNegated) {
    try results ~= new ExpectedActualResult("not typeof " ~ expectedType, "typeof " ~ currentType); catch(Exception) {}
  }

  return results;
}