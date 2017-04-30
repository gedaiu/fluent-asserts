module fluentasserts.core.callable;

public import fluentasserts.core.base;

struct ShouldCallable(T) {
  private T callable;
  mixin ShouldCommons;

  Throwable throwAnyException(string file = __FILE__, size_t line = __LINE__) {
    addMessage("throw any exception");
    beginCheck;

    return throwException!Exception;
  }

  Throwable throwException(T)(string file = __FILE__, size_t line = __LINE__) {
    Throwable t;
    addMessage("throw a `" ~ T.stringof ~ "` exception");

    try {
      try {
        callable();
      } catch(T e) {
        t = e;
      }
    } catch(Throwable t) {
      result(false, "Got invalid exception type: `" ~ t.msg ~ "`", file, line);
    }

    auto hasException = t !is null;

    result(hasException, "", file, line);

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
    e.msg.should.startWith(" should throw any exception.");
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
    e.msg.should.startWith(" should not throw any exception.");
  }

  thrown.should.equal(true);
}
