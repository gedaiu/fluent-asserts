module fluentasserts.core.operations.throwable;

public import fluentasserts.core.base;
import fluentasserts.core.results;
import fluentasserts.core.lifecycle;
import fluentasserts.core.expect;
import fluentasserts.core.serializers;

import std.string;
import std.conv;
import std.algorithm;
import std.array;

static immutable throwAnyDescription = "Tests that the tested callable throws an exception.";

version(unittest) {
  class CustomException : Exception {
    this(string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
    }
  }
}

///
IResult[] throwAnyException(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results;

  evaluation.message.addText(". ");
  auto thrown = evaluation.currentValue.throwable;

  if(evaluation.currentValue.throwable && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("No exception to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.message.addText("No exception was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "Nothing was thrown"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("A `Throwable` saying `" ~ message ~ "` was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "A `Throwable` with message `" ~ message ~ "` was thrown"); catch(Exception) {}
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  return results;
}

/// It should be successfull when the function does not throw
unittest {
  void test() {}
  expect({ test(); }).to.not.throwAnyException();
}

/// It should fail when an exception is thrown and none is expected
unittest {
  void test() { throw new Exception("Test exception"); }

  bool thrown;

  try {
    expect({ test(); }).to.not.throwAnyException();
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should not throw any exception. `object.Exception` saying `Test exception` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:No exception to be thrown\n") != -1);
    assert(e.message.indexOf("\n   Actual:`object.Exception` saying `Test exception`\n") != -1);
  }

  assert(thrown, "The exception was not thrown");
}

/// It should be successfull when the function throws an expected exception
unittest {
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

/// It should not be successfull when the function throws a throwable and an exception is expected
unittest {
  void test() { assert(false); }

  bool thrown;

  try {
    expect({ test(); }).to.throwAnyException;
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should throw any exception.") != -1, "Message was: " ~ e.message);
    assert(e.message.indexOf("A `Throwable` saying `Assertion failure` was thrown.") != -1, "Message was: " ~ e.message);
    assert(e.message.indexOf("\n Expected:Any exception to be thrown\n") != -1, "Message was: " ~ e.message);
    assert(e.message.indexOf("\n   Actual:A `Throwable` with message `Assertion failure` was thrown\n") != -1, "Message was: " ~ e.message);
    assert(e.file == "source/fluentasserts/core/operations/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

/// It should be successfull when the function throws an expected exception
unittest {
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

IResult[] throwAnyExceptionWithMessage(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results;

  auto thrown = evaluation.currentValue.throwable;


  if(thrown !is null && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("No exception to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(thrown is null && !evaluation.isNegated) {
    evaluation.message.addText("Nothing was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "Nothing was thrown"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText(". A `Throwable` saying `" ~ message ~ "` was thrown.");

    try results ~= new ExpectedActualResult("Any throwable with the message `" ~ message ~ "` to be thrown", "A `" ~ thrown.classinfo.name ~ "` with message `" ~ message ~ "` was thrown"); catch(Exception) {}
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  return results;
}

/// throwSomething - accepts any Throwable including Error/AssertError
IResult[] throwSomething(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results;

  evaluation.message.addText(". ");
  auto thrown = evaluation.currentValue.throwable;

  if (thrown && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch (Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("No throwable to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch (Exception) {}
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.message.addText("Nothing was thrown.");

    try results ~= new ExpectedActualResult("Any throwable to be thrown", "Nothing was thrown"); catch (Exception) {}
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  return results;
}

/// throwSomethingWithMessage - accepts any Throwable including Error/AssertError
IResult[] throwSomethingWithMessage(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results;

  auto thrown = evaluation.currentValue.throwable;

  if (thrown !is null && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch (Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("No throwable to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch (Exception) {}
  }

  if (thrown is null && !evaluation.isNegated) {
    evaluation.message.addText("Nothing was thrown.");

    try results ~= new ExpectedActualResult("Any throwable to be thrown", "Nothing was thrown"); catch (Exception) {}
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  return results;
}

///
IResult[] throwException(ref Evaluation evaluation) @trusted nothrow {
  evaluation.message.addText(".");

  string exceptionType;

  if("exceptionType" in evaluation.expectedValue.meta) {
    exceptionType = evaluation.expectedValue.meta["exceptionType"].cleanString;
  }

  IResult[] results;
  auto thrown = evaluation.currentValue.throwable;

  if(thrown && evaluation.isNegated && thrown.classinfo.name == exceptionType) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("no `" ~ exceptionType ~ "` to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && thrown.classinfo.name != exceptionType) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult(exceptionType, "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.message.addText(" No exception was thrown.");

    try results ~= new ExpectedActualResult("`" ~ exceptionType ~ "` to be thrown", "Nothing was thrown"); catch(Exception) {}
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  return results;
}

/// Should be able to catch a certain exception type
unittest {
  expect({
    throw new CustomException("test");
  }).to.throwException!CustomException;
}

/// It fails when no exception is thrown but one is expected
unittest {
  bool thrown;

  try {
    ({}).should.throwException!Exception;
  } catch (TestException e) {
    thrown = true;
  }

  assert(thrown, "The test should have failed because no exception was thrown");
}

/// It should fail when an unexpected exception is thrown
unittest {
  bool thrown;

  try {
    expect({
      throw new Exception("test");
    }).to.throwException!CustomException;
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should throw exception \"fluentasserts.core.operations.throwable.CustomException\".`object.Exception` saying `test` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:fluentasserts.core.operations.throwable.CustomException\n") != -1);
    assert(e.message.indexOf("\n   Actual:`object.Exception` saying `test`\n") != -1);
    assert(e.file == "source/fluentasserts/core/operations/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

/// It should not fail when an exception is thrown and it is not expected
unittest {
  expect({
    throw new Exception("test");
  }).to.not.throwException!CustomException;
}

/// It should fail when an different exception than the one checked is thrown
unittest {
  bool thrown;

  try {
    expect({
      throw new CustomException("test");
    }).to.not.throwException!CustomException;
  } catch(TestException e) {
    thrown = true;
    assert(e.message.indexOf("should not throw exception \"fluentasserts.core.operations.throwable.CustomException\".`fluentasserts.core.operations.throwable.CustomException` saying `test` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:no `fluentasserts.core.operations.throwable.CustomException` to be thrown\n") != -1);
    assert(e.message.indexOf("\n   Actual:`fluentasserts.core.operations.throwable.CustomException` saying `test`\n") != -1);
    assert(e.file == "source/fluentasserts/core/operations/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

///
IResult[] throwExceptionWithMessage(ref Evaluation evaluation) @trusted nothrow {
  import std.stdio;


  evaluation.message.addText(". ");

  string exceptionType;
  string message;
  string expectedMessage = evaluation.expectedValue.strValue;

  if(expectedMessage.startsWith(`"`)) {
    expectedMessage = expectedMessage[1..$-1];
  }

  if("exceptionType" in evaluation.expectedValue.meta) {
    exceptionType = evaluation.expectedValue.meta["exceptionType"].cleanString;
  }

  IResult[] results;
  auto thrown = evaluation.currentValue.throwable;
  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  if(thrown) {
    try message = thrown.message.to!string; catch(Exception) {}
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.message.addText("No exception was thrown.");

    try results ~= new ExpectedActualResult("`" ~ exceptionType ~ "` with message `" ~ expectedMessage ~ "` to be thrown", "nothing was thrown"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && thrown.classinfo.name != exceptionType) {
    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("`" ~ exceptionType ~ "` to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && thrown.classinfo.name == exceptionType && message != expectedMessage) {
    evaluation.message.addText("`");
    evaluation.message.addValue(thrown.classinfo.name);
    evaluation.message.addText("` saying `");
    evaluation.message.addValue(message);
    evaluation.message.addText("` was thrown.");

    try results ~= new ExpectedActualResult("`" ~ exceptionType ~ "` saying `" ~ message ~ "` to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  return results;
}

/// It fails when an exception is not catched
unittest {
  Exception exception;

  try {
    expect({}).to.throwException!Exception.withMessage.equal("test");
  } catch(Exception e) {
    exception = e;
  }

  assert(exception !is null);
  assert(exception.message.indexOf("should throw exception") != -1);
  assert(exception.message.indexOf("with message equal \"test\"") != -1);
  assert(exception.message.indexOf("No exception was thrown.") != -1);
}

/// It does not fail when an exception is not expected and none is not catched
unittest {
  Exception exception;

  try {
    expect({}).not.to.throwException!Exception.withMessage.equal("test");
  } catch(Exception e) {
    exception = e;
  }

  assert(exception is null);
}

/// It fails when the caught exception has a different type
unittest {
  Exception exception;

  try {
    expect({
      throw new CustomException("hello");
    }).to.throwException!Exception.withMessage.equal("test");
  } catch(Exception e) {
    exception = e;
  }

  assert(exception !is null);
  assert(exception.message.indexOf("should throw exception") != -1);
  assert(exception.message.indexOf("with message equal \"test\"") != -1);
  assert(exception.message.indexOf("`fluentasserts.core.operations.throwable.CustomException` saying `hello` was thrown.") != -1);
}

/// It does not fail when a certain exception type is not catched
unittest {
  Exception exception;

  try {
    expect({
      throw new CustomException("hello");
    }).not.to.throwException!Exception.withMessage.equal("test");
  } catch(Exception e) {
    exception = e;
  }

  assert(exception is null);
}

/// It fails when the caught exception has a different message
unittest {
  Exception exception;

  try {
    expect({
      throw new CustomException("hello");
    }).to.throwException!CustomException.withMessage.equal("test");
  } catch(Exception e) {
    exception = e;
  }

  assert(exception !is null);
  assert(exception.message.indexOf("should throw exception") != -1);
  assert(exception.message.indexOf("with message equal \"test\"") != -1);
  assert(exception.message.indexOf("`fluentasserts.core.operations.throwable.CustomException` saying `hello` was thrown.") != -1);
}

/// It does not fails when the caught exception is expected to have a different message
unittest {
  Exception exception;

  try {
    expect({
      throw new CustomException("hello");
    }).not.to.throwException!CustomException.withMessage.equal("test");
  } catch(Exception e) {
    exception = e;
  }

  assert(exception is null);
}
