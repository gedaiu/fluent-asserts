module fluentasserts.operations.string.contain;

import std.algorithm;
import std.array;
import std.conv;

import fluentasserts.assertions.array;
import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.results.serializers;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.string;
}

static immutable containDescription = "When the tested value is a string, it asserts that the given string val is a substring of the target. \n\n" ~
  "When the tested value is an array, it asserts that the given val is inside the tested value.";

///
void contain(ref Evaluation evaluation) @safe nothrow {
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
}

@("string contains a substring")
unittest {
  expect("hello world").to.contain("world");
}

@("string contains multiple substrings")
unittest {
  expect("hello world").to.contain("hello");
  expect("hello world").to.contain("world");
}

@("string does not contain a substring")
unittest {
  expect("hello world").to.not.contain("foo");
}

@("string hello world contain foo reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect("hello world").to.contain("foo");
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal(`to contain "foo"`);
  expect(evaluation.result.actual).to.equal("hello world");
}

@("string hello world not contain world reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect("hello world").to.not.contain("world");
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal(`to contain "world"`);
  expect(evaluation.result.actual).to.equal("hello world");
  expect(evaluation.result.negated).to.equal(true);
}

///
void arrayContain(ref Evaluation evaluation) @trusted nothrow {
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
}

@("array contains a value")
unittest {
  expect([1, 2, 3]).to.contain(2);
}

@("array contains multiple values")
unittest {
  expect([1, 2, 3, 4, 5]).to.contain([2, 4]);
}

@("array does not contain a value")
unittest {
  expect([1, 2, 3]).to.not.contain(5);
}

@("array [1,2,3] contain 5 reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.contain(5);
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal("to contain 5");
  expect(evaluation.result.actual).to.equal("[1, 2, 3]");
}

@("array [1,2,3] not contain 2 reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.not.contain(2);
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal("to contain 2");
  expect(evaluation.result.negated).to.equal(true);
}

///
void arrayContainOnly(ref Evaluation evaluation) @safe nothrow {
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
    return;
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
}

@("array containOnly passes when elements match exactly")
unittest {
  expect([1, 2, 3]).to.containOnly([1, 2, 3]);
  expect([1, 2, 3]).to.containOnly([3, 2, 1]);
}

@("array [1,2,3,4] containOnly [1,2,3] reports error with actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3, 4]).to.containOnly([1, 2, 3]);
  }).recordEvaluation;

  expect(evaluation.result.actual).to.equal("[1, 2, 3, 4]");
}

@("array [1,2] containOnly [1,2,3] reports error with extra")
unittest {
  auto evaluation = ({
    expect([1, 2]).to.containOnly([1, 2, 3]);
  }).recordEvaluation;

  expect(evaluation.result.extra.length).to.equal(1);
  expect(evaluation.result.extra[0]).to.equal("3");
}

@("array containOnly negated passes when elements differ")
unittest {
  expect([1, 2, 3, 4]).to.not.containOnly([1, 2, 3]);
}

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

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
