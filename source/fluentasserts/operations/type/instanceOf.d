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
  auto value = new Object();

  expect(value).to.be.instanceOf!Object;
  expect(value).to.not.be.instanceOf!string;
}

@("does not throw when comparing an Exception with an Object")
unittest {
  auto value = new Exception("some test");

  expect(value).to.be.instanceOf!Exception;
  expect(value).to.be.instanceOf!Object;
  expect(value).to.not.be.instanceOf!string;
}

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " can compare two types")
  unittest {
    Type value = cast(Type) 40;
    expect(value).to.be.instanceOf!Type;
    expect(value).to.not.be.instanceOf!string;
  }

  @(Type.stringof ~ " throws detailed error when the types do not match")
  unittest {
    Type value = cast(Type) 40;
    auto msg = ({
      expect(value).to.be.instanceOf!string;
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(value.to!string ~ ` should be instance of "string". ` ~ value.to!string ~ " is instance of " ~ Type.stringof ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:typeof string");
    msg.split("\n")[2].strip.should.equal("Actual:typeof " ~ Type.stringof);
  }

  @(Type.stringof ~ " throws detailed error when the types match but negated")
  unittest {
    Type value = cast(Type) 40;
    auto msg = ({
      expect(value).to.not.be.instanceOf!Type;
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(value.to!string ~ ` should not be instance of "` ~ Type.stringof ~ `". ` ~ value.to!string ~ " is instance of " ~ Type.stringof ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:not typeof " ~ Type.stringof);
    msg.split("\n")[2].strip.should.equal("Actual:typeof " ~ Type.stringof);
  }
}