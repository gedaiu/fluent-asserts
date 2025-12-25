module fluentasserts.operations.string.arraycontain;

import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.core.memory.heapequable : HeapEquableValue;
import fluentasserts.operations.string.containmessages;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
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
