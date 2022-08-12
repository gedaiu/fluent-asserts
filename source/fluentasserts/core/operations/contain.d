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

static immutable containDescription = "When the tested value is a string, it asserts that the given string val is a substring of the target. \n\n" ~
  "When the tested value is an array, it asserts that the given val is inside the tested value.";

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
      catch(Exception e) {
        results ~= e.toResults;
        return results;
      }
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
      catch(Exception e) {
        results ~= e.toResults;
        return results;
      }
    }
  }

  return results;
}

///
IResult[] arrayContain(ref Evaluation evaluation) @trusted nothrow {
  evaluation.message.addText(".");

  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.proxyValue.toArray;
  auto testData = evaluation.currentValue.proxyValue.toArray;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => testData.filter!(b => b.isEqualTo(a)).empty).array;

    if(missingValues.length > 0) {
      addLifecycleMessage(evaluation, missingValues);
      try results ~= new ExpectedActualResult(createResultMessage(evaluation.expectedValue, expectedPieces), evaluation.currentValue.strValue);
      catch(Exception e) {
        results ~= e.toResults;
        return results;
      }
    }
  } else {
    auto presentValues = expectedPieces.filter!(a => !testData.filter!(b => b.isEqualTo(a)).empty).array;

    if(presentValues.length > 0) {
      addNegatedLifecycleMessage(evaluation, presentValues);
      try results ~= new ExpectedActualResult(createNegatedResultMessage(evaluation.expectedValue, expectedPieces), evaluation.currentValue.strValue);
      catch(Exception e) {
        results ~= e.toResults;
        return results;
      }
    }
  }

  return results;
}

///
IResult[] arrayContainOnly(ref Evaluation evaluation) @safe nothrow {
  evaluation.message.addText(".");

  IResult[] results = [];

  auto expectedPieces = evaluation.expectedValue.proxyValue.toArray;
  auto testData = evaluation.currentValue.proxyValue.toArray;

  auto comparison = ListComparison!EquableValue(testData, expectedPieces);

  EquableValue[] missing;
  EquableValue[] extra;
  EquableValue[] common;

  try {
    missing = comparison.missing;
    extra = comparison.extra;
    common = comparison.common;
  } catch(Exception e) {
    results ~= e.toResults;

    return results;
  }

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
      catch(Exception e) {
        results ~= e.toResults;
        return results;
      }

      try results ~= new ExtraMissingResult(strExtra, strMissing);
      catch(Exception e) {
        results ~= e.toResults;
        return results;
      }
    }
  } else {
    auto isSuccess = (missing.length != 0 || extra.length != 0) || common.length != testData.length;

    if(!isSuccess) {
      try results ~= new ExpectedActualResult("to not contain " ~ expectedPieces.niceJoin(evaluation.currentValue.typeName), testData.niceJoin(evaluation.currentValue.typeName));
      catch(Exception e) {
        results ~= e.toResults;
        return results;
      }
    }
  }

  return results;
}

///
void addLifecycleMessage(ref Evaluation evaluation, string[] missingValues) @safe nothrow {
  evaluation.message.addText(" ");

  if(missingValues.length == 1) {
    try evaluation.message.addValue(missingValues[0]); catch(Exception) {
      evaluation.message.addText(" some value ");
    }

    evaluation.message.addText(" is missing from ");
  } else {
    try {
      evaluation.message.addValue(missingValues.niceJoin(evaluation.currentValue.typeName));
    } catch(Exception) {
      evaluation.message.addText(" some values ");
    }

    evaluation.message.addText(" are missing from ");
  }

  evaluation.message.addValue(evaluation.currentValue.strValue);
  evaluation.message.addText(".");
}

///
void addLifecycleMessage(ref Evaluation evaluation, EquableValue[] missingValues) @safe nothrow {
  auto missing = missingValues.map!(a => a.getSerialized.cleanString).array;

  addLifecycleMessage(evaluation, missing);
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

///
void addNegatedLifecycleMessage(ref Evaluation evaluation, EquableValue[] missingValues) @safe nothrow {
  auto missing = missingValues.map!(a => a.getSerialized).array;

  addNegatedLifecycleMessage(evaluation, missing);
}

string createResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) @safe nothrow {
  string message = "to contain ";

  if(expectedPieces.length > 1) {
    message ~= "all ";
  }

  message ~= expectedValue.strValue;

  return message;
}

///
string createResultMessage(ValueEvaluation expectedValue, EquableValue[] missingValues) @safe nothrow {
  auto missing = missingValues.map!(a => a.getSerialized).array;

  return createResultMessage(expectedValue, missing);
}

string createNegatedResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) @safe nothrow {
  string message = "to not contain ";

  if(expectedPieces.length > 1) {
    message ~= "any ";
  }

  message ~= expectedValue.strValue;

  return message;
}

///
string createNegatedResultMessage(ValueEvaluation expectedValue, EquableValue[] missingValues) @safe nothrow {
  auto missing = missingValues.map!(a => a.getSerialized).array;

  return createNegatedResultMessage(expectedValue, missing);
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

string niceJoin(EquableValue[] values, string typeName = "") @safe nothrow {
  return values.map!(a => a.getSerialized.cleanString).array.niceJoin(typeName);
}

