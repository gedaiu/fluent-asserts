module fluentasserts.core.operations.contain;

import std.algorithm;
import std.array;
import std.conv;

import fluentasserts.core.array;
import fluentasserts.core.results;
import fluentasserts.core.evaluation;
import fluentasserts.core.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluentasserts.core.expect;
}

///
IResult[] contain(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString;
  auto testData = evaluation.currentValue.strValue.cleanString;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => !testData.canFind(a)).array;

    if(missingValues.length > 0) {
      addLifecycleMessage(evaluation, missingValues);
      try results ~= new ExpectedActualResult(createResultMessage(evaluation.expectedValue, expectedPieces), testData);
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

      evaluation.message.addText(" ");

      if(presentValues.length == 1) {
        try evaluation.message.addValue(presentValues[0]); catch(Exception e) {
          evaluation.message.addText(" some value ");
        }

        evaluation.message.addText(" is present in ");
      } else {
        try evaluation.message.addValue(presentValues.to!string); catch(Exception e) {
          evaluation.message.addText(" some values ");
        }

        evaluation.message.addText(" are present in ");
      }

      evaluation.message.addValue(evaluation.currentValue.strValue);
      evaluation.message.addText(".");

      try results ~= new ExpectedActualResult(message, testData);
      catch(Exception) {}
    }
  }

  return results;
}

///
IResult[] arrayContain(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString;
  auto testData = evaluation.currentValue.strValue.parseList.cleanString;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => !testData.canFind(a)).array;

    if(missingValues.length > 0) {
      addLifecycleMessage(evaluation, missingValues);
      try results ~= new ExpectedActualResult(createResultMessage(evaluation.expectedValue, expectedPieces), evaluation.currentValue.strValue);
      catch(Exception) {}
    }
  } else {
    auto presentValues = expectedPieces.filter!(a => testData.canFind(a)).array;

    if(presentValues.length > 0) {
      addNegatedLifecycleMessage(evaluation, presentValues);
      try results ~= new ExpectedActualResult(createNegatedResultMessage(evaluation.expectedValue, expectedPieces), evaluation.currentValue.strValue);
      catch(Exception) {}
    }
  }

  return results;
}

///
IResult[] arrayContainOnly(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString;
  auto testData = evaluation.currentValue.strValue.parseList.cleanString;

  auto comparison = ListComparison!string(testData, expectedPieces);

  auto missing = comparison.missing;
  auto extra = comparison.extra;
  auto common = comparison.common;

  string strExtra = "";
  string strMissing = "";

  if(extra.length > 0) {
    strExtra = extra.niceJoin(evaluation.currentValue.typeName);
  }

  if(missing.length > 0) {
    strMissing = missing.niceJoin(evaluation.currentValue.typeName);
  }

  if(!evaluation.isNegated) {
    auto isSuccess = missing.length == 0 && extra.length == 0 && common.length == testData.length;

    if(!isSuccess) {
      try results ~= new ExpectedActualResult("", testData.niceJoin(evaluation.currentValue.typeName));
      catch(Exception) {}

      try results ~= new ExtraMissingResult(strExtra, strMissing);
      catch(Exception) {}
    }
  } else {
    auto isSuccess = (missing.length != 0 || extra.length != 0) || common.length != testData.length;

    if(!isSuccess) {
      try results ~= new ExpectedActualResult("to not contain " ~ expectedPieces.niceJoin(evaluation.currentValue.typeName), testData.niceJoin(evaluation.currentValue.typeName));
      catch(Exception) {}
    }
  }

  return results;
}

///
void addLifecycleMessage(ref Evaluation evaluation, string[] missingValues) @safe nothrow {
  evaluation.message.addText(" ");

  if(missingValues.length == 1) {
    try evaluation.message.addValue(missingValues[0]); catch(Exception e) {
      evaluation.message.addText(" some value ");
    }

    evaluation.message.addText(" is missing from ");
  } else {
    try {
      evaluation.message.addValue(missingValues.niceJoin(evaluation.currentValue.typeName));
    } catch(Exception e) {
      evaluation.message.addText(" some values ");
    }

    evaluation.message.addText(" are missing from ");
  }

  evaluation.message.addValue(evaluation.currentValue.strValue);
  evaluation.message.addText(".");
}

///
void addNegatedLifecycleMessage(ref Evaluation evaluation, string[] presentValues) @safe nothrow {
  evaluation.message.addText(" ");

  if(presentValues.length == 1) {
    try evaluation.message.addValue(presentValues[0]); catch(Exception e) {
      evaluation.message.addText(" some value ");
    }

    evaluation.message.addText(" is present in ");
  } else {
    try evaluation.message.addValue(presentValues.niceJoin(evaluation.currentValue.typeName));
    catch(Exception e) {
      evaluation.message.addText(" some values ");
    }

    evaluation.message.addText(" are present in ");
  }

  evaluation.message.addValue(evaluation.currentValue.strValue);
  evaluation.message.addText(".");
}

string createResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) @safe nothrow {
  string message = "to contain ";

  if(expectedPieces.length > 1) {
    message ~= "all ";
  }

  message ~= expectedValue.strValue;

  return message;
}

string createNegatedResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) @safe nothrow {
  string message = "to not contain ";

  if(expectedPieces.length > 1) {
    message ~= "any ";
  }

  message ~= expectedValue.strValue;

  return message;
}

string niceJoin(string[] values, string typeName = "") @safe nothrow {
  string result = "";

  try {
    result = values.to!string;

    if(!typeName.canFind("string")) {
      result = result.replace(`"`, "");
    }
  } catch(Exception) {}

  return result;
}