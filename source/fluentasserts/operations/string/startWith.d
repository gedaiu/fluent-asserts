module fluentasserts.operations.string.startWith;

import std.string;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
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

static immutable startWithDescription = "Tests that the tested string starts with the expected value.";

/// Asserts that a string starts with the expected prefix.
void startWith(ref Evaluation evaluation) @safe nothrow @nogc {
  auto current = evaluation.currentValue.strValue[].cleanString;
  auto expected = evaluation.expectedValue.strValue[].cleanString;

  // Check if string starts with prefix (replaces indexOf for @nogc)
  bool doesStartWith = current.length >= expected.length && current[0 .. expected.length] == expected;

  if(evaluation.isNegated) {
    if(doesStartWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue[]);
      evaluation.result.addText(" starts with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue[]);

      evaluation.result.expected.put("not to start with ");
      evaluation.result.expected.put(evaluation.expectedValue.strValue[]);
      evaluation.result.actual.put(evaluation.currentValue.strValue[]);
      evaluation.result.negated = true;
    }
  } else {
    if(!doesStartWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue[]);
      evaluation.result.addText(" does not start with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue[]);

      evaluation.result.expected.put("to start with ");
      evaluation.result.expected.put(evaluation.expectedValue.strValue[]);
      evaluation.result.actual.put(evaluation.currentValue.strValue[]);
    }
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

version(unittest) {
  alias StringTypes = AliasSeq!(string, wstring, dstring);

  static foreach (Type; StringTypes) {
  @(Type.stringof ~ " checks that a string starts with a certain substring")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.startWith("test");
  }

  @(Type.stringof ~ " checks that a string starts with a certain char")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.startWith('t');
  }

  @(Type.stringof ~ " checks that a string does not start with a certain substring")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.not.startWith("other");
  }

  @(Type.stringof ~ " checks that a string does not start with a certain char")
  unittest {
    Type testValue = "test string".to!Type;
    expect(testValue).to.not.startWith('o');
  }

  @(Type.stringof ~ " test string startWith other reports error with expected and actual")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.startWith("other");
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`to start with other`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
  }

  @(Type.stringof ~ " test string startWith char o reports error with expected and actual")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.startWith('o');
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`to start with o`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
  }

  @(Type.stringof ~ " test string not startWith test reports error with expected and negated")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.not.startWith("test");
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`not to start with test`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
    expect(evaluation.result.negated).to.equal(true);
  }

  @(Type.stringof ~ " test string not startWith char t reports error with expected and negated")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.not.startWith('t');
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`not to start with t`);
    expect(evaluation.result.actual[]).to.equal(`test string`);
    expect(evaluation.result.negated).to.equal(true);
  }
}

@("lazy string throwing in startWith propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string someLazyString() {
    throw new Exception("This is it.");
  }

  ({
    someLazyString.should.startWith(" ");
  }).should.throwAnyException.withMessage("This is it.");
}
}
