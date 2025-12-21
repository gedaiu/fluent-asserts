module fluentasserts.operations.string.contain;

import std.algorithm;
import std.array;
import std.exception : assumeWontThrow;
import std.conv;

import fluentasserts.core.listcomparison;
import fluentasserts.results.printer;
import fluentasserts.results.asserts : AssertResult;
import fluentasserts.core.evaluation;
import fluentasserts.results.serializers;
import fluentasserts.core.memory;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.algorithm : map;
  import std.string;
}

static immutable containDescription = "When the tested value is a string, it asserts that the given string val is a substring of the target. \n\n" ~
  "When the tested value is an array, it asserts that the given val is inside the tested value.";

/// Asserts that a string contains specified substrings.
void contain(ref Evaluation evaluation) @trusted nothrow @nogc {
  auto expectedPieces = evaluation.expectedValue.strValue[].parseList;
  cleanString(expectedPieces);
  auto testData = evaluation.currentValue.strValue[].cleanString;
  bool negated = evaluation.isNegated;

  auto result = negated
    ? countMatches!true(expectedPieces, testData)
    : countMatches!false(expectedPieces, testData);

  if (result.count == 0) {
    return;
  }

  evaluation.result.addText(" ");
  appendValueList(evaluation.result, expectedPieces, testData, result, negated);
  evaluation.result.addText(negated
    ? (result.count == 1 ? " is present in " : " are present in ")
    : (result.count == 1 ? " is missing from " : " are missing from "));
  evaluation.result.addValue(evaluation.currentValue.strValue[]);

  if (negated) {
    evaluation.result.expected.put("not ");
  }
  evaluation.result.expected.put("to contain ");
  if (negated ? result.count > 1 : expectedPieces.length > 1) {
    evaluation.result.expected.put(negated ? "any " : "all ");
  }
  evaluation.result.expected.put(evaluation.expectedValue.strValue[]);
  evaluation.result.actual.put(testData);
  evaluation.result.negated = negated;
}

private struct MatchResult {
  size_t count;
  const(char)[] first;
}

private MatchResult countMatches(bool findPresent)(ref HeapStringList pieces, const(char)[] testData) @nogc nothrow {
  MatchResult result;
  foreach (i; 0 .. pieces.length) {
    auto piece = pieces[i][];
    if (canFind(testData, piece) != findPresent) {
      continue;
    }
    if (result.count == 0) {
      result.first = piece;
    }
    result.count++;
  }
  return result;
}

private void appendValueList(ref AssertResult result, ref HeapStringList pieces, const(char)[] testData,
                             MatchResult matchResult, bool findPresent) @nogc nothrow {
  if (matchResult.count == 1) {
    result.addValue(matchResult.first);
    return;
  }

  result.addText("[");
  bool first = true;
  foreach (i; 0 .. pieces.length) {
    auto piece = pieces[i][];
    if (canFind(testData, piece) != findPresent) {
      continue;
    }
    if (!first) {
      result.addText(", ");
    }
    result.addValue(piece);
    first = false;
  }
  result.addText("]");
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

  expect(evaluation.result.expected[]).to.equal(`to contain foo`);
  expect(evaluation.result.actual[]).to.equal("hello world");
}

@("string hello world not contain world reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect("hello world").to.not.contain("world");
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal(`not to contain world`);
  expect(evaluation.result.actual[]).to.equal("hello world");
  expect(evaluation.result.negated).to.equal(true);
}

/// Asserts that an array contains specified elements.
/// Sets evaluation.result with missing values if the assertion fails.
void arrayContain(ref Evaluation evaluation) @trusted nothrow {
  auto expectedPieces = evaluation.expectedValue.proxyValue.toArray;
  auto testData = evaluation.currentValue.proxyValue.toArray;

  if (!evaluation.isNegated) {
    auto missingValues = filterHeapEquableValues(expectedPieces, testData, false);

    if (missingValues.length > 0) {
      addLifecycleMessage(evaluation, missingValues);
      evaluation.result.expected = createResultMessage(evaluation.expectedValue, expectedPieces);
      evaluation.result.actual = evaluation.currentValue.strValue[];
    }
  } else {
    auto presentValues = filterHeapEquableValues(expectedPieces, testData, true);

    if (presentValues.length > 0) {
      addNegatedLifecycleMessage(evaluation, presentValues);
      evaluation.result.expected = createNegatedResultMessage(evaluation.expectedValue, expectedPieces);
      evaluation.result.actual = evaluation.currentValue.strValue[];
      evaluation.result.negated = true;
    }
  }
}

/// Filters elements from `source` based on whether they exist in `searchIn`.
/// When `keepFound` is true, returns elements that ARE in searchIn.
/// When `keepFound` is false, returns elements that are NOT in searchIn.
HeapEquableValue[] filterHeapEquableValues(
  HeapEquableValue[] source,
  HeapEquableValue[] searchIn,
  bool keepFound
) @trusted nothrow {
  HeapEquableValue[] result;

  foreach (ref a; source) {
    bool found = false;
    foreach (ref b; searchIn) {
      if (b.isEqualTo(a)) {
        found = true;
        break;
      }
    }

    if (found == keepFound) {
      result ~= a;
    }
  }

  return result;
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

  expect(evaluation.result.expected[]).to.equal("to contain 5");
  expect(evaluation.result.actual[]).to.equal("[1, 2, 3]");
}

@("array [1,2,3] not contain 2 reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.not.contain(2);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("not to contain 2");
  expect(evaluation.result.negated).to.equal(true);
}

/// Asserts that an array contains only the specified elements (no extras, no missing).
/// Sets evaluation.result with extra/missing arrays if the assertion fails.
void arrayContainOnly(ref Evaluation evaluation) @safe nothrow {
  auto expectedPieces = evaluation.expectedValue.proxyValue.toArray;
  auto testData = evaluation.currentValue.proxyValue.toArray;

  auto comparison = ListComparison!HeapEquableValue(testData, expectedPieces);

  auto missing = comparison.missing;
  auto extra = comparison.extra;
  auto common = comparison.common;

  if(!evaluation.isNegated) {
    auto isSuccess = missing.length == 0 && extra.length == 0 && common.length == testData.length;

    if(!isSuccess) {
      evaluation.result.expected.put("to contain only ");
      evaluation.result.expected.put(expectedPieces.niceJoin(evaluation.currentValue.typeName.idup));
      evaluation.result.actual.put(testData.niceJoin(evaluation.currentValue.typeName.idup));

      foreach(e; extra) {
        evaluation.result.extra ~= e.getSerialized.idup.cleanString;
      }

      foreach(m; missing) {
        evaluation.result.missing ~= m.getSerialized.idup.cleanString;
      }
    }
  } else {
    auto isSuccess = (missing.length != 0 || extra.length != 0) || common.length != testData.length;

    if(!isSuccess) {
      evaluation.result.expected.put("not to contain only ");
      evaluation.result.expected.put(expectedPieces.niceJoin(evaluation.currentValue.typeName.idup));
      evaluation.result.actual.put(testData.niceJoin(evaluation.currentValue.typeName.idup));
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

  expect(evaluation.result.actual[]).to.equal("[1, 2, 3, 4]");
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

/// Adds a failure message to evaluation.result describing missing string values.
void addLifecycleMessage(ref Evaluation evaluation, string[] missingValues) @safe nothrow {
  evaluation.result.addText(". ");

  if(missingValues.length == 1) {
    evaluation.result.addValue(missingValues[0]);
    evaluation.result.addText(" is missing from ");
  } else {
    evaluation.result.addValue(missingValues.niceJoin(evaluation.currentValue.typeName.idup));
    evaluation.result.addText(" are missing from ");
  }

  evaluation.result.addValue(evaluation.currentValue.strValue[]);
}

/// Adds a failure message to evaluation.result describing missing HeapEquableValue elements.
void addLifecycleMessage(ref Evaluation evaluation, HeapEquableValue[] missingValues) @safe nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup.cleanString;
    }
  } catch (Exception) {
    return;
  }

  addLifecycleMessage(evaluation, missing);
}

/// Adds a negated failure message to evaluation.result describing unexpectedly present string values.
void addNegatedLifecycleMessage(ref Evaluation evaluation, string[] presentValues) @safe nothrow {
  evaluation.result.addText(". ");

  if(presentValues.length == 1) {
    evaluation.result.addValue(presentValues[0]);
    evaluation.result.addText(" is present in ");
  } else {
    evaluation.result.addValue(presentValues.niceJoin(evaluation.currentValue.typeName.idup));
    evaluation.result.addText(" are present in ");
  }

  evaluation.result.addValue(evaluation.currentValue.strValue[]);
}

/// Adds a negated failure message to evaluation.result describing unexpectedly present HeapEquableValue elements.
void addNegatedLifecycleMessage(ref Evaluation evaluation, HeapEquableValue[] missingValues) @safe nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup;
    }
  } catch (Exception) {
    return;
  }

  addNegatedLifecycleMessage(evaluation, missing);
}

string createResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) @safe nothrow {
  string message = "to contain ";

  if(expectedPieces.length > 1) {
    message ~= "all ";
  }

  message ~= expectedValue.strValue[].idup;

  return message;
}

/// Creates an expected result message from HeapEquableValue array.
string createResultMessage(ValueEvaluation expectedValue, HeapEquableValue[] missingValues) @safe nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup;
    }
  } catch (Exception) {
    return "";
  }

  return createResultMessage(expectedValue, missing);
}

string createNegatedResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) @safe nothrow {
  string message = "not to contain ";

  if(expectedPieces.length > 1) {
    message ~= "any ";
  }

  message ~= expectedValue.strValue[].idup;

  return message;
}

/// Creates a negated expected result message from HeapEquableValue array.
string createNegatedResultMessage(ValueEvaluation expectedValue, HeapEquableValue[] missingValues) @safe nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup;
    }
  } catch (Exception) {
    return "";
  }

  return createNegatedResultMessage(expectedValue, missing);
}

string niceJoin(string[] values, string typeName = "") @trusted nothrow {
  string result = values.to!string.assumeWontThrow;

  if(!typeName.canFind("string")) {
    result = result.replace(`"`, "");
  }

  return result;
}

string niceJoin(HeapEquableValue[] values, string typeName = "") @trusted nothrow {
  string[] strValues;
  try {
    strValues = new string[values.length];
    foreach (i, ref val; values) {
      strValues[i] = val.getSerialized.idup.cleanString;
    }
  } catch (Exception) {
    return "";
  }
  return strValues.niceJoin(typeName);
}

@("range contain array succeeds")
unittest {
  [1, 2, 3].map!"a".should.contain([2, 1]);
}

@("range not contain missing array succeeds")
unittest {
  [1, 2, 3].map!"a".should.not.contain([4, 5, 6, 7]);
}

@("range contain element succeeds")
unittest {
  [1, 2, 3].map!"a".should.contain(1);
}

@("range contain missing array reports missing elements")
unittest {
  auto evaluation = ({
    [1, 2, 3].map!"a".should.contain([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal(`[1, 2, 3].map!"a" should contain [4, 5]. [4, 5] are missing from [1, 2, 3].`);
}

@("range not contain present array reports present elements")
unittest {
  auto evaluation = ({
    [1, 2, 3].map!"a".should.not.contain([1, 2]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal(`[1, 2, 3].map!"a" should not contain [1, 2]. [1, 2] are present in [1, 2, 3].`);
}

@("range contain missing element reports missing element")
unittest {
  auto evaluation = ({
    [1, 2, 3].map!"a".should.contain(4);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal(`[1, 2, 3].map!"a" should contain 4. 4 is missing from [1, 2, 3].`);
}

@("const range contain array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
}

@("const range contain const range succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.contain(data);
}

@("array contain const array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  [1, 2, 3].should.contain(data);
}

@("const range not contain transformed data succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

@("immutable range contain array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
}

@("immutable range contain immutable range succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.contain(data);
}

@("array contain immutable array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  [1, 2, 3].should.contain(data);
}

@("immutable range not contain transformed data succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

@("empty array containOnly empty array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[] list;
  list.should.containOnly([]);
}

@("const range containOnly reordered array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([3, 2, 1]);
}

@("const range containOnly const range succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly(data);
}

@("array containOnly const array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  [1, 2, 3].should.containOnly(data);
}

@("const range not containOnly transformed data succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];

  ({
    data.map!"a * 4".should.not.containOnly(data);
  }).should.not.throwAnyException;
}

@("immutable range containOnly reordered array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([2, 1, 3]);
}

@("immutable range containOnly immutable range succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly(data);
}

@("array containOnly immutable array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  [1, 2, 3].should.containOnly(data);
}

@("immutable range not containOnly transformed data succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];

  ({
    data.map!"a * 4".should.not.containOnly(data);
  }).should.not.throwAnyException;
}

@("custom range contain array succeeds")
unittest {
  struct Range {
    int n;
    int front() {
      return n;
    }
    void popFront() {
      ++n;
    }
    bool empty() {
      return n == 3;
    }
  }

  Range().should.contain([0,1]);
}

@("custom range contain element succeeds")
unittest {
  struct Range {
    int n;
    int front() {
      return n;
    }
    void popFront() {
      ++n;
    }
    bool empty() {
      return n == 3;
    }
  }

  Range().should.contain(0);
}

@("custom range contain missing element reports missing")
unittest {
  struct Range {
    int n;
    int front() {
      return n;
    }
    void popFront() {
      ++n;
    }
    bool empty() {
      return n == 3;
    }
  }

  auto evaluation = ({
    Range().should.contain([2, 3]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal("Range() should contain [2, 3]. 3 is missing from [0, 1, 2].");
}

@("custom range contain missing single element reports missing")
unittest {
  struct Range {
    int n;
    int front() {
      return n;
    }
    void popFront() {
      ++n;
    }
    bool empty() {
      return n == 3;
    }
  }

  auto evaluation = ({
    Range().should.contain(3);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal("Range() should contain 3. 3 is missing from [0, 1, 2].");
}
