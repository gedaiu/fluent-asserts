module fluentasserts.operations.equality.equal;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation;

import fluentasserts.core.lifecycle;
import fluentasserts.results.message;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.expect;
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

///
void equal(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.add(endSentence);

  bool isEqual = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;

  if(!isEqual && evaluation.currentValue.proxyValue !is null && evaluation.expectedValue.proxyValue !is null) {
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

  if(evaluation.currentValue.typeName != "bool") {
    evaluation.result.add(Message(Message.Type.value, evaluation.currentValue.strValue));

    if(evaluation.isNegated) {
      evaluation.result.add(isEqualTo);
    } else {
      evaluation.result.add(isNotEqualTo);
    }

    evaluation.result.add(Message(Message.Type.value, evaluation.expectedValue.strValue));
    evaluation.result.add(endSentence);

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

  @(Type.stringof ~ " throws exception when strings are not equal")
  unittest {
    auto msg = ({
      expect("test string").to.equal("test");
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].strip.should.equal(`"test string" should equal "test". "test string" is not equal to "test".`);
  }

  @(Type.stringof ~ " throws exception when strings unexpectedly equal")
  unittest {
    auto msg = ({
      expect("test string").to.not.equal("test string");
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].strip.should.equal(`"test string" should not equal "test string". "test string" is equal to "test string".`);
  }

  @(Type.stringof ~ " shows null chars in detailed message")
  unittest {
    auto msg = ({
      ubyte[] data = [115, 111, 109, 101, 32, 100, 97, 116, 97, 0, 0];
      expect(data.assumeUTF.to!Type).to.equal("some data");
    }).should.throwException!TestException.msg;

    msg.should.contain(`Actual:"some data\0\0"`);
    msg.should.contain(`some data[+\0\0]`);
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

  @(Type.stringof ~ " throws exception when values are not equal")
  unittest {
    Type testValue = cast(Type) 40;
    Type otherTestValue = cast(Type) 50;
    auto msg = ({
      expect(testValue).to.equal(otherTestValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].strip.should.equal(testValue.to!string ~ ` should equal ` ~ otherTestValue.to!string ~ `. ` ~ testValue.to!string ~ ` is not equal to ` ~ otherTestValue.to!string ~ `.`);
  }

  @(Type.stringof ~ " throws exception when values unexpectedly equal")
  unittest {
    Type testValue = cast(Type) 40;
    auto msg = ({
      expect(testValue).to.not.equal(testValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].strip.should.equal(testValue.to!string ~ ` should not equal ` ~ testValue.to!string ~ `. ` ~ testValue.to!string ~ ` is equal to ` ~ testValue.to!string ~ `.`);
  }
}

@("booleans compares two true values")
unittest {
  expect(true).to.equal(true);
}

@("booleans compares two false values")
unittest {
  expect(false).to.equal(false);
}

@("booleans compares that two bools are not equal")
unittest {
  expect(true).to.not.equal(false);
  expect(false).to.not.equal(true);
}

@("booleans throws detailed error when not equal")
unittest {
  auto msg = ({
    expect(true).to.equal(false);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.equal("true should equal false.");
  msg[1].strip.should.equal("Expected:false");
  msg[2].strip.should.equal("Actual:true");
}

@("durations compares two equal values")
unittest {
  expect(2.seconds).to.equal(2.seconds);
}

@("durations compares that two durations are not equal")
unittest {
  expect(2.seconds).to.not.equal(3.seconds);
  expect(3.seconds).to.not.equal(2.seconds);
}

@("durations throws detailed error when not equal")
unittest {
  auto msg = ({
    expect(3.seconds).to.equal(2.seconds);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.equal("3 secs should equal 2 secs. 3000000000 is not equal to 2000000000.");
}

@("objects without custom opEquals compares two exact values")
unittest {
  Object testValue = new Object();
  expect(testValue).to.equal(testValue);
}

@("objects without custom opEquals checks if two values are not equal")
unittest {
  Object testValue = new Object();
  Object otherTestValue = new Object();
  expect(testValue).to.not.equal(otherTestValue);
}

@("objects without custom opEquals throws exception when not equal")
unittest {
  Object testValue = new Object();
  Object otherTestValue = new Object();
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  auto msg = ({
    expect(testValue).to.equal(otherTestValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal(niceTestValue.to!string ~ ` should equal ` ~ niceOtherTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is not equal to ` ~ niceOtherTestValue.to!string ~ `.`);
}

@("objects without custom opEquals throws exception when unexpectedly equal")
unittest {
  Object testValue = new Object();
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  auto msg = ({
    expect(testValue).to.not.equal(testValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal(niceTestValue.to!string ~ ` should not equal ` ~ niceTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is equal to ` ~ niceTestValue.to!string ~ `.`);
}

@("objects with custom opEquals compares two exact values")
unittest {
  auto testValue = new EqualThing(1);
  expect(testValue).to.equal(testValue);
}

@("objects with custom opEquals compares two objects with same fields")
unittest {
  auto testValue = new EqualThing(1);
  auto sameTestValue = new EqualThing(1);
  expect(testValue).to.equal(sameTestValue);
  expect(testValue).to.equal(cast(Object) sameTestValue);
}

@("objects with custom opEquals checks if two values are not equal")
unittest {
  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);
  expect(testValue).to.not.equal(otherTestValue);
}

@("objects with custom opEquals throws exception when not equal")
unittest {
  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  auto msg = ({
    expect(testValue).to.equal(otherTestValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal(niceTestValue.to!string ~ ` should equal ` ~ niceOtherTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is not equal to ` ~ niceOtherTestValue.to!string ~ `.`);
}

@("objects with custom opEquals throws exception when unexpectedly equal")
unittest {
  auto testValue = new EqualThing(1);
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  auto msg = ({
    expect(testValue).to.not.equal(testValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal(niceTestValue.to!string ~ ` should not equal ` ~ niceTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is equal to ` ~ niceTestValue.to!string ~ `.`);
}

@("assoc arrays compares two exact values")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  expect(testValue).to.equal(testValue);
}

@("assoc arrays compares two objects with same fields")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] sameTestValue = ["a": "1", "b": "2", "c": "3"];
  expect(testValue).to.equal(sameTestValue);
}

@("assoc arrays checks if two values are not equal")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];
  expect(testValue).to.not.equal(otherTestValue);
}

@("assoc arrays throws exception when not equal")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);
  string niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);

  auto msg = ({
    expect(testValue).to.equal(otherTestValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should equal ` ~ niceOtherTestValue.to!string ~ `.`);
}

@("assoc arrays throws exception when unexpectedly equal")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string niceTestValue = SerializerRegistry.instance.niceValue(testValue);

  auto msg = ({
    expect(testValue).to.not.equal(testValue);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should not equal ` ~ niceTestValue.to!string ~ `.`);
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
