module fluentasserts.operations.string.startWith;

import std.string;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.results.serializers;

import fluentasserts.core.lifecycle;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.conv;
  import std.meta;
}

static immutable startWithDescription = "Tests that the tested string starts with the expected value.";

/// Asserts that a string starts with the expected prefix.
void startWith(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  auto index = evaluation.currentValue.strValue.cleanString.indexOf(evaluation.expectedValue.strValue.cleanString);
  auto doesStartWith = index == 0;

  if(evaluation.isNegated) {
    if(doesStartWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" starts with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to start with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
      evaluation.result.negated = true;
    }
  } else {
    if(!doesStartWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" does not start with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to start with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
    }
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

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

    expect(evaluation.result.expected).to.equal(`to start with "other"`);
    expect(evaluation.result.actual).to.equal(`"test string"`);
  }

  @(Type.stringof ~ " test string startWith char o reports error with expected and actual")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.startWith('o');
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal(`to start with 'o'`);
    expect(evaluation.result.actual).to.equal(`"test string"`);
  }

  @(Type.stringof ~ " test string not startWith test reports error with expected and negated")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.not.startWith("test");
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal(`to start with "test"`);
    expect(evaluation.result.actual).to.equal(`"test string"`);
    expect(evaluation.result.negated).to.equal(true);
  }

  @(Type.stringof ~ " test string not startWith char t reports error with expected and negated")
  unittest {
    Type testValue = "test string".to!Type;

    auto evaluation = ({
      expect(testValue).to.not.startWith('t');
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal(`to start with 't'`);
    expect(evaluation.result.actual).to.equal(`"test string"`);
    expect(evaluation.result.negated).to.equal(true);
  }
}
