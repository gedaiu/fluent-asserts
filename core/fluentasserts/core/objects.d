module fluentasserts.core.objects;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.stdio;

struct ShouldObject(T) {
  private const T testData;

  mixin ShouldCommons;

  void beNull(const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("be null");
    beginCheck;

    if(expectedValue) {
      result(testData is null, cast(IResult) new ExpectedActualResult("null", "a `" ~ T.stringof ~ "` instance"), file, line);
    } else {
      result(testData is null, cast(IResult) new ExpectedActualResult("a `" ~ T.stringof ~ "` instance", "null"), file, line);
    }
  }
}

@("object beNull")
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
  msg.split("\n")[2].should.equal("Expected:a `Object` instance");
  msg.split("\n")[3].strip.should.equal("Actual:null");

  msg = ({
    (new Object).should.beNull;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("(new Object) should be null.");
  msg.split("\n")[2].should.equal("Expected:null");
  msg.split("\n")[3].strip.should.equal("Actual:a `Object` instance");
}