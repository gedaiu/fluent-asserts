module fluentasserts.operations.string.startWith;

import std.string;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.results.serializers;

import fluentasserts.core.lifecycle;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import std.conv;
  import std.meta;
}

static immutable startWithDescription = "Tests that the tested string starts with the expected value.";

///
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

  @(Type.stringof ~ " throws detailed error when the string does not start with expected substring")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.startWith("other");
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should start with "other". "test string" does not start with "other".`);
    msg.split("\n")[1].strip.should.equal(`Expected:to start with "other"`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }

  @(Type.stringof ~ " throws detailed error when the string does not start with expected char")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.startWith('o');
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should start with 'o'. "test string" does not start with 'o'.`);
    msg.split("\n")[1].strip.should.equal(`Expected:to start with 'o'`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }

  @(Type.stringof ~ " throws detailed error when the string unexpectedly starts with a substring")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.not.startWith("test");
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should not start with "test". "test string" starts with "test".`);
    msg.split("\n")[1].strip.should.equal(`Expected:not to start with "test"`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }

  @(Type.stringof ~ " throws detailed error when the string unexpectedly starts with a char")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.not.startWith('t');
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should not start with 't'. "test string" starts with 't'.`);
    msg.split("\n")[1].strip.should.equal(`Expected:not to start with 't'`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }
}
