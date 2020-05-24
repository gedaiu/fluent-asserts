module fluentasserts.core.operations.throwable;

public import fluentasserts.core.base;
import fluentasserts.core.results;
import fluentasserts.core.lifecycle;
import fluentasserts.core.expect;

import std.string;
import std.conv;
import std.algorithm;
import std.array;

///
IResult[] throwAnyException(ref Evaluation evaluation) @trusted nothrow {
  IResult[] results;

  Lifecycle.instance.addText(". ");
  auto thrown = evaluation.currentValue.throwable;

  if(evaluation.currentValue.throwable && evaluation.isNegated) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    Lifecycle.instance.addText("`");
    Lifecycle.instance.addValue(thrown.classinfo.name);
    Lifecycle.instance.addText("` saying `");
    Lifecycle.instance.addValue(message);
    Lifecycle.instance.addText("` was thrown.");

    try results ~= new ExpectedActualResult("No exception to be thrown", "`" ~ thrown.classinfo.name ~ "` saying `" ~ message ~ "`"); catch(Exception) {}
  }

  if(!thrown && !evaluation.isNegated) {
    Lifecycle.instance.addText("No exception was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "Nothing was thrown"); catch(Exception) {}
  }

  if(thrown && !evaluation.isNegated && "Throwable" in evaluation.currentValue.meta) {
    string message;
    try message = thrown.message.to!string; catch(Exception) {}

    Lifecycle.instance.addText("A `Throwable` saying `" ~ message ~ "` was thrown.");

    try results ~= new ExpectedActualResult("Any exception to be thrown", "A `Throwable` with message `" ~ message ~ "` was thrown"); catch(Exception) {}
  }

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

    assert(e.message.indexOf("should throw any exception. A `Throwable` saying `Assertion failure` was thrown.") != -1);
    assert(e.message.indexOf("\n Expected:Any exception to be thrown\n") != -1);
    assert(e.message.indexOf("\n   Actual:A `Throwable` with message `Assertion failure` was thrown\n") != -1);
  }

  assert(thrown, "The exception was not thrown");
}

/// It should be successfull when the function throws an expected exception
unittest {
  void test() { throw new Exception("test"); }
  expect({ test(); }).to.throwAnyException;
}
