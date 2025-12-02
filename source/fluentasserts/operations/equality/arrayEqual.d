module fluentasserts.operations.equality.arrayEqual;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.string;
}

static immutable arrayEqualDescription = "Asserts that the target is strictly == equal to the given val.";

///
void arrayEqual(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");
  bool result = true;

  EquableValue[] expectedPieces = evaluation.expectedValue.proxyValue.toArray;
  EquableValue[] testData = evaluation.currentValue.proxyValue.toArray;

  if(testData.length == expectedPieces.length) {
    foreach(index, testedValue; testData) {
      if(testedValue !is null && !testedValue.isEqualTo(expectedPieces[index])) {
        result = false;
        break;
      }
    }
  } else {
    result = false;
  }

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.expected = evaluation.expectedValue.strValue;
  evaluation.result.actual = evaluation.currentValue.strValue;
  evaluation.result.negated = evaluation.isNegated;

  if(!evaluation.isNegated) {
    evaluation.result.computeDiff(evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  }
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

  expect(evaluation.result.expected).to.equal("[1, 2, 4]");
  expect(evaluation.result.actual).to.equal("[1, 2, 3]");
}

@("[1,2,3] not equal [1,2,3] reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.not.equal([1, 2, 3]);
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal("[1, 2, 3]");
  expect(evaluation.result.actual).to.equal("[1, 2, 3]");
  expect(evaluation.result.negated).to.equal(true);
}

@("[1,2,3] equal [1,2] reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect([1, 2, 3]).to.equal([1, 2]);
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal("[1, 2]");
  expect(evaluation.result.actual).to.equal("[1, 2, 3]");
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

  expect(evaluation.result.expected).to.equal(`["a", "b", "d"]`);
  expect(evaluation.result.actual).to.equal(`["a", "b", "c"]`);
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
