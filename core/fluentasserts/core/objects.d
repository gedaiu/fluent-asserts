module fluentasserts.core.objects;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.stdio;
import std.traits;

struct ShouldObject(T) {
  private const T testData;

  mixin ShouldCommons;

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

  msg.writeln("$$$$$$");

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
