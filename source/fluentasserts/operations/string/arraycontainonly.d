module fluentasserts.operations.string.arraycontainonly;

import fluentasserts.core.listcomparison;
import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.core.memory.heapequable : HeapEquableValue;
import fluentasserts.results.serializers.stringprocessing : cleanString;
import fluentasserts.operations.string.containmessages : niceJoin;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
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

// Issue #96: Object[] and nested arrays should work with containOnly
@("Object array containOnly itself passes")
unittest {
  Object[] l = [new Object(), new Object()];
  l.should.containOnly(l);
}

// Issue #96: Object[] and nested arrays should work with containOnly
@("nested int array containOnly passes")
unittest {
  import std.range : iota;
  import std.algorithm : map;
  import std.array : array;

  auto ll = iota(1, 4).map!iota;
  ll.map!array.array.should.containOnly([[0], [0, 1], [0, 1, 2]]);
}

// Issue #85: range of ranges should work with containOnly without memory exhaustion
@("issue #85: range of ranges containOnly passes")
unittest {
  import std.range : iota;
  import std.algorithm : map;

  auto ror = iota(1, 4).map!iota;
  ror.should.containOnly([[0], [0, 1], [0, 1, 2]]);
}
