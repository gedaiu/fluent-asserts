module fluentasserts.core.operations.beNull;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import std.algorithm;

version(unittest) {
  import fluentasserts.core.base : should, TestException;
}

static immutable beNullDescription = "Asserts that the value is null.";

///
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
  void delegate() action;
  action.should.beNull;
}

@("beNull fails for non-null delegate")
unittest {
  auto msg = ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

  msg.should.startWith("({ }) should be null.");
  msg.should.contain("Expected:null\n");
  msg.should.not.contain("Actual:null\n");
}

@("beNull negated passes for non-null delegate")
unittest {
  ({ }).should.not.beNull;
}

@("beNull negated fails for null delegate")
unittest {
  void delegate() action;

  auto msg = ({
    action.should.not.beNull;
  }).should.throwException!TestException.msg;

  msg.should.startWith("action should not be null.");
  msg.should.contain("Expected:not null");
  msg.should.contain("Actual:null");
}
