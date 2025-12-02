module fluentasserts.operations.string.endWith;

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

static immutable endWithDescription = "Tests that the tested string ends with the expected value.";

///
void endWith(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(".");

  auto current = evaluation.currentValue.strValue.cleanString;
  auto expected = evaluation.expectedValue.strValue.cleanString;

  long index = -1;

  try {
    index = current.lastIndexOf(expected);
  } catch(Exception) { }

  auto doesEndWith = index >= 0 && index == current.length - expected.length;

  if(evaluation.isNegated) {
    if(doesEndWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" ends with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to end with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
      evaluation.result.negated = true;
    }
  } else {
    if(!doesEndWith) {
      evaluation.result.addText(" ");
      evaluation.result.addValue(evaluation.currentValue.strValue);
      evaluation.result.addText(" does not end with ");
      evaluation.result.addValue(evaluation.expectedValue.strValue);
      evaluation.result.addText(".");

      evaluation.result.expected = "to end with " ~ evaluation.expectedValue.strValue;
      evaluation.result.actual = evaluation.currentValue.strValue;
    }
  }
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

  @(Type.stringof ~ " throws detailed error when the string does not end with expected substring")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.endWith("other");
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should end with "other". "test string" does not end with "other".`);
    msg.split("\n")[1].strip.should.equal(`Expected:to end with "other"`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }

  @(Type.stringof ~ " throws detailed error when the string does not end with expected char")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.endWith('o');
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should end with 'o'. "test string" does not end with 'o'.`);
    msg.split("\n")[1].strip.should.equal(`Expected:to end with 'o'`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }

  @(Type.stringof ~ " throws detailed error when the string unexpectedly ends with a substring")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.not.endWith("string");
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should not end with "string". "test string" ends with "string".`);
    msg.split("\n")[1].strip.should.equal(`Expected:not to end with "string"`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }

  @(Type.stringof ~ " throws detailed error when the string unexpectedly ends with a char")
  unittest {
    Type testValue = "test string".to!Type;
    auto msg = ({
      expect(testValue).to.not.endWith('g');
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.contain(`"test string" should not end with 'g'. "test string" ends with 'g'.`);
    msg.split("\n")[1].strip.should.equal(`Expected:not to end with 'g'`);
    msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
  }
}
