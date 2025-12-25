module fluentasserts.operations.equality.arrayEqual;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation.eval : Evaluation;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.algorithm : map;
  import std.string;
}

static immutable arrayEqualDescription = "Asserts that the target is strictly == equal to the given val.";

/// Asserts that two arrays are strictly equal element by element.
/// Uses proxyValue which now supports both string comparison and opEquals.
void arrayEqual(ref Evaluation evaluation) @safe nothrow {
  bool isEqual;

  if (!evaluation.currentValue.proxyValue.isNull() && !evaluation.expectedValue.proxyValue.isNull()) {
    isEqual = evaluation.currentValue.proxyValue.isEqualTo(evaluation.expectedValue.proxyValue);
  } else {
    isEqual = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;
  }

  bool passed = evaluation.isNegated ? !isEqual : isEqual;
  if (passed) {
    return;
  }

  if (evaluation.isNegated) {
    evaluation.result.expected.put("not ");
  }
  evaluation.result.expected.put(evaluation.expectedValue.strValue[]);
  evaluation.result.actual.put(evaluation.currentValue.strValue[]);
  evaluation.result.negated = evaluation.isNegated;
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

@("int array compares two equal arrays")
unittest {
  expect([1, 2, 3]).to.equal([1, 2, 3]);
}

@("int array compares two different arrays")
unittest {
  expect([1, 2, 3]).to.not.equal([1, 2, 4]);
}

@("[1,2,3] equal [1,2,4] reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.equal([1, 2, 4]);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("[1, 2, 4]");
  expect(evaluation.result.actual[]).to.equal("[1, 2, 3]");
}

@("[1,2,3] not equal [1,2,3] reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.not.equal([1, 2, 3]);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("not [1, 2, 3]");
  expect(evaluation.result.actual[]).to.equal("[1, 2, 3]");
  expect(evaluation.result.negated).to.equal(true);
}

@("[1,2,3] equal [1,2] reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.equal([1, 2]);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal("[1, 2]");
  expect(evaluation.result.actual[]).to.equal("[1, 2, 3]");
}

@("string array compares two equal arrays")
unittest {
  expect(["a", "b", "c"]).to.equal(["a", "b", "c"]);
}

@("string array compares two different arrays")
unittest {
  expect(["a", "b", "c"]).to.not.equal(["a", "b", "d"]);
}

@("string array [a,b,c] equal [a,b,d] reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect(["a", "b", "c"]).to.equal(["a", "b", "d"]);
  }).recordEvaluation;

  expect(evaluation.result.expected[]).to.equal(`[a, b, d]`);
  expect(evaluation.result.actual[]).to.equal(`[a, b, c]`);
}

@("empty arrays are equal")
unittest {
  int[] empty1;
  int[] empty2;
  expect(empty1).to.equal(empty2);
}

@("empty array differs from non-empty array")
unittest {
  int[] empty;
  expect(empty).to.not.equal([1, 2, 3]);
}

@("object array with null elements compares equal")
unittest {
  Object[] arr1 = [null, null];
  Object[] arr2 = [null, null];
  expect(arr1).to.equal(arr2);
}

@("object array with null element differs from non-null")
unittest {
  Object obj = new Object();
  Object[] arr1 = [null];
  Object[] arr2 = [obj];
  expect(arr1).to.not.equal(arr2);
}

@("lazy array throwing in equal propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[] someLazyArray() {
    throw new Exception("This is it.");
  }

  ({
    someLazyArray.should.equal([]);
  }).should.throwAnyException.withMessage("This is it.");
}

version(unittest) {
  struct ArrayTestStruct {
    int value;
    void f() {}
  }
}

@("array of structs equal same array succeeds")
unittest {
  [ArrayTestStruct(1)].should.equal([ArrayTestStruct(1)]);
}

@("array of structs equal different array reports not equal")
unittest {
  auto evaluation = ({
    [ArrayTestStruct(2)].should.equal([ArrayTestStruct(1)]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal("[ArrayTestStruct(2)] should equal [ArrayTestStruct(1)].");
}

@("const string array equal string array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(string)[] constValue = ["test", "string"];
  constValue.should.equal(["test", "string"]);
}

@("immutable string array equal string array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(string)[] immutableValue = ["test", "string"];
  immutableValue.should.equal(["test", "string"]);
}

@("string array equal const string array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const(string)[] constValue = ["test", "string"];
  ["test", "string"].should.equal(constValue);
}

@("string array equal immutable string array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable(string)[] immutableValue = ["test", "string"];
  ["test", "string"].should.equal(immutableValue);
}

version(unittest) {
  class ArrayTestEqualsClass {
    int value;

    this(int value) { this.value = value; }
    void f() {}
  }
}

@("array of class instances equal same instance succeeds")
unittest {
  auto instance = new ArrayTestEqualsClass(1);
  [instance].should.equal([instance]);
}

@("array of class instances equal different instances reports not equal")
unittest {
  auto evaluation = ({
    [new ArrayTestEqualsClass(2)].should.equal([new ArrayTestEqualsClass(1)]);
  }).recordEvaluation;

  evaluation.result.hasContent.should.equal(true);
}

@("range equal same array succeeds")
unittest {
  [1, 2, 3].map!"a".should.equal([1, 2, 3]);
}

@("range not equal reordered array succeeds")
unittest {
  [1, 2, 3].map!"a".should.not.equal([2, 1, 3]);
}

@("range not equal subset succeeds")
unittest {
  [1, 2, 3].map!"a".should.not.equal([2, 3]);
}

@("subset range not equal array succeeds")
unittest {
  [2, 3].map!"a".should.not.equal([1, 2, 3]);
}

@("range equal different array reports not equal")
unittest {
  auto evaluation = ({
    [1, 2, 3].map!"a".should.equal([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal(`[1, 2, 3] should equal [4, 5].`);
}

@("range equal different same-length array reports not equal")
unittest {
  auto evaluation = ({
    [1, 2].map!"a".should.equal([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal(`[1, 2] should equal [4, 5].`);
}

@("range equal reordered array reports not equal")
unittest {
  auto evaluation = ({
    [1, 2, 3].map!"a".should.equal([2, 3, 1]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal(`[1, 2, 3] should equal [2, 3, 1].`);
}

@("range not equal same array reports is equal")
unittest {
  auto evaluation = ({
    [1, 2, 3].map!"a".should.not.equal([1, 2, 3]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal(`[1, 2, 3] should not equal [1, 2, 3].`);
}

@("custom range equal array succeeds")
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

  Range().should.equal([0,1,2]);
}

@("custom range equal shorter array reports not equal")
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
    Range().should.equal([0,1]);
  }).recordEvaluation;

  evaluation.result.messageString.should.equal("[0, 1, 2] should equal [0, 1].");
}

@("custom const range equal array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  struct ConstRange {
    int n;
    const(int) front() {
      return n;
    }

    void popFront() {
      ++n;
    }

    bool empty() {
      return n == 3;
    }
  }

  [0,1,2].should.equal(ConstRange());
}

@("array equal custom const range succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  struct ConstRange {
    int n;
    const(int) front() {
      return n;
    }

    void popFront() {
      ++n;
    }

    bool empty() {
      return n == 3;
    }
  }

  ConstRange().should.equal([0,1,2]);
}

@("custom immutable range equal array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  struct ImmutableRange {
    int n;
    immutable(int) front() {
      return n;
    }

    void popFront() {
      ++n;
    }

    bool empty() {
      return n == 3;
    }
  }

  [0,1,2].should.equal(ImmutableRange());
}

@("array equal custom immutable range succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  struct ImmutableRange {
    int n;
    immutable(int) front() {
      return n;
    }

    void popFront() {
      ++n;
    }

    bool empty() {
      return n == 3;
    }
  }

  ImmutableRange().should.equal([0,1,2]);
}

@("immutable string array equal empty array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable string[] someList;

  someList.should.equal([]);
}

@("const object array equal array with same object succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  class A {}
  A a = new A();
  const(A)[] arr = [a];
  arr.should.equal([a]);
}
