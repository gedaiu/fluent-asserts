module fluentasserts.operations.type.instanceOf;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;
import std.algorithm;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.meta;
  import std.string;
}

static immutable instanceOfDescription = "Asserts that the tested value is related to a type.";

///
void instanceOf(ref Evaluation evaluation) @safe nothrow {
  string expectedType = evaluation.expectedValue.strValue[1 .. $-1];
  string currentType = evaluation.currentValue.typeNames[0];

  evaluation.result.addText(". ");

  auto existingTypes = findAmong(evaluation.currentValue.typeNames, [expectedType]);

  auto isExpected = existingTypes.length > 0;

  if(evaluation.isNegated) {
    isExpected = !isExpected;
  }

  if(isExpected) {
    return;
  }

  evaluation.result.addValue(evaluation.currentValue.strValue);
  evaluation.result.addText(" is instance of ");
  evaluation.result.addValue(currentType);
  evaluation.result.addText(".");

  evaluation.result.expected = "typeof " ~ expectedType;
  evaluation.result.actual = "typeof " ~ currentType;
  evaluation.result.negated = evaluation.isNegated;
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

@("does not throw when comparing an object")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto value = new Object();

  expect(value).to.be.instanceOf!Object;
  expect(value).to.not.be.instanceOf!string;
}

@("does not throw when comparing an Exception with an Object")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto value = new Exception("some test");

  expect(value).to.be.instanceOf!Exception;
  expect(value).to.be.instanceOf!Object;
  expect(value).to.not.be.instanceOf!string;
}

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " can compare two types")
  unittest {
    Lifecycle.instance.disableFailureHandling = false;
    Type value = cast(Type) 40;
    expect(value).to.be.instanceOf!Type;
    expect(value).to.not.be.instanceOf!string;
  }

  @(Type.stringof ~ " instanceOf string reports error with expected and actual")
  unittest {
    Type value = cast(Type) 40;

    auto evaluation = ({
      expect(value).to.be.instanceOf!string;
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal("typeof string");
    expect(evaluation.result.actual).to.equal("typeof " ~ Type.stringof);
  }

  @(Type.stringof ~ " not instanceOf itself reports error with expected and negated")
  unittest {
    Type value = cast(Type) 40;

    auto evaluation = ({
      expect(value).to.not.be.instanceOf!Type;
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal("typeof " ~ Type.stringof);
    expect(evaluation.result.actual).to.equal("typeof " ~ Type.stringof);
    expect(evaluation.result.negated).to.equal(true);
  }
}