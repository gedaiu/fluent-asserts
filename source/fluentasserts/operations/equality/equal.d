module fluentasserts.operations.equality.equal;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import fluentasserts.results.message;

version (unittest) {
  import fluent.asserts;
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
static immutable endSentence = Message(Message.Type.info, ". ");

/// Asserts that the current value is strictly equal to the expected value.
void equal(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.add(endSentence);

  bool isEqual = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;

  auto hasCurrentProxy = evaluation.currentValue.proxyValue !is null;
  auto hasExpectedProxy = evaluation.expectedValue.proxyValue !is null;

  if(!isEqual && hasCurrentProxy && hasExpectedProxy) {
    isEqual = evaluation.currentValue.proxyValue.isEqualTo(evaluation.expectedValue.proxyValue);
  }

  if(evaluation.isNegated) {
    isEqual = !isEqual;
  }

  if(isEqual) {
    return;
  }

  evaluation.result.expected = evaluation.expectedValue.strValue;
  evaluation.result.actual = evaluation.currentValue.strValue;
  evaluation.result.negated = evaluation.isNegated;

  if(evaluation.isNegated) {
    evaluation.result.expected = "not " ~ evaluation.expectedValue.strValue;
  }

  if(evaluation.currentValue.typeName != "bool") {
    evaluation.result.computeDiff(evaluation.expectedValue.strValue, evaluation.currentValue.strValue);
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias StringTypes = AliasSeq!(string, wstring, dstring);

static foreach (Type; StringTypes) {
  @(Type.stringof ~ " compares two exact strings")
  unittest {
    expect("test string").to.equal("test string");
  }

  @(Type.stringof ~ " checks if two strings are not equal")
  unittest {
    expect("test string").to.not.equal("test");
  }

  @(Type.stringof ~ " test string equal test reports error with expected and actual")
  unittest {
    auto evaluation = ({
      expect("test string").to.equal("test");
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal(`"test"`);
    expect(evaluation.result.actual).to.equal(`"test string"`);
  }

  @(Type.stringof ~ " test string not equal test string reports error with expected and negated")
  unittest {
    auto evaluation = ({
      expect("test string").to.not.equal("test string");
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal(`not "test string"`);
    expect(evaluation.result.actual).to.equal(`"test string"`);
    expect(evaluation.result.negated).to.equal(true);
  }

  @(Type.stringof ~ " string with null chars equal string without null chars reports error with actual containing null chars")
  unittest {
    ubyte[] data = [115, 111, 109, 101, 32, 100, 97, 116, 97, 0, 0];

    auto evaluation = ({
      expect(data.assumeUTF.to!Type).to.equal("some data");
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal(`"some data"`);
    expect(evaluation.result.actual).to.equal("\"some data\0\0\"");
  }
}

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " compares two exact values")
  unittest {
    Type testValue = cast(Type) 40;
    expect(testValue).to.equal(testValue);
  }

  @(Type.stringof ~ " checks if two values are not equal")
  unittest {
    Type testValue = cast(Type) 40;
    Type otherTestValue = cast(Type) 50;
    expect(testValue).to.not.equal(otherTestValue);
  }

  @(Type.stringof ~ " 40 equal 50 reports error with expected and actual")
  unittest {
    Type testValue = cast(Type) 40;
    Type otherTestValue = cast(Type) 50;

    auto evaluation = ({
      expect(testValue).to.equal(otherTestValue);
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal(otherTestValue.to!string);
    expect(evaluation.result.actual).to.equal(testValue.to!string);
  }

  @(Type.stringof ~ " 40 not equal 40 reports error with expected and negated")
  unittest {
    Type testValue = cast(Type) 40;

    auto evaluation = ({
      expect(testValue).to.not.equal(testValue);
    }).recordEvaluation;

    expect(evaluation.result.expected).to.equal("not " ~ testValue.to!string);
    expect(evaluation.result.actual).to.equal(testValue.to!string);
    expect(evaluation.result.negated).to.equal(true);
  }
}

@("booleans compares two true values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect(true).to.equal(true);
}

@("booleans compares two false values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect(false).to.equal(false);
}

@("booleans compares that two bools are not equal")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect(true).to.not.equal(false);
  expect(false).to.not.equal(true);
}

@("true equal false reports error with expected false and actual true")
unittest {
  mixin(enableEvaluationRecording);

  expect(true).to.equal(false);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal("false");
  expect(evaluation.result.actual).to.equal("true");
}

@("durations compares two equal values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect(2.seconds).to.equal(2.seconds);
}

@("durations compares that two durations are not equal")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect(2.seconds).to.not.equal(3.seconds);
  expect(3.seconds).to.not.equal(2.seconds);
}

@("3 seconds equal 2 seconds reports error with expected and actual")
unittest {
  mixin(enableEvaluationRecording);

  expect(3.seconds).to.equal(2.seconds);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal("2000000000");
  expect(evaluation.result.actual).to.equal("3000000000");
}

@("objects without custom opEquals compares two exact values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Object testValue = new Object();
  expect(testValue).to.equal(testValue);
}

@("objects without custom opEquals checks if two values are not equal")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Object testValue = new Object();
  Object otherTestValue = new Object();
  expect(testValue).to.not.equal(otherTestValue);
}

@("object equal different object reports error with expected and actual")
unittest {
  mixin(enableEvaluationRecording);

  Object testValue = new Object();
  Object otherTestValue = new Object();
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  expect(testValue).to.equal(otherTestValue);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal(niceOtherTestValue);
  expect(evaluation.result.actual).to.equal(niceTestValue);
}

@("object not equal itself reports error with expected and negated")
unittest {
  mixin(enableEvaluationRecording);

  Object testValue = new Object();
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  expect(testValue).to.not.equal(testValue);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal("not " ~ niceTestValue);
  expect(evaluation.result.actual).to.equal(niceTestValue);
  expect(evaluation.result.negated).to.equal(true);
}

@("objects with custom opEquals compares two exact values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto testValue = new EqualThing(1);
  expect(testValue).to.equal(testValue);
}

@("objects with custom opEquals compares two objects with same fields")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto testValue = new EqualThing(1);
  auto sameTestValue = new EqualThing(1);
  expect(testValue).to.equal(sameTestValue);
  expect(testValue).to.equal(cast(Object) sameTestValue);
}

@("objects with custom opEquals checks if two values are not equal")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);
  expect(testValue).to.not.equal(otherTestValue);
}

@("EqualThing(1) equal EqualThing(2) reports error with expected and actual")
unittest {
  mixin(enableEvaluationRecording);

  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  expect(testValue).to.equal(otherTestValue);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal(niceOtherTestValue);
  expect(evaluation.result.actual).to.equal(niceTestValue);
}

@("EqualThing(1) not equal itself reports error with expected and negated")
unittest {
  mixin(enableEvaluationRecording);

  auto testValue = new EqualThing(1);
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  expect(testValue).to.not.equal(testValue);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal("not " ~ niceTestValue);
  expect(evaluation.result.actual).to.equal(niceTestValue);
  expect(evaluation.result.negated).to.equal(true);
}

@("assoc arrays compares two exact values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  expect(testValue).to.equal(testValue);
}

@("assoc arrays compares two objects with same fields")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] sameTestValue = ["a": "1", "b": "2", "c": "3"];
  expect(testValue).to.equal(sameTestValue);
}

@("assoc arrays checks if two values are not equal")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];
  expect(testValue).to.not.equal(otherTestValue);
}

@("assoc array equal different assoc array reports error with expected and actual")
unittest {
  mixin(enableEvaluationRecording);

  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  expect(testValue).to.equal(otherTestValue);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal(niceOtherTestValue);
  expect(evaluation.result.actual).to.equal(niceTestValue);
}

@("assoc array not equal itself reports error with expected and negated")
unittest {
  mixin(enableEvaluationRecording);

  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  expect(testValue).to.not.equal(testValue);

  auto evaluation = Lifecycle.instance.lastEvaluation;
  Lifecycle.instance.disableFailureHandling = false;
  expect(evaluation.result.expected).to.equal("not " ~ niceTestValue);
  expect(evaluation.result.actual).to.equal(niceTestValue);
  expect(evaluation.result.negated).to.equal(true);
}

version (unittest):
class EqualThing {
  int x;
  this(int x) {
    this.x = x;
  }

  override bool opEquals(Object o) {
    if (typeid(this) != typeid(o))
      return false;
    alias a = this;
    auto b = cast(typeof(this)) o;
    return a.x == b.x;
  }
}
