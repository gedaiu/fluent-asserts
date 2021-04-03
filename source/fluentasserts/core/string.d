module fluentasserts.core.string;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.conv;
import std.algorithm;
import std.array;

/// When there is a lazy string that throws an it should throw that exception
unittest {
  string someLazyString() {
    throw new Exception("This is it.");
  }

  ({
    someLazyString.should.equal("");
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyString.should.contain("");
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyString.should.contain([""]);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyString.should.contain(' ');
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyString.should.startWith(" ");
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyString.should.endWith(" ");
  }).should.throwAnyException.withMessage("This is it.");
}

@("string startWith")
unittest {
  ({
    "test string".should.startWith("test");
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.startWith("other");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`"test string" does not start with "other"`);
  msg.split("\n")[2].strip.should.equal(`Expected:to start with "other"`);
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);

  ({
    "test string".should.not.startWith("other");
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.startWith("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`"test string" starts with "test"`);
  msg.split("\n")[2].strip.should.equal(`Expected:to not start with "test"`);
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);

  ({
    "test string".should.startWith('t');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.startWith('o');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`"test string" does not start with 'o'`);
  msg.split("\n")[2].strip.should.equal("Expected:to start with 'o'");
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);

  ({
    "test string".should.not.startWith('o');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.startWith('t');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`"test string" starts with 't'`);
  msg.split("\n")[2].strip.should.equal(`Expected:to not start with 't'`);
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);
}

@("string endWith")
unittest {
  ({
    "test string".should.endWith("string");
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.endWith("other");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`"test string" does not end with "other"`);
  msg.split("\n")[2].strip.should.equal(`Expected:to end with "other"`);
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);

  ({
    "test string".should.not.endWith("other");
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.endWith("string");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should not end with "string". "test string" ends with "string".`);
  msg.split("\n")[2].strip.should.equal(`Expected:to not end with "string"`);
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);

  ({
    "test string".should.endWith('g');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.endWith('t');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`"test string" does not end with 't'`);
  msg.split("\n")[2].strip.should.equal("Expected:to end with 't'");
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);

  ({
    "test string".should.not.endWith('w');
  }).should.not.throwAnyException;

  msg = ({
    "test string".should.not.endWith('g');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`"test string" ends with 'g'`);
  msg.split("\n")[2].strip.should.equal("Expected:to not end with 'g'");
  msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);
}

@("string contain")
unittest {
  ({
    "test string".should.contain(["string", "test"]);
    "test string".should.not.contain(["other", "message"]);
  }).should.not.throwAnyException;

  ({
    "test string".should.contain("string");
    "test string".should.not.contain("other");
  }).should.not.throwAnyException;

  ({
    "test string".should.contain('s');
    "test string".should.not.contain('z');
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.contain(["other", "message"]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should contain ["other", "message"]. ["other", "message"] are missing from "test string".`);
  msg.split("\n")[2].strip.should.equal(`Expected:to contain all ["other", "message"]`);
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain(["test", "string"]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should not contain ["test", "string"]. ["test", "string"] are present in "test string".`);
  msg.split("\n")[2].strip.should.equal(`Expected:to not contain any ["test", "string"]`);
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.contain("other");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should contain "other". other is missing from "test string".`);
  msg.split("\n")[2].strip.should.equal(`Expected:to contain "other"`);
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should not contain "test". test is present in "test string".`);
  msg.split("\n")[2].strip.should.equal(`Expected:to not contain "test"`);
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.contain('o');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`o is missing from "test string"`);
  msg.split("\n")[2].strip.should.equal("Expected:to contain 'o'");
  msg.split("\n")[3].strip.should.equal("Actual:test string");

  msg = ({
    "test string".should.not.contain('t');
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should not contain 't'. t is present in "test string".`);
  msg.split("\n")[2].strip.should.equal("Expected:to not contain 't'");
  msg.split("\n")[3].strip.should.equal("Actual:test string");
}

@("string equal")
unittest {
  ({
    "test string".should.equal("test string");
  }).should.not.throwAnyException;

  ({
    "test string".should.not.equal("test");
  }).should.not.throwAnyException;

  auto msg = ({
    "test string".should.equal("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should equal "test". "test string" is not equal to "test".`);

  msg = ({
    "test string".should.not.equal("test string");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal(`"test string" should not equal "test string". "test string" is equal to "test string".`);

  msg = ({
    ubyte[] data = [115, 111, 109, 101, 32, 100, 97, 116, 97, 0, 0];
    data.assumeUTF.to!string.should.equal("some data");
  }).should.throwException!TestException.msg;

  msg.should.contain(`Actual:"some data\0\0"`);
  msg.should.contain(`data.assumeUTF.to!string should equal "some data". "some data\0\0" is not equal to "some data".`);
  msg.should.contain(`some data[+\0\0]`);
}

/// should throw exceptions for delegates that return basic types
unittest {
  string value() {
    throw new Exception("not implemented");
  }

  value().should.throwAnyException.withMessage.equal("not implemented");

  string noException() { return null; }
  bool thrown;

  try {
    noException.should.throwAnyException;
  } catch(TestException e) {
    e.msg.should.startWith("noException should throw any exception. No exception was thrown.");
    thrown = true;
  }

  thrown.should.equal(true);
}

@("const string equal")
unittest {
  const string constValue = "test string";
  immutable string immutableValue = "test string";

  constValue.should.equal("test string");
  immutableValue.should.equal("test string");

  "test string".should.equal(constValue);
  "test string".should.equal(immutableValue);
}
