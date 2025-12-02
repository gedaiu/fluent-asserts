module fluentasserts.operations.type.beNull;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import std.algorithm;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.base : should, TestException;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
}

static immutable beNullDescription = "Asserts that the value is null.";

/// Asserts that a value is null (for nullable types like pointers, delegates, classes).
void beNull(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  auto result = evaluation.currentValue.typeNames.canFind("null") || evaluation.currentValue.strValue == "null";

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  evaluation.result.expected = "null";
  evaluation.result.actual = evaluation.currentValue.typeNames.length ? evaluation.currentValue.typeNames[0] : "unknown";
  evaluation.result.negated = evaluation.isNegated;
}

@("beNull passes for null delegate")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  void delegate() action;
  action.should.beNull;
}

@("non-null delegate beNull reports error with expected null")
unittest {
  auto evaluation = ({
    ({ }).should.beNull;
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal("null");
  expect(evaluation.result.actual).to.not.equal("null");
}

@("beNull negated passes for non-null delegate")
unittest {
  ({ }).should.not.beNull;
}

@("null delegate not beNull reports error with expected and actual")
unittest {
  void delegate() action;

  auto evaluation = ({
    action.should.not.beNull;
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal("null");
  expect(evaluation.result.negated).to.equal(true);
}
