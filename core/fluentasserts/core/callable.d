module fluentasserts.core.callable;

public import fluentasserts.core.base;
import std.string;
import std.datetime;
import std.conv;

struct ThrowableProxy(T : Throwable) {
  import fluentasserts.core.results;

  private const {
    bool expectedValue;
    bool rightType;
    const string _file;
    size_t _line;
  }

  private {
    Message[] messages;
    string reason;
    bool check;
    T t;
  }

  this(T t, bool expectedValue, bool rightType, Message[] messages, const string file, size_t line) {
    this.expectedValue = expectedValue;
    this._file = file;
    this._line = line;
    this.t = t;
    this.messages = messages;
    this.check = true;
    this.rightType = rightType;
  }

  ~this() {
    checkException;
  }

  auto msg() {
    checkException;
    check = false;

    return t.msg.dup.to!string;
  }

  auto original() {
    checkException;
    check = false;

    return t;
  }

  auto file() {
    checkException;
    check = false;

    return t.file;
  }

  auto info() {
    checkException;
    check = false;

    return t.info;
  }

  auto line() {
    checkException;
    check = false;

    return t.line;
  }

  auto next() {
    checkException;
    check = false;

    return t.next;
  }

  auto withMessage() {
    auto s = ShouldString(msg);
    check = false;

    return s.forceMessage(messages ~ Message(false, " with message"));
  }

  private void checkException() {
    if(!check) {
      return;
    }

    bool hasException = t !is null;

    if(hasException == expectedValue && rightType) {
      return;
    }

    auto sourceResult = new SourceResult(_file, _line);

    auto message = new MessageResult("");

    if(reason != "") {
      message.addText("Because " ~ reason ~ ", ");
    }

    message.addText(sourceResult.getValue ~ " should");

    foreach(msg; messages) {
      if(msg.isValue) {
        message.addValue(msg.text);
      } else {
        message.addText(msg.text);
      }
    }

    message.addText(".");

    if(t is null) {
      message.addText(" Nothing was thrown.");
    } else {
      message.addText(" An exception of type `");
      message.addValue(t.classinfo.name);
      message.addText("` saying `");
      message.addValue(t.msg);
      message.addText("` was thrown.");
    }

    throw new TestException([ cast(IResult) message ], _file, _line);
  }

  void because(string reason) {
    this.reason = reason;
  }
}

struct ShouldCallable(T) {
  private T callable;
  mixin ShouldCommons;

  auto haveExecutionTime(string file = __FILE__, size_t line = __LINE__) {
    auto begin = Clock.currTime;
    callable();

    auto tmpShould = ShouldBaseType!Duration(Clock.currTime - begin).forceMessage(" have execution time");

    return tmpShould;
  }

  auto throwAnyException(string file = __FILE__, size_t line = __LINE__) {
    addMessage(" throw ");
    addValue("any exception");
    beginCheck;

    return throwException!Exception(file, line);
  }

  auto throwSomething(string file = __FILE__, size_t line = __LINE__) {
    addMessage(" throw ");
    addValue("something");
    beginCheck;

    return throwException!Throwable(file, line);
  }

  ThrowableProxy throwException(T)(string file = __FILE__, size_t line = __LINE__) {
    Throwable t;
    bool rightType = true;
    addMessage(" throw a `");
    addValue(T.stringof);
    addMessage("`");

    try {
      try {
        callable();
      } catch(T e) {
        t = e;
      }
    } catch(Throwable th) {
      t = th;
      rightType = false;
    }

    return ThrowableProxy!T(t, expectedValue, rightType, messages, file, line);
  }
}

/// Should be able to catch any exception
unittest
{
  ({
    throw new Exception("test");
  }).should.throwAnyException.msg.should.equal("test");
}

/// Should be able to catch any assert
unittest {
  ({
    assert(false, "test");
  }).should.throwSomething.withMessage.equal("test");
}

/// Should be able to catch a certain exception type
unittest
{
  class CustomException : Exception {
    this(string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
    }
  }

  ({
    throw new CustomException("test");
  }).should.throwException!CustomException.withMessage.equal("test");


  bool hasException;
  try {
    ({
      throw new Exception("test");
    }).should.throwException!CustomException.withMessage.equal("test");
  } catch(TestException t) {
    hasException = true;
    t.msg.split("\n")[0].should.equal("}) should throw a `CustomException`. An exception of type `object.Exception` saying `test` was thrown.");
  }

  hasException.should.equal(true).because("we want to catch a CustomException not an Exception");
}

/// Should print a nice message for exception message asserts
unittest
{
  class CustomException : Exception {
    this(string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
    }
  }

  Throwable t;

  try {
    ({
      throw new CustomException("test");
    }).should.throwException!CustomException.withMessage.equal("other");
  } catch(Throwable e) {
    t = e;
  }

  t.should.not.beNull;
  t.msg.split("\n")[0].should.equal("}) should throw a `CustomException` with message equal `other`. `test` is not equal to `other`.");
}

/// Should fail if an exception is not thrown
unittest
{
  auto thrown = false;
  try {
    ({  }).should.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[0].should.equal("  }) should throw any exception. Nothing was thrown.");
  }

  thrown.should.equal(true);
}

/// Should fail if an exception is not expected
unittest
{
  auto thrown = false;
  try {
    ({
      throw new Exception("test");
    }).should.not.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[0].should.equal("}) should not throw any exception. An exception of type `object.Exception` saying `test` was thrown.");
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
