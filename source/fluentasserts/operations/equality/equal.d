module fluentasserts.operations.equality.equal;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;
import fluentasserts.core.memory.heapequable : objectEquals;

import fluentasserts.core.lifecycle;
import fluentasserts.results.message;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import fluentasserts.results.serializers;
  import std.conv;
  import std.datetime;
  import std.meta;
  import std.string;
}

static immutable equalDescription = "Asserts that the target is strictly == equal to the given val.";

static immutable isEqualTo = Message(Message.Type.info, " is equal to ");
static immutable isNotEqualTo = Message(Message.Type.info, " is not equal to ");
static immutable endSentence = Message(Message.Type.info, ".");

/// Asserts that the current value is strictly equal to the expected value.
/// Note: This function is not @nogc because it may use opEquals for object comparison.
void equal(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.add(endSentence);

  bool isEqual;

  // For objects, use opEquals for proper comparison (identity matters, not just string)
  if (evaluation.currentValue.objectRef !is null && evaluation.expectedValue.objectRef !is null) {
    isEqual = objectEquals(evaluation.currentValue.objectRef, evaluation.expectedValue.objectRef);
  } else {
    isEqual = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;
  }

  auto hasCurrentProxy = !evaluation.currentValue.proxyValue.isNull();
  auto hasExpectedProxy = !evaluation.expectedValue.proxyValue.isNull();

  if (!isEqual && hasCurrentProxy && hasExpectedProxy) {
    isEqual = evaluation.currentValue.proxyValue.isEqualTo(evaluation.expectedValue.proxyValue);
  }

  if (evaluation.isNegated) {
    isEqual = !isEqual;
  }

  if (isEqual) {
    return;
  }

  if (evaluation.isNegated) {
    evaluation.result.expected.put("not ");
  }
  evaluation.result.expected.put(evaluation.expectedValue.strValue[]);
  evaluation.result.actual.put(evaluation.currentValue.strValue[]);
  evaluation.result.negated = evaluation.isNegated;
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias StringTypes = AliasSeq!(string, wstring, dstring);

static foreach (Type; StringTypes) {
  @(Type.stringof ~ " compares two exact strings")
  unittest {
    auto evaluation = ({
      expect("test string").to.equal("test string");
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "equal operation should pass for identical strings");
  }

  @(Type.stringof ~ " checks if two strings are not equal")
  unittest {
    auto evaluation = ({
      expect("test string").to.not.equal("test");
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "not equal operation should pass for different strings");
  }

  @(Type.stringof ~ " test string equal test reports error with expected and actual")
  unittest {
    auto evaluation = ({
      expect("test string").to.equal("test");
    }).recordEvaluation;

    assert(evaluation.result.expected[] == `test`, "expected 'test' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == `test string`, "expected 'test string' but got: " ~ evaluation.result.actual[]);
  }

  @(Type.stringof ~ " test string not equal test string reports error with expected and negated")
  unittest {
    auto evaluation = ({
      expect("test string").to.not.equal("test string");
    }).recordEvaluation;

    assert(evaluation.result.expected[] == `not test string`, "expected 'not test string' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == `test string`, "expected 'test string' but got: " ~ evaluation.result.actual[]);
    assert(evaluation.result.negated == true, "expected negated to be true");
  }

  @(Type.stringof ~ " string with null chars equal string without null chars reports error with actual containing null chars")
  unittest {
    ubyte[] data = [115, 111, 109, 101, 32, 100, 97, 116, 97, 0, 0];

    auto evaluation = ({
      expect(data.assumeUTF.to!Type).to.equal("some data");
    }).recordEvaluation;

    assert(evaluation.result.expected[] == `some data`, "expected 'some data' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == `some data\0\0`, "expected 'some data\\0\\0' but got: " ~ evaluation.result.actual[]);
  }
}

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " compares two exact values")
  unittest {
    Type testValue = cast(Type) 40;

    auto evaluation = ({
      expect(testValue).to.equal(testValue);
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "equal operation should pass for identical values");
  }

  @(Type.stringof ~ " checks if two values are not equal")
  unittest {
    Type testValue = cast(Type) 40;
    Type otherTestValue = cast(Type) 50;

    auto evaluation = ({
      expect(testValue).to.not.equal(otherTestValue);
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "not equal operation should pass for different values");
  }

  @(Type.stringof ~ " 40 equal 50 reports error with expected and actual")
  unittest {
    Type testValue = cast(Type) 40;
    Type otherTestValue = cast(Type) 50;

    auto evaluation = ({
      expect(testValue).to.equal(otherTestValue);
    }).recordEvaluation;

    assert(evaluation.result.expected[] == otherTestValue.to!string, "expected '" ~ otherTestValue.to!string ~ "' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == testValue.to!string, "expected '" ~ testValue.to!string ~ "' but got: " ~ evaluation.result.actual[]);
  }

  @(Type.stringof ~ " 40 not equal 40 reports error with expected and negated")
  unittest {
    Type testValue = cast(Type) 40;

    auto evaluation = ({
      expect(testValue).to.not.equal(testValue);
    }).recordEvaluation;

    assert(evaluation.result.expected[] == "not " ~ testValue.to!string, "expected 'not " ~ testValue.to!string ~ "' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == testValue.to!string, "expected '" ~ testValue.to!string ~ "' but got: " ~ evaluation.result.actual[]);
    assert(evaluation.result.negated == true, "expected negated to be true");
  }
}

@("booleans compares two true values")
unittest {
  auto evaluation = ({
    expect(true).to.equal(true);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for true == true");
}

@("booleans compares two false values")
unittest {
  auto evaluation = ({
    expect(false).to.equal(false);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for false == false");
}

@("booleans true not equal false passes")
unittest {
  auto evaluation = ({
    expect(true).to.not.equal(false);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for true != false");
}

@("booleans false not equal true passes")
unittest {
  auto evaluation = ({
    expect(false).to.not.equal(true);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for false != true");
}

@("true equal false reports error with expected false and actual true")
unittest {
  auto evaluation = ({
    expect(true).to.equal(false);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "false", "expected 'false' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == "true", "expected 'true' but got: " ~ evaluation.result.actual[]);
}

@("durations compares two equal values")
unittest {
  auto evaluation = ({
    expect(2.seconds).to.equal(2.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for identical durations");
}

@("durations 2 seconds not equal 3 seconds passes")
unittest {
  auto evaluation = ({
    expect(2.seconds).to.not.equal(3.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for 2s != 3s");
}

@("durations 3 seconds not equal 2 seconds passes")
unittest {
  auto evaluation = ({
    expect(3.seconds).to.not.equal(2.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for 3s != 2s");
}

@("3 seconds equal 2 seconds reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect(3.seconds).to.equal(2.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "2000000000", "expected '2000000000' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == "3000000000", "expected '3000000000' but got: " ~ evaluation.result.actual[]);
}

@("objects without custom opEquals compares two exact values")
unittest {
  Object testValue = new Object();

  auto evaluation = ({
    expect(testValue).to.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for same object reference");
}

@("objects without custom opEquals checks if two values are not equal")
unittest {
  Object testValue = new Object();
  Object otherTestValue = new Object();

  auto evaluation = ({
    expect(testValue).to.not.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for different objects");
}

@("object equal different object reports error with expected and actual")
unittest {
  Object testValue = new Object();
  Object otherTestValue = new Object();
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  auto evaluation = ({
    expect(testValue).to.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == niceOtherTestValue, "expected '" ~ niceOtherTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
}

@("object not equal itself reports error with expected and negated")
unittest {
  Object testValue = new Object();
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  auto evaluation = ({
    expect(testValue).to.not.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "not " ~ niceTestValue, "expected 'not " ~ niceTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
  assert(evaluation.result.negated == true, "expected negated to be true");
}

@("objects with custom opEquals compares two exact values")
unittest {
  auto testValue = new EqualThing(1);

  auto evaluation = ({
    expect(testValue).to.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for same object reference");
}

@("objects with custom opEquals compares two objects with same fields")
unittest {
  auto testValue = new EqualThing(1);
  auto sameTestValue = new EqualThing(1);

  auto evaluation = ({
    expect(testValue).to.equal(sameTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for objects with same fields");
}

@("objects with custom opEquals compares object cast to Object with same fields")
unittest {
  auto testValue = new EqualThing(1);
  auto sameTestValue = new EqualThing(1);

  auto evaluation = ({
    expect(testValue).to.equal(cast(Object) sameTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for objects with same fields cast to Object");
}

@("objects with custom opEquals checks if two values are not equal")
unittest {
  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);

  auto evaluation = ({
    expect(testValue).to.not.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for objects with different fields");
}

@("EqualThing(1) equal EqualThing(2) reports error with expected and actual")
unittest {
  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  auto evaluation = ({
    expect(testValue).to.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == niceOtherTestValue, "expected '" ~ niceOtherTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
}

@("EqualThing(1) not equal itself reports error with expected and negated")
unittest {
  auto testValue = new EqualThing(1);
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  auto evaluation = ({
    expect(testValue).to.not.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "not " ~ niceTestValue, "expected 'not " ~ niceTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
  assert(evaluation.result.negated == true, "expected negated to be true");
}

@("assoc arrays compares two exact values")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];

  auto evaluation = ({
    expect(testValue).to.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for same assoc array reference");
}

@("assoc arrays compares two objects with same fields")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] sameTestValue = ["a": "1", "b": "2", "c": "3"];

  auto evaluation = ({
    expect(testValue).to.equal(sameTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for assoc arrays with same content");
}

@("assoc arrays checks if two values are not equal")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];

  auto evaluation = ({
    expect(testValue).to.not.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for assoc arrays with different content");
}

@("assoc array equal different assoc array reports error with expected and actual")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  auto evaluation = ({
    expect(testValue).to.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == niceOtherTestValue, "expected '" ~ niceOtherTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
}

@("assoc array not equal itself reports error with expected and negated")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  auto evaluation = ({
    expect(testValue).to.not.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "not " ~ niceTestValue, "expected 'not " ~ niceTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
  assert(evaluation.result.negated == true, "expected negated to be true");
}

@("lazy number throwing in equal propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int someLazyInt() {
    throw new Exception("This is it.");
  }

  ({
    someLazyInt.should.equal(3);
  }).should.throwAnyException.withMessage("This is it.");
}

@("const int equal int succeeds")
unittest {
  const actual = 42;
  actual.should.equal(42);
}

@("lazy string throwing in equal propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string someLazyString() {
    throw new Exception("This is it.");
  }

  ({
    someLazyString.should.equal("");
  }).should.throwAnyException.withMessage("This is it.");
}

@("const string equal string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const string constValue = "test string";
  constValue.should.equal("test string");
}

@("immutable string equal string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable string immutableValue = "test string";
  immutableValue.should.equal("test string");
}

@("string equal const string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const string constValue = "test string";
  "test string".should.equal(constValue);
}

@("string equal immutable string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable string immutableValue = "test string";
  "test string".should.equal(immutableValue);
}

@("lazy object throwing in equal propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Object someLazyObject() {
    throw new Exception("This is it.");
  }

  ({
    someLazyObject.should.equal(new Object);
  }).should.throwAnyException.withMessage("This is it.");
}

@("null object equals new object reports message starts with equal")
unittest {
  Object nullObject;

  auto evaluation = ({
    nullObject.should.equal(new Object);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("nullObject should equal Object(");
}

@("new object equals null reports message starts with equal null")
unittest {
  auto evaluation = ({
    (new Object).should.equal(null);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("(new Object) should equal null.");
}

version (unittest):
class EqualThing {
  int x;
  this(int x) {
    this.x = x;
  }

  override bool opEquals(Object o) @trusted nothrow @nogc {
    auto b = cast(typeof(this)) o;
    if (b is null) return false;
    return this.x == b.x;
  }
}
