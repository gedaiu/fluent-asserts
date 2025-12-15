module fluentasserts.operations.type.instanceOf;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;

import std.conv;
import std.datetime;
import std.algorithm;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.meta;
  import std.string;
}

static immutable instanceOfDescription = "Asserts that the tested value is related to a type.";

/// Asserts that a value is an instance of a specific type or inherits from it.
void instanceOf(ref Evaluation evaluation) @safe nothrow @nogc {
  const(char)[] expectedType = evaluation.expectedValue.strValue[][1 .. $-1];
  string currentType = evaluation.currentValue.typeNames[0];

  evaluation.result.addText(". ");

  // Check if expectedType is in typeNames (replaces findAmong for @nogc)
  bool found = false;
  foreach (typeName; evaluation.currentValue.typeNames) {
    if (typeName == expectedType) {
      found = true;
      break;
    }
  }

  auto isExpected = found;

  if(evaluation.isNegated) {
    isExpected = !isExpected;
  }

  if(isExpected) {
    return;
  }

  evaluation.result.addValue(evaluation.currentValue.strValue[]);
  evaluation.result.addText(" is instance of ");
  evaluation.result.addValue(currentType);
  evaluation.result.addText(".");

  if (evaluation.isNegated) {
    evaluation.result.expected.put("not typeof ");
  } else {
    evaluation.result.expected.put("typeof ");
  }
  evaluation.result.expected.put(expectedType);
  evaluation.result.actual.put("typeof ");
  evaluation.result.actual.put(currentType);
  evaluation.result.negated = evaluation.isNegated;
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

version(unittest) {
  alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);
}

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

version(unittest) {
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

      expect(evaluation.result.expected[]).to.equal("typeof string");
      expect(evaluation.result.actual[]).to.equal("typeof " ~ Type.stringof);
    }

    @(Type.stringof ~ " not instanceOf itself reports error with expected and negated")
    unittest {
      Type value = cast(Type) 40;

      auto evaluation = ({
        expect(value).to.not.be.instanceOf!Type;
      }).recordEvaluation;

      expect(evaluation.result.expected[]).to.equal("not typeof " ~ Type.stringof);
      expect(evaluation.result.actual[]).to.equal("typeof " ~ Type.stringof);
      expect(evaluation.result.negated).to.equal(true);
    }
  }
}

@("lazy object throwing in instanceOf propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Object someLazyObject() {
    throw new Exception("This is it.");
  }

  ({
    someLazyObject.should.be.instanceOf!Object;
  }).should.throwAnyException.withMessage("This is it.");
}

@("object instanceOf same class succeeds")
unittest {
  class SomeClass { }
  auto someObject = new SomeClass;
  someObject.should.be.instanceOf!SomeClass;
}

@("extended object instanceOf base class succeeds")
unittest {
  class BaseClass { }
  class ExtendedClass : BaseClass { }
  auto extendedObject = new ExtendedClass;
  extendedObject.should.be.instanceOf!BaseClass;
}

@("object not instanceOf different class succeeds")
unittest {
  class SomeClass { }
  class OtherClass { }
  auto someObject = new SomeClass;
  someObject.should.not.be.instanceOf!OtherClass;
}

@("object not instanceOf unrelated base class succeeds")
unittest {
  class BaseClass { }
  class SomeClass { }
  auto someObject = new SomeClass;
  someObject.should.not.be.instanceOf!BaseClass;
}

version(unittest) {
  interface InstanceOfTestInterface { }
  class InstanceOfBaseClass : InstanceOfTestInterface { }
  class InstanceOfOtherClass { }
}

@("object instanceOf wrong class reports expected class name")
unittest {
  auto otherObject = new InstanceOfOtherClass;

  auto evaluation = ({
    otherObject.should.be.instanceOf!InstanceOfBaseClass;
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`otherObject should be instance of`);
  evaluation.result.expected[].should.equal("typeof fluentasserts.operations.type.instanceOf.InstanceOfBaseClass");
  evaluation.result.actual[].should.equal("typeof fluentasserts.operations.type.instanceOf.InstanceOfOtherClass");
}

@("object not instanceOf own class reports expected not typeof")
unittest {
  auto otherObject = new InstanceOfOtherClass;

  auto evaluation = ({
    otherObject.should.not.be.instanceOf!InstanceOfOtherClass;
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith(`otherObject should not be instance of "fluentasserts.operations.type.instanceOf.InstanceOfOtherClass".`);
  evaluation.result.messageString.should.endWith(`is instance of fluentasserts.operations.type.instanceOf.InstanceOfOtherClass.`);
  evaluation.result.actual[].should.equal("typeof fluentasserts.operations.type.instanceOf.InstanceOfOtherClass");
  evaluation.result.expected[].should.equal("not typeof fluentasserts.operations.type.instanceOf.InstanceOfOtherClass");
}

@("interface instanceOf same interface succeeds")
unittest {
  InstanceOfTestInterface someInterface = new InstanceOfBaseClass;
  someInterface.should.be.instanceOf!InstanceOfTestInterface;
}

@("interface not instanceOf implementing class succeeds")
unittest {
  InstanceOfTestInterface someInterface = new InstanceOfBaseClass;
  someInterface.should.not.be.instanceOf!InstanceOfBaseClass;
}

@("class instanceOf implemented interface succeeds")
unittest {
  auto someObject = new InstanceOfBaseClass;
  someObject.should.be.instanceOf!InstanceOfTestInterface;
}

@("object instanceOf unimplemented interface reports expected interface name")
unittest {
  auto otherObject = new InstanceOfOtherClass;

  auto evaluation = ({
    otherObject.should.be.instanceOf!InstanceOfTestInterface;
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`otherObject should be instance of`);
  evaluation.result.messageString.should.contain(`InstanceOfTestInterface`);
  evaluation.result.expected[].should.equal("typeof fluentasserts.operations.type.instanceOf.InstanceOfTestInterface");
  evaluation.result.actual[].should.equal("typeof fluentasserts.operations.type.instanceOf.InstanceOfOtherClass");
}

@("object not instanceOf implemented interface reports expected not typeof")
unittest {
  auto someObject = new InstanceOfBaseClass;

  auto evaluation = ({
    someObject.should.not.be.instanceOf!InstanceOfTestInterface;
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith(`someObject should not be instance of "fluentasserts.operations.type.instanceOf.InstanceOfTestInterface".`);
  evaluation.result.messageString.should.endWith(`is instance of fluentasserts.operations.type.instanceOf.InstanceOfBaseClass.`);
  evaluation.result.expected[].should.equal("not typeof fluentasserts.operations.type.instanceOf.InstanceOfTestInterface");
  evaluation.result.actual[].should.equal("typeof fluentasserts.operations.type.instanceOf.InstanceOfBaseClass");
}