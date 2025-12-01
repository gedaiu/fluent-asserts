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
  evaluation.result.addText(".");

  auto expectedPieces = evaluation.expectedValue.strValue.parseList.cleanString;
  auto testData = evaluation.currentValue.strValue.cleanString;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => !testData.canFind(a)).array;

    if(missingValues.length > 0) {
      addLifecycleMessage(evaluation, missingValues);
      evaluation.result.expected = createResultMessage(evaluation.expectedValue, expectedPieces);
      evaluation.result.actual = testData;
    }
  } else {
    auto presentValues = expectedPieces.filter!(a => testData.canFind(a)).array;

    if(presentValues.length > 0) {
      string message = "to contain ";

      if(presentValues.length > 1) {
        message ~= "any ";
      }

      message ~= evaluation.expectedValue.strValue;

      evaluation.result.addText(" ");

      if(presentValues.length == 1) {
        try evaluation.result.addValue(presentValues[0]); catch(Exception e) {
          evaluation.result.addText(" some value ");
        }

        evaluation.result.addText(" is present in ");
      } else {
        try evaluation.result.addValue(presentValues.to!string); catch(Exception e) {
          evaluation.result.addText(" some values ");
        }

        evaluation.result.addText(" are present in ");
      }

      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = message;
      evaluation.result.actual = testData;
      evaluation.result.negated = true;
    }
  }

  return [];
}

///
IResult[] arrayContain(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addText(".");

  auto expectedPieces = evaluation.expectedValue.proxyValue.toArray;
  auto testData = evaluation.currentValue.proxyValue.toArray;

  if(!evaluation.isNegated) {
    auto missingValues = expectedPieces.filter!(a => testData.filter!(b => b.isEqualTo(a)).empty).array;

    if(missingValues.length > 0) {
      addLifecycleMessage(evaluation, missingValues);
      evaluation.result.expected = createResultMessage(evaluation.expectedValue, expectedPieces);
      evaluation.result.actual = evaluation.currentValue.strValue;
    }
  } else {
    auto presentValues = expectedPieces.filter!(a => !testData.filter!(b => b.isEqualTo(a)).empty).array;

    if(presentValues.length > 0) {
      addNegatedLifecycleMessage(evaluation, presentValues);
      evaluation.result.expected = createNegatedResultMessage(evaluation.expectedValue, expectedPieces);
      evaluation.result.actual = evaluation.currentValue.strValue;
      evaluation.result.negated = true;
    }
  }

  return [];
}

///
IResult[] arrayContainOnly(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

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
    evaluation.result.expected = "valid comparison";
    evaluation.result.actual = "exception during comparison";
    return [];
  }

  if(!evaluation.isNegated) {
    auto isSuccess = missing.length == 0 && extra.length == 0 && common.length == testData.length;

    if(!isSuccess) {
      evaluation.result.actual = testData.niceJoin(evaluation.currentValue.typeName);

      if(extra.length > 0) {
        try {
          foreach(e; extra) {
            evaluation.result.extra ~= e.getSerialized.cleanString;
          }
        } catch(Exception) {}
      }

      if(missing.length > 0) {
        try {
          foreach(m; missing) {
            evaluation.result.missing ~= m.getSerialized.cleanString;
          }
        } catch(Exception) {}
      }
    }
  } else {
    auto isSuccess = (missing.length != 0 || extra.length != 0) || common.length != testData.length;

    if(!isSuccess) {
      evaluation.result.expected = "to contain " ~ expectedPieces.niceJoin(evaluation.currentValue.typeName);
      evaluation.result.actual = testData.niceJoin(evaluation.currentValue.typeName);
      evaluation.result.negated = true;
    }
  }

  return [];
}

///
void addLifecycleMessage(ref Evaluation evaluation, string[] missingValues) @safe nothrow {
  evaluation.result.addText(" ");

  if(missingValues.length == 1) {
    try evaluation.result.addValue(missingValues[0]); catch(Exception) {
      evaluation.result.addText(" some value ");
    }

    evaluation.result.addText(" is missing from ");
  } else {
    try {
      evaluation.result.addValue(missingValues.niceJoin(evaluation.currentValue.typeName));
    } catch(Exception) {
      evaluation.result.addText(" some values ");
    }

    evaluation.result.addText(" are missing from ");
  }

  evaluation.result.addValue(evaluation.currentValue.strValue);
  evaluation.result.addText(".");
}

///
void addLifecycleMessage(ref Evaluation evaluation, EquableValue[] missingValues) @safe nothrow {
  auto missing = missingValues.map!(a => a.getSerialized.cleanString).array;

  addLifecycleMessage(evaluation, missing);
}

///
void addNegatedLifecycleMessage(ref Evaluation evaluation, string[] presentValues) @safe nothrow {
  evaluation.result.addText(" ");

  if(presentValues.length == 1) {
    try evaluation.result.addValue(presentValues[0]); catch(Exception e) {
      evaluation.result.addText(" some value ");
    }

    evaluation.result.addText(" is present in ");
  } else {
    try evaluation.result.addValue(presentValues.niceJoin(evaluation.currentValue.typeName));
    catch(Exception e) {
      evaluation.result.addText(" some values ");
    }

    evaluation.result.addText(" are present in ");
  }

  evaluation.result.addValue(evaluation.currentValue.strValue);
  evaluation.result.addText(".");
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
  string message = "to contain ";

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

