module fluentasserts.core.objects;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.stdio;
import std.traits;

struct ShouldObject(T) {
  private {
    T testData;
    ValueEvaluation valueEvaluation;
  }

  mixin ShouldCommons;
  mixin ShouldThrowableCommons;

  this(U)(U value) {
    this.valueEvaluation = value.evaluation;
    this.testData = value.value;
  }

  auto beNull(const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" be ");
    addValue("null");
    beginCheck;

    if(expectedValue) {
      return result(testData is null, cast(IResult) new ExpectedActualResult("null", "a `" ~ T.stringof ~ "` instance"), file, line);
    } else {
      return result(testData is null, cast(IResult) new ExpectedActualResult("a `" ~ T.stringof ~ "` instance", "null"), file, line);
    }
  }

  auto instanceOf(U)(const string file = __FILE__, const size_t line = __LINE__) {
    addValue(" instance of `" ~ U.stringof ~ "`");
    beginCheck;

    U castedObject = cast(U) testData;

    return result(castedObject !is null,
    cast(IResult) new ExpectedActualResult(( expectedValue ? "" : "not " ) ~ "a `" ~ U.stringof ~ "` instance",
                                           "a `" ~ T.stringof ~ "` instance"),
                                           file, line);
  }

  auto equal(U)(U instance, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" equal ");
    addValue("`" ~ U.stringof ~ "`");
    beginCheck;

    return result(testData == instance, [] ,
      cast(IResult) new ExpectedActualResult(( expectedValue ? "" : "not " ) ~ instance.toString, testData.toString), file, line);
  }
}

/// object beNull
unittest {
  Object o = null;

  ({
    o.should.beNull;
    (new Object).should.not.beNull;
  }).should.not.throwAnyException;

  auto msg = ({
    o.should.not.beNull;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("o should not be null.");
  msg.split("\n")[2].strip.should.equal("Expected:a `Object` instance");
  msg.split("\n")[3].strip.should.equal("Actual:null");

  msg = ({
    (new Object).should.beNull;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("(new Object) should be null.");
  msg.split("\n")[2].strip.should.equal("Expected:null");
  msg.split("\n")[3].strip.strip.should.equal("Actual:a `Object` instance");
}

/// object instanceOf
unittest {
  class BaseClass { }
  class ExtendedClass : BaseClass { }
  class SomeClass { }
  class OtherClass { }

  auto someObject = new SomeClass;
  auto otherObject = new OtherClass;
  auto extendedObject = new ExtendedClass;

  someObject.should.be.instanceOf!SomeClass;
  extendedObject.should.be.instanceOf!BaseClass;

  someObject.should.not.be.instanceOf!OtherClass;
  someObject.should.not.be.instanceOf!BaseClass;

  auto msg = ({
    otherObject.should.be.instanceOf!SomeClass;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("otherObject should be instance of `SomeClass`.");
  msg.split("\n")[2].strip.should.equal("Expected:a `SomeClass` instance");
  msg.split("\n")[3].strip.should.equal("Actual:a `OtherClass` instance");

  msg = ({
    otherObject.should.not.be.instanceOf!OtherClass;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("otherObject should not be instance of `OtherClass`.");
  msg.split("\n")[2].strip.should.equal("Expected:not a `OtherClass` instance");
  msg.split("\n")[3].strip.should.equal("Actual:a `OtherClass` instance");
}


/// object instanceOf interface
unittest {
  interface MyInterface { }
  class BaseClass : MyInterface { }
  class OtherClass { }

  auto someObject = new BaseClass;
  auto otherObject = new OtherClass;

  someObject.should.be.instanceOf!MyInterface;

  auto msg = ({
    otherObject.should.be.instanceOf!MyInterface;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("otherObject should be instance of `MyInterface`.");
  msg.split("\n")[2].strip.should.equal("Expected:a `MyInterface` instance");
  msg.split("\n")[3].strip.should.equal("Actual:a `OtherClass` instance");

  msg = ({
    someObject.should.not.be.instanceOf!MyInterface;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("someObject should not be instance of `MyInterface`.");
  msg.split("\n")[2].strip.should.equal("Expected:not a `MyInterface` instance");
  msg.split("\n")[3].strip.should.equal("Actual:a `BaseClass` instance");
}

/// should throw exceptions for delegates that return basic types
unittest {
  class SomeClass { }

  SomeClass value() {
    throw new Exception("not implemented");
  }

  SomeClass noException() { return null; }

  value().should.throwAnyException.withMessage.equal("not implemented");

  bool thrown;

  try {
    noException.should.throwAnyException;
  } catch (TestException e) {
    e.msg.should.startWith("noException should throw any exception. Nothing was thrown.");
    thrown = true;
  }

  thrown.should.equal(true);
}

/// object equal
unittest {
  class TestEqual {
    private int value;

    this(int value) {
      this.value = value;
    }
  }

  auto instance = new TestEqual(1);

  instance.should.equal(instance);
  instance.should.not.equal(new TestEqual(1));

  auto msg = ({
    instance.should.not.equal(instance);
  }).should.throwException!TestException.msg;

  msg.should.startWith("instance should not equal `TestEqual`.");

  msg = ({
    instance.should.equal(new TestEqual(1));
  }).should.throwException!TestException.msg;

  msg.should.startWith("instance should equal `TestEqual`.");
}
