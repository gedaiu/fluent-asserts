module fluentasserts.operations.string.contain;

import std.algorithm;
import std.array;

import fluentasserts.results.printer;
import fluentasserts.results.asserts : AssertResult;
import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.results.serializers.stringprocessing : parseList, cleanString;
import fluentasserts.core.memory.heapstring : HeapString, HeapStringList;

// Re-export array operations
public import fluentasserts.operations.string.arraycontain : arrayContain;
public import fluentasserts.operations.string.arraycontainonly : arrayContainOnly;

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

// Re-export range/immutable tests from backup
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
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
}

@("const range contain const range succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.contain(data);
}

@("array contain const array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  [1, 2, 3].should.contain(data);
}

@("const range not contain transformed data succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

@("immutable range contain array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
}

@("immutable range contain immutable range succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.contain(data);
}

@("array contain immutable array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  [1, 2, 3].should.contain(data);
}

@("immutable range not contain transformed data succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

@("empty array containOnly empty array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  int[] list;
  list.should.containOnly([]);
}

@("const range containOnly reordered array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([3, 2, 1]);
}

@("const range containOnly const range succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly(data);
}

@("array containOnly const array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];
  [1, 2, 3].should.containOnly(data);
}

@("const range not containOnly transformed data succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  const(int)[] data = [1, 2, 3];

  ({
    data.map!"a * 4".should.not.containOnly(data);
  }).should.not.throwAnyException;
}

@("immutable range containOnly reordered array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([2, 1, 3]);
}

@("immutable range containOnly immutable range succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly(data);
}

@("array containOnly immutable array succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
  Lifecycle.instance.disableFailureHandling = false;
  immutable(int)[] data = [1, 2, 3];
  [1, 2, 3].should.containOnly(data);
}

@("immutable range not containOnly transformed data succeeds")
unittest {
  import fluentasserts.core.lifecycle : Lifecycle;
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
