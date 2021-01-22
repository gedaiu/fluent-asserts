module fluentasserts.core.callable;

public import fluentasserts.core.base;
import std.string;
import std.datetime;
import std.conv;
import std.traits;

import fluentasserts.core.results;

@safe:
///
struct ShouldCallable(T) {
  private {
    T callable;
  }

  mixin ShouldCommons;
  mixin ShouldThrowableCommons;

  ///
  this(lazy T callable) {
    auto result = callable.evaluate;

    valueEvaluation = result.evaluation;
    this.callable = result.value;
  }

  ///
  auto haveExecutionTime(string file = __FILE__, size_t line = __LINE__) {
    validateException;

    auto tmpShould = ShouldBaseType!Duration(evaluate(valueEvaluation.duration)).forceMessage(" have execution time");

    return tmpShould;
  }

  ///
  auto beNull(string file = __FILE__, size_t line = __LINE__) {
    validateException;

    addMessage(" be ");
    addValue("null");
    beginCheck;

    bool isNull = callable is null;

    string expected;

    static if(isDelegate!callable) {
      string actual = callable.ptr.to!string;
    } else {
      string actual = (cast(void*)callable).to!string;
    }

    if(expectedValue) {
      expected = "null";
    } else {
      expected = "not null";
    }

    return result(isNull, [], new ExpectedActualResult(expected, actual), file, line);
  }
}

/// Should be able to catch any exception
unittest {
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

/// Should be able to use with message without a custom assert
unittest {
  ({
    assert(false, "test");
  }).should.throwSomething.withMessage("test");
}

/// Should be able to catch a certain exception type
unittest {
  class CustomException : Exception {
    this(string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
    }
  }

  ({
    throw new CustomException("test");
  }).should.throwException!CustomException.withMessage("test");

  bool hasException;
  try {
    ({
      throw new Exception("test");
    }).should.throwException!CustomException.withMessage("test");
  } catch(TestException t) {
    hasException = true;
    t.msg.should.contain("    }) should throw exception with message equal \"test\". `object.Exception` saying `test` was thrown.");
  }
  hasException.should.equal(true).because("we want to catch a CustomException not an Exception");
}

/// Should be able to retrieve a typed version of a custom exception
unittest {
  class CustomException : Exception {
    int data;
    this(int data, string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);

      this.data = data;
    }
  }

  auto thrown = ({
    throw new CustomException(2, "test");
  }).should.throwException!CustomException.thrown;

  thrown.should.not.beNull;
  thrown.msg.should.equal("test");
  (cast(CustomException) thrown).data.should.equal(2);
}

/// Should fail if an exception is not thrown
unittest {
  auto thrown = false;
  try {
    ({  }).should.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[0].should.equal("({  }) should throw any exception. No exception was thrown.");
  }

  thrown.should.equal(true);
}

/// Should fail if an exception is not expected
unittest {
  auto thrown = false;
  try {
    ({
      throw new Exception("test");
    }).should.not.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[2].should.equal("    }) should not throw any exception. `object.Exception` saying `test` was thrown.");
  }

  thrown.should.equal(true);
}

/// Should be able to benchmark some code
unittest {
  ({

  }).should.haveExecutionTime.lessThan(1.seconds);
}

/// Should fail on benchmark timeout
unittest {
  import core.thread;

  TestException exception = null;

  try {
    ({
      Thread.sleep(2.msecs);
    }).should.haveExecutionTime.lessThan(1.msecs);
  } catch(TestException e) {
    exception = e;
  }

  exception.should.not.beNull.because("we wait 20 milliseconds");
  exception.msg.should.startWith("({\n      Thread.sleep(2.msecs);\n    }) should have execution time less than 1 ms.");
}

/// It should check if a delegate is null
unittest {
  void delegate() action;
  action.should.beNull;

  ({ }).should.not.beNull;

  auto msg = ({
    action.should.not.beNull;
  }).should.throwException!TestException.msg;

  msg.should.startWith("action should not be null.");
  msg.should.contain("Expected:not null");
  msg.should.contain("Actual:null");

  msg = ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

  msg.should.startWith("({ }) should be null.");
  msg.should.contain("Expected:null\n");
  msg.should.not.contain("Actual:null\n");
}
