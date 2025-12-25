module fluentasserts.operations.exception.throwable;

public import fluentasserts.core.base;
import fluentasserts.results.printer;
import fluentasserts.core.lifecycle;
import fluentasserts.core.expect;
import fluentasserts.results.serializers.string_registry;
import fluentasserts.results.serializers.stringprocessing : cleanString;

import std.string;
import std.conv;

static immutable throwAnyDescription = "Tests that the tested callable throws an exception.";

private void addThrownMessage(ref Evaluation evaluation, Throwable thrown, string message) @trusted nothrow {
  evaluation.result.addText(". `");
  evaluation.result.addValue(thrown.classinfo.name);
  evaluation.result.addText("` saying `");
  evaluation.result.addValue(message);
  evaluation.result.addText("` was thrown.");
}

private void setThrownActual(ref Evaluation evaluation, Throwable thrown, string message) @trusted nothrow {
  evaluation.result.actual.put("`");
  evaluation.result.actual.put(thrown.classinfo.name);
  evaluation.result.actual.put("` saying `");
  evaluation.result.actual.put(message);
  evaluation.result.actual.put("`");
}

private string getThrowableMessage(Throwable thrown) @trusted nothrow {
  string message;
  try {
    message = thrown.message.to!string;
  } catch (Exception) {}
  return message;
}

version(unittest) {
  import fluentasserts.core.lifecycle;

  class CustomException : Exception {
    this(string msg, string fileName = "", size_t line = 0, Throwable next = null) {
      super(msg, fileName, line, next);
    }
  }
}

///
void throwAnyException(ref Evaluation evaluation) @trusted nothrow {
  auto thrown = evaluation.currentValue.throwable;

  if (thrown && evaluation.isNegated) {
    string message = getThrowableMessage(thrown);
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put("No exception to be thrown");
    setThrownActual(evaluation, thrown, message);
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.result.addText(". No exception was thrown.");
    evaluation.result.expected.put("Any exception to be thrown");
    evaluation.result.actual.put("Nothing was thrown");
  }

  if (thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message = getThrowableMessage(thrown);
    evaluation.result.addText(". A `Throwable` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");
    evaluation.result.expected.put("Any exception to be thrown");
    evaluation.result.actual.put("A `Throwable` with message `");
    evaluation.result.actual.put(message);
    evaluation.result.actual.put("` was thrown");
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

@("non-throwing function not throwAnyException succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  void test() {}
  expect({ test(); }).to.not.throwAnyException();
}

@("throwing function not throwAnyException reports error with expected and actual")
unittest {
  void test() { throw new Exception("Test exception"); }

  auto evaluation = ({
    expect({ test(); }).to.not.throwAnyException();
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should not throw any exception. `object.Exception` saying `Test exception` was thrown.");
  expect(evaluation.result.expected[]).to.equal("No exception to be thrown");
  expect(evaluation.result.actual[]).to.equal("`object.Exception` saying `Test exception`");
}

@("throwing function throwAnyException succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

@("function throwing Throwable throwAnyException reports error with expected and actual")
unittest {
  void test() { assert(false); }

  auto evaluation = ({
    expect({ test(); }).to.throwAnyException;
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should throw any exception.");
  expect(evaluation.result.messageString).to.contain("Throwable");
  expect(evaluation.result.expected[]).to.equal("Any exception to be thrown");
  // The actual message contains verbose assertion output from the fluentHandler
  expect(evaluation.result.actual[].length > 0).to.equal(true);
}

@("function throwing any exception throwAnyException succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}

void throwAnyExceptionWithMessage(ref Evaluation evaluation) @trusted nothrow {
  auto thrown = evaluation.currentValue.throwable;

  if (thrown && evaluation.isNegated) {
    string message = getThrowableMessage(thrown);
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put("No exception to be thrown");
    setThrownActual(evaluation, thrown, message);
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.result.addText(". Nothing was thrown.");
    evaluation.result.expected.put("Any exception to be thrown");
    evaluation.result.actual.put("Nothing was thrown");
  }

  if (thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message = getThrowableMessage(thrown);
    evaluation.result.addText(". A `Throwable` saying `");
    evaluation.result.addValue(message);
    evaluation.result.addText("` was thrown.");
    evaluation.result.expected.put("Any throwable with the message `");
    evaluation.result.expected.put(message);
    evaluation.result.expected.put("` to be thrown");
    evaluation.result.actual.put("A `");
    evaluation.result.actual.put(thrown.classinfo.name);
    evaluation.result.actual.put("` with message `");
    evaluation.result.actual.put(message);
    evaluation.result.actual.put("` was thrown");
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

/// throwSomething - accepts any Throwable including Error/AssertError
void throwSomething(ref Evaluation evaluation) @trusted nothrow {
  auto thrown = evaluation.currentValue.throwable;

  if (thrown && evaluation.isNegated) {
    string message = getThrowableMessage(thrown);
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put("No throwable to be thrown");
    setThrownActual(evaluation, thrown, message);
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.result.addText(". Nothing was thrown.");
    evaluation.result.expected.put("Any throwable to be thrown");
    evaluation.result.actual.put("Nothing was thrown");
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

/// throwSomethingWithMessage - accepts any Throwable including Error/AssertError
void throwSomethingWithMessage(ref Evaluation evaluation) @trusted nothrow {
  auto thrown = evaluation.currentValue.throwable;

  if (thrown && evaluation.isNegated) {
    string message = getThrowableMessage(thrown);
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put("No throwable to be thrown");
    setThrownActual(evaluation, thrown, message);
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.result.addText(". Nothing was thrown.");
    evaluation.result.expected.put("Any throwable to be thrown");
    evaluation.result.actual.put("Nothing was thrown");
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

@("throwSomething catches assert failures")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  ({
    assert(false, "test");
  }).should.throwSomething.withMessage.equal("test");
}

@("throwSomething works with withMessage directly")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  ({
    assert(false, "test");
  }).should.throwSomething.withMessage("test");
}

///
void throwException(ref Evaluation evaluation) @trusted nothrow {
  string exceptionType;

  if ("exceptionType" in evaluation.expectedValue.meta) {
    exceptionType = cleanString(evaluation.expectedValue.meta["exceptionType"].idup);
  }

  auto thrown = evaluation.currentValue.throwable;

  if (thrown && evaluation.isNegated && thrown.classinfo.name == exceptionType) {
    string message = getThrowableMessage(thrown);
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put("no `");
    evaluation.result.expected.put(exceptionType);
    evaluation.result.expected.put("` to be thrown");
    setThrownActual(evaluation, thrown, message);
  }

  if (thrown && !evaluation.isNegated && thrown.classinfo.name != exceptionType) {
    string message = getThrowableMessage(thrown);
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put(exceptionType);
    setThrownActual(evaluation, thrown, message);
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.result.addText(". No exception was thrown.");
    evaluation.result.expected.put("`");
    evaluation.result.expected.put(exceptionType);
    evaluation.result.expected.put("` to be thrown");
    evaluation.result.actual.put("Nothing was thrown");
  }

  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;
}

@("CustomException throwException CustomException succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect({
    throw new CustomException("test");
  }).to.throwException!CustomException;
}

@("non-throwing throwException Exception reports error with expected and actual")
unittest {
  auto evaluation = ({
    ({}).should.throwException!Exception;
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should throw exception");
  expect(evaluation.result.messageString).to.contain("No exception was thrown.");
  expect(evaluation.result.expected[]).to.equal("`object.Exception` to be thrown");
  expect(evaluation.result.actual[]).to.equal("Nothing was thrown");
}

@("Exception throwException CustomException reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect({
      throw new Exception("test");
    }).to.throwException!CustomException;
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should throw exception");
  expect(evaluation.result.messageString).to.contain("`object.Exception` saying `test` was thrown.");
  expect(evaluation.result.expected[]).to.equal("fluentasserts.operations.exception.throwable.CustomException");
  expect(evaluation.result.actual[]).to.equal("`object.Exception` saying `test`");
}

@("Exception not throwException CustomException succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect({
    throw new Exception("test");
  }).to.not.throwException!CustomException;
}

@("CustomException not throwException CustomException reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect({
      throw new CustomException("test");
    }).to.not.throwException!CustomException;
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should not throw exception");
  expect(evaluation.result.messageString).to.contain("`fluentasserts.operations.exception.throwable.CustomException` saying `test` was thrown.");
  expect(evaluation.result.expected[]).to.equal("no `fluentasserts.operations.exception.throwable.CustomException` to be thrown");
  expect(evaluation.result.actual[]).to.equal("`fluentasserts.operations.exception.throwable.CustomException` saying `test`");
}

void throwExceptionWithMessage(ref Evaluation evaluation) @trusted nothrow {
  string exceptionType;
  string message;
  string expectedMessage = evaluation.expectedValue.strValue[].idup;

  if(expectedMessage.startsWith(`"`)) {
    expectedMessage = expectedMessage[1..$-1];
  }

  if ("exceptionType" in evaluation.expectedValue.meta) {
    exceptionType = cleanString(evaluation.expectedValue.meta["exceptionType"].idup);
  }

  auto thrown = evaluation.currentValue.throwable;
  evaluation.throwable = thrown;
  evaluation.currentValue.throwable = null;

  if (thrown) {
    message = getThrowableMessage(thrown);
  }

  if (!thrown && !evaluation.isNegated) {
    evaluation.result.addText(". No exception was thrown.");
    evaluation.result.expected.put("`");
    evaluation.result.expected.put(exceptionType);
    evaluation.result.expected.put("` with message `");
    evaluation.result.expected.put(expectedMessage);
    evaluation.result.expected.put("` to be thrown");
    evaluation.result.actual.put("nothing was thrown");
  }

  if (thrown && !evaluation.isNegated && thrown.classinfo.name != exceptionType) {
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put("`");
    evaluation.result.expected.put(exceptionType);
    evaluation.result.expected.put("` to be thrown");
    setThrownActual(evaluation, thrown, message);
  }

  if (thrown && !evaluation.isNegated && thrown.classinfo.name == exceptionType && message != expectedMessage) {
    addThrownMessage(evaluation, thrown, message);
    evaluation.result.expected.put("`");
    evaluation.result.expected.put(exceptionType);
    evaluation.result.expected.put("` saying `");
    evaluation.result.expected.put(message);
    evaluation.result.expected.put("` to be thrown");
    setThrownActual(evaluation, thrown, message);
  }
}

@("non-throwing throwException Exception withMessage reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect({}).to.throwException!Exception.withMessage.equal("test");
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should throw exception");
  expect(evaluation.result.messageString).to.contain("with message equal test");
  expect(evaluation.result.messageString).to.contain("No exception was thrown.");
}

@("non-throwing not throwException Exception withMessage succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect({}).not.to.throwException!Exception.withMessage.equal("test");
}

@("CustomException throwException Exception withMessage reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect({
      throw new CustomException("hello");
    }).to.throwException!Exception.withMessage.equal("test");
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should throw exception");
  expect(evaluation.result.messageString).to.contain("with message equal test");
  expect(evaluation.result.messageString).to.contain("`fluentasserts.operations.exception.throwable.CustomException` saying `hello` was thrown.");
}

@("CustomException not throwException Exception withMessage succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect({
    throw new CustomException("hello");
  }).not.to.throwException!Exception.withMessage.equal("test");
}

@("CustomException hello throwException CustomException withMessage test reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect({
      throw new CustomException("hello");
    }).to.throwException!CustomException.withMessage.equal("test");
  }).recordEvaluation;

  expect(evaluation.result.messageString).to.contain("should throw exception");
  expect(evaluation.result.messageString).to.contain("with message equal test");
  expect(evaluation.result.messageString).to.contain("`fluentasserts.operations.exception.throwable.CustomException` saying `hello` was thrown.");
}

@("CustomException hello not throwException CustomException withMessage test succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect({
    throw new CustomException("hello");
  }).not.to.throwException!CustomException.withMessage.equal("test");
}

@("throwException allows access to thrown exception via .thrown")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
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
  Lifecycle.instance.disableFailureHandling = false;
  ({
    throw new Exception("test");
  }).should.throwAnyException.msg.should.equal("test");
}
