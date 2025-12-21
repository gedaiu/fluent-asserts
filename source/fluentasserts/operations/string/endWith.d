module fluentasserts.operations.string.endWith;

import std.string;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.results.serializers;

import fluentasserts.core.lifecycle;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.conv;
  import std.meta;
}

static immutable endWithDescription = "Tests that the tested string ends with the expected value.";

/// Asserts that a string ends with the expected suffix.
void endWith(ref Evaluation evaluation) @safe nothrow @nogc {
  auto current = evaluation.currentValue.strValue[].cleanString;
  auto expected = evaluation.expectedValue.strValue[].cleanString;

  bool doesEndWith = current.length >= expected.length && current[$ - expected.length .. $] == expected;

  evaluation.reportStringCheck(doesEndWith, "end with", "ends with");
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

@("multiline string ends with a certain substring")
unittest {
  expect("str\ning").to.endWith("ing");
}

alias StringTypes = AliasSeq!(string, wstring, dstring);

static foreach (Type; StringTypes) {
  @(Type.stringof ~ " checks that a string ends with a certain substring")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.endWith("string");
  }

  @(Type.stringof ~ " checks that a string ends with a certain char")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.endWith('g');
  }

  @(Type.stringof ~ " checks that a string does not end with a certain substring")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.not.endWith("other");
  }

  @(Type.stringof ~ " checks that a string does not end with a certain char")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.not.endWith('o');
  }

  @(Type.stringof ~ " test string endWith other reports error with expected and actual")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.endWith("other");
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`to end with other`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
  }

  @(Type.stringof ~ " test string endWith char o reports error with expected and actual")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.endWith('o');
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`to end with o`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
  }

  @(Type.stringof ~ " test string not endWith string reports error with expected and negated")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.not.endWith("string");
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`not to end with string`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
    expect(evaluation.result.negated).to.equal(true);
  }

  @(Type.stringof ~ " test string not endWith char g reports error with expected and negated")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.not.endWith('g');
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`not to end with g`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
    expect(evaluation.result.negated).to.equal(true);
  }
}

@("lazy string throwing in endWith propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string someLazyString() {
    throw new Exception("This is it.");
  }

  ({
    someLazyString.should.endWith(" ");
  }).should.throwAnyException.withMessage("This is it.");
}
