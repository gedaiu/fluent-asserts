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
  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString;
  auto testData = evaluation.currentValue.strValue.cleanString;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => !testData.canFind(a)).array;

    if(missingValues.length > 0) {
      addLifecycleMessage(evaluation.currentValue, missingValues);
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

///
IResult[] arrayContain(ref Evaluation evaluation) @safe nothrow {
  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString;
  auto testData = evaluation.currentValue.strValue.parseList.cleanString;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => !testData.canFind(a)).array;

    if(missingValues.length > 0) {
      addLifecycleMessage(evaluation.currentValue, missingValues);
      try results ~= new ExpectedActualResult(createResultMessage(evaluation.expectedValue, expectedPieces), evaluation.currentValue.strValue);
      catch(Exception) {}
    }
  } else {
    auto presentValues = expectedPieces.filter!(a => testData.canFind(a)).array;

    if(presentValues.length > 0) {
      addNegatedLifecycleMessage(evaluation.currentValue, presentValues);
      try results ~= new ExpectedActualResult(createNegatedResultMessage(evaluation.expectedValue, expectedPieces), evaluation.currentValue.strValue);
      catch(Exception) {}
    }
  }

  return results;
}

///
IResult[] arrayContainOnly(ref Evaluation evaluation) @safe nothrow {
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
void addLifecycleMessage(ValueEvaluation currentValue, string[] missingValues) @safe nothrow {
  Lifecycle.instance.addText(" ");

  if(missingValues.length == 1) {
    try Lifecycle.instance.addValue(missingValues[0]); catch(Exception e) {
      Lifecycle.instance.addText(" some value ");
    }

    Lifecycle.instance.addText(" is missing from ");
  } else {
    try {
      Lifecycle.instance.addValue(missingValues.niceJoin(currentValue.typeName));
    } catch(Exception e) {
      Lifecycle.instance.addText(" some values ");
    }

    Lifecycle.instance.addText(" are missing from ");
  }

  Lifecycle.instance.addValue(currentValue.strValue);
  Lifecycle.instance.addText(".");
}

///
void addNegatedLifecycleMessage(ValueEvaluation currentValue, string[] presentValues) @safe nothrow {
  Lifecycle.instance.addText(" ");

  if(presentValues.length == 1) {
    try Lifecycle.instance.addValue(presentValues[0]); catch(Exception e) {
      Lifecycle.instance.addText(" some value ");
    }

    Lifecycle.instance.addText(" is present in ");
  } else {
    try Lifecycle.instance.addValue(presentValues.niceJoin(currentValue.typeName));
    catch(Exception e) {
      Lifecycle.instance.addText(" some values ");
    }

    Lifecycle.instance.addText(" are present in ");
  }

  Lifecycle.instance.addValue(currentValue.strValue);
  Lifecycle.instance.addText(".");
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

string niceJoin(string[] values, string typeName) @safe nothrow {
  string result = "";

  try {
    result = values.to!string;

    if(!typeName.canFind("string")) {
      result = result.replace(`"`, "");
    }
  } catch(Exception) {}

  return result;
}