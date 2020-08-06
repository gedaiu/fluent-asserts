module fluentasserts.core.operations.contain;

import std.algorithm;
import std.array;
import std.conv;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;
import fluentasserts.core.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] contain(ref Evaluation evaluation) @safe nothrow {
  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString;
  auto testData = evaluation.currentValue.strValue.cleanString;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => !testData.canFind(a)).array;

    if(missingValues.length > 0) {
      string message = "to contain ";

      if(expectedPieces.length > 1) {
        message ~= "all ";
      }

      message ~= evaluation.expectedValue.strValue;

      if(missingValues.length == 1) {
        Lifecycle.instance.addText(" ");
        try Lifecycle.instance.addValue(missingValues[0]); catch(Exception e) {
          Lifecycle.instance.addText(" some value ");
        }

        Lifecycle.instance.addText(" is missing from ");
      } else {
        Lifecycle.instance.addText(" ");
        try Lifecycle.instance.addValue(missingValues.to!string); catch(Exception e) {
          Lifecycle.instance.addText(" some values ");
        }

        Lifecycle.instance.addText(" are missing from ");
      }

      Lifecycle.instance.addValue(evaluation.currentValue.strValue);
      Lifecycle.instance.addText(".");

      try results ~= new ExpectedActualResult(message, testData);
      catch(Exception) {}
    }
  } else {
    auto presentValues = expectedPieces.filter!(a => testData.canFind(a)).array;

    if(presentValues.length > 0) {
      string message = "to not contain ";

      if(presentValues.length > 1) {
        message ~= "any ";
      }

      message ~= evaluation.expectedValue.strValue;

      Lifecycle.instance.addText(" ");

      if(presentValues.length == 1) {
        try Lifecycle.instance.addValue(presentValues[0]); catch(Exception e) {
          Lifecycle.instance.addText(" some value ");
        }

        Lifecycle.instance.addText(" is present in ");
      } else {
        try Lifecycle.instance.addValue(presentValues.to!string); catch(Exception e) {
          Lifecycle.instance.addText(" some values ");
        }

        Lifecycle.instance.addText(" are present in ");
      }

      Lifecycle.instance.addValue(evaluation.currentValue.strValue);
      Lifecycle.instance.addText(".");

      try results ~= new ExpectedActualResult(message, testData);
      catch(Exception) {}
    }
  }

  return results;
}
