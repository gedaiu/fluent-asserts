module fluentasserts.operations.exception.throwable;

public import fluentasserts.core.base;
import fluentasserts.results.printer;
import fluentasserts.core.lifecycle;
import fluentasserts.core.expect;
import fluentasserts.results.serializers;

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
void throwAnyException(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addText(". ");
  auto thrown = evaluation.currentValue.throwable;

  if(evaluation.currentValue.throwable && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = "No exception to be thrown";
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.result.addText("No exception was thrown.");

    evaluation.result.expected = "Any exception to be thrown";
    evaluation.result.actual = "Nothing was thrown";
  }

  if(thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.result.addText("A `Throwable` saying `" ~ message ~ "` was thrown.");

    evaluation.result.expected = "Any exception to be thrown";
    evaluation.result.actual = "A `Throwable` with message `" ~ message ~ "` was thrown";
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

@("it is successful when the function does not throw")
unittest {
  void test() {}
  expect({ test(); }).to.not.throwAnyException();
}

@("it fails when an exception is thrown and none is expected")
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

@("it is successful when the function throws an expected exception")
unittest {
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

@("it fails when the function throws a Throwable and an Exception is expected")
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
    assert(e.file == "source/fluentasserts/operations/exception/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

@("it is successful when the function throws any exception")
unittest {
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

void throwAnyExceptionWithMessage(ref Evaluation evaluation) @trusted nothrow {
  auto thrown = evaluation.currentValue.throwable;


  if(thrown !is null && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = "No exception to be thrown";
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }

  if(thrown is null && !evaluation.isNegated) {
    evaluation.result.addText("Nothing was thrown.");

    evaluation.result.expected = "Any exception to be thrown";
    evaluation.result.actual = "Nothing was thrown";
  }

  if(thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.result.addText(". A `Throwable` saying `" ~ message ~ "` was thrown.");

    evaluation.result.expected = "Any throwable with the message `" ~ message ~ "` to be thrown";
    evaluation.result.actual = "A `" ~ thrown.classinfo.name ~ "` with message `" ~ message ~ "` was thrown";
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

/// throwSomething - accepts any Throwable including Error/AssertError
void throwSomething(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addText(". ");
  auto thrown = evaluation.currentValue.throwable;

  if (thrown && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch (Exception) {}

    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = "No throwable to be thrown";
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.result.addText("Nothing was thrown.");

    evaluation.result.expected = "Any throwable to be thrown";
    evaluation.result.actual = "Nothing was thrown";
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

/// throwSomethingWithMessage - accepts any Throwable including Error/AssertError
void throwSomethingWithMessage(ref Evaluation evaluation) @trusted nothrow {
  auto thrown = evaluation.currentValue.throwable;

  if (thrown !is null && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch (Exception) {}

    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = "No throwable to be thrown";
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }

  if (thrown is null && !evaluation.isNegated) {
    evaluation.result.addText("Nothing was thrown.");

    evaluation.result.expected = "Any throwable to be thrown";
    evaluation.result.actual = "Nothing was thrown";
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

///
void throwException(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addText(".");

  string exceptionType;

  if("exceptionType" in evaluation.expectedValue.meta) {
    exceptionType = evaluation.expectedValue.meta["exceptionType"].cleanString;
  }

  auto thrown = evaluation.currentValue.throwable;

  if(thrown && evaluation.isNegated && thrown.classinfo.name == exceptionType) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = "no `" ~ exceptionType ~ "` to be thrown";
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }

  if(thrown && !evaluation.isNegated && thrown.classinfo.name != exceptionType) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = exceptionType;
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.result.addText(" No exception was thrown.");

    evaluation.result.expected = "`" ~ exceptionType ~ "` to be thrown";
    evaluation.result.actual = "Nothing was thrown";
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

@("catches a certain exception type")
unittest {
  expect({
    throw new CustomException("test");
  }).to.throwException!CustomException;
}

@("fails when no exception is thrown but one is expected")
unittest {
  bool thrown;

  try {
    ({}).should.throwException!Exception;
  } catch (TestException e) {
    thrown = true;
  }

  assert(thrown, "The test should have failed because no exception was thrown");
}

@("fails when an unexpected exception is thrown")
unittest {
  bool thrown;

  try {
    expect({
      throw new Exception("test");
    }).to.throwException!CustomException;
  } catch(TestException e) {
    thrown = true;

    assert(e.message.indexOf("should throw exception \"fluentasserts.operations.exception.throwable.CustomException\".`object.Exception` saying `test` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:fluentasserts.operations.exception.throwable.CustomException\n") != -1);
    assert(e.message.indexOf("\n   Actual:`object.Exception` saying `test`\n") != -1);
    assert(e.file == "source/fluentasserts/operations/exception/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

@("does not fail when an exception is thrown and it is not expected")
unittest {
  expect({
    throw new Exception("test");
  }).to.not.throwException!CustomException;
}

@("fails when the checked exception type is thrown but not expected")
unittest {
  bool thrown;

  try {
    expect({
      throw new CustomException("test");
    }).to.not.throwException!CustomException;
  } catch(TestException e) {
    thrown = true;
    assert(e.message.indexOf("should not throw exception \"fluentasserts.operations.exception.throwable.CustomException\".`fluentasserts.operations.exception.throwable.CustomException` saying `test` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:no `fluentasserts.operations.exception.throwable.CustomException` to be thrown\n") != -1);
    assert(e.message.indexOf("\n   Actual:`fluentasserts.operations.exception.throwable.CustomException` saying `test`\n") != -1);
    assert(e.file == "source/fluentasserts/operations/exception/throwable.d");
  }

  assert(thrown, "The exception was not thrown");
}

void throwExceptionWithMessage(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addText(". ");

  string exceptionType;
  string message;
  string expectedMessage = evaluation.expectedValue.strValue;

  if(expectedMessage.startsWith(`"`)) {
    expectedMessage = expectedMessage[1..$-1];
  }

  if("exceptionType" in evaluation.expectedValue.meta) {
    exceptionType = evaluation.expectedValue.meta["exceptionType"].cleanString;
  }

  auto thrown = evaluation.currentValue.throwable;
  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  if(thrown) {
    try message = thrown.message.to!string; catch(Exception) {}
  }

  if(!thrown && !evaluation.isNegated) {
    evaluation.result.addText("No exception was thrown.");

    evaluation.result.expected = "`" ~ exceptionType ~ "` with message `" ~ expectedMessage ~ "` to be thrown";
    evaluation.result.actual = "nothing was thrown";
  }

  if(thrown && !evaluation.isNegated && thrown.classinfo.name != exceptionType) {
    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = "`" ~ exceptionType ~ "` to be thrown";
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }

  if(thrown && !evaluation.isNegated && thrown.classinfo.name == exceptionType && message != expectedMessage) {
    evaluation.result.addText("`");
    evaluation.result.addValue(thrown.classinfo.name);
    evaluation.result.addText("` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");

    evaluation.result.expected = "`" ~ exceptionType ~ "` saying `" ~ message ~ "` to be thrown";
    evaluation.result.actual = "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`";
  }
}

@("fails when an exception is not caught")
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

@("does not fail when an exception is not expected and none is caught")
unittest {
  Exception exception;

  try {
    expect({}).not.to.throwException!Exception.withMessage.equal("test");
  } catch(Exception e) {
    exception = e;
  }

  assert(exception is null);
}

@("fails when the caught exception has a different type")
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
  assert(exception.message.indexOf("`fluentasserts.operations.exception.throwable.CustomException` saying `hello` was thrown.") != -1);
}

@("does not fail when a certain exception type is not caught")
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

@("fails when the caught exception has a different message")
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
  assert(exception.message.indexOf("`fluentasserts.operations.exception.throwable.CustomException` saying `hello` was thrown.") != -1);
}

@("does not fail when the caught exception is expected to have a different message")
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

@("throwSomething catches assert failures")
unittest {
  ({
    assert(false, "test");
  }).should.throwSomething.withMessage.equal("test");
}

@("throwSomething works with withMessage directly")
unittest {
  ({
    assert(false, "test");
  }).should.throwSomething.withMessage("test");
}

@("throwException allows access to thrown exception via .thrown")
unittest {
  class DataException : Exception {
    int data;
    this(int data, string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
      this.data = data;
    }
  }

  auto thrown = ({
    throw new DataException(2, "test");
  }).should.throwException!DataException.thrown;

  thrown.should.not.beNull;
  thrown.msg.should.equal("test");
  (cast(DataException) thrown).data.should.equal(2);
}

@("throwAnyException returns message for chaining")
unittest {
  ({
    throw new Exception("test");
  }).should.throwAnyException.msg.should.equal("test");
}
