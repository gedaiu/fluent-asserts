module fluentasserts.core.callable;

public import fluentasserts.core.base;
import std.string;
import std.datetime;

struct ShouldCallable(T) {
  private T callable;
  mixin ShouldCommons;

  auto haveExecutionTime(string file = __FILE__, size_t line = __LINE__) {
    auto begin = Clock.currTime;
    callable();

    auto tmpShould = should(Clock.currTime - begin).forceMessage(" have execution time");

    return tmpShould;
  }

  Throwable throwAnyException(string file = __FILE__, size_t line = __LINE__) {
    addMessage(" throw ");
    addValue("any exception");
    beginCheck;

    return throwException!Exception(file, line);
  }

  Throwable throwException(T)(string file = __FILE__, size_t line = __LINE__) {
    Throwable t;
    addMessage(" throw a `");
    addValue(T.stringof);
    addMessage("` exception");

    try {
      try {
        callable();
      } catch(T e) {
        t = e;
      }
    } catch(Throwable th) {
      t = th;
    }

    auto hasException = t !is null;
    Message[] msg;

    if(hasException) {
      msg = [
        Message(false, "Got invalid exception type: `"),
        Message(true, t.msg),
        Message(false, "`")
       ];
    }

    simpleResult(hasException, msg , file, line);

    return t;
  }
}

@("Should be able to catch any exception")
unittest
{
  ({
    throw new Exception("test");
  }).should.throwAnyException.msg.should.equal("test");
}

@("Should be able to catch a certain exception")
unittest
{
  class CustomException : Exception {
    this(string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
    }
  }

  ({
    throw new CustomException("test");
  }).should.throwException!CustomException.msg.should.equal("test");
}

@("Should fail if an exception is not thrown")
unittest
{
  auto thrown = false;
  try {
    ({  }).should.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[0].should.contain(" should throw any exception.");
  }

  thrown.should.equal(true);
}

@("Should fail if an exception is not expected")
unittest
{
  auto thrown = false;
  try {
    ({
      throw new Exception("test");
    }).should.not.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[0].should.contain(" should not throw any exception.");
  }

  thrown.should.equal(true);
}

@("Should be able to benchmark some code")
unittest
{
  ({

  }).should.haveExecutionTime.lessThan(1.seconds);
}

@("Should fail on benchmark timeout")
unittest
{
  import core.thread;

  TestException exception = null;

  try {
    ({
      Thread.sleep(2.msecs);
    }).should.haveExecutionTime.lessThan(1.msecs);
  } catch(TestException e) {
    exception = e;
  }

  exception.should.not.beNull.because("we wait 2 seconds");
  exception.msg.split("\n")[0].should.startWith("}) should have execution time less than `1 ms`.");
}