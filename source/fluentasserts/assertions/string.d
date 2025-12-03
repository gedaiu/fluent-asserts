module fluentasserts.assertions.string;

public import fluentasserts.core.base;
import fluentasserts.results.printer;

import std.string;
import std.conv;
import std.algorithm;
import std.array;

version(unittest) {
  import fluentasserts.core.lifecycle;
}

@("lazy string that throws propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
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
  "test string".should.startWith("test");
  "test string".should.not.startWith("other");
  "test string".should.startWith('t');
  "test string".should.not.startWith('o');

  auto evaluation = ({
    "test string".should.startWith("other");
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" does not start with "other"`);
  evaluation.result.expected.should.equal(`to start with "other"`);
  evaluation.result.actual.should.equal(`"test string"`);

  evaluation = ({
    "test string".should.not.startWith("test");
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" starts with "test"`);
  evaluation.result.expected.should.equal(`not to start with "test"`);
  evaluation.result.actual.should.equal(`"test string"`);

  evaluation = ({
    "test string".should.startWith('o');
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" does not start with 'o'`);
  evaluation.result.expected.should.equal("to start with 'o'");
  evaluation.result.actual.should.equal(`"test string"`);

  evaluation = ({
    "test string".should.not.startWith('t');
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" starts with 't'`);
  evaluation.result.expected.should.equal(`not to start with 't'`);
  evaluation.result.actual.should.equal(`"test string"`);
}

@("string endWith")
unittest {
  "test string".should.endWith("string");
  "test string".should.not.endWith("other");
  "test string".should.endWith('g');
  "test string".should.not.endWith('w');

  auto evaluation = ({
    "test string".should.endWith("other");
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" does not end with "other"`);
  evaluation.result.expected.should.equal(`to end with "other"`);
  evaluation.result.actual.should.equal(`"test string"`);

  evaluation = ({
    "test string".should.not.endWith("string");
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith(`"test string" should not end with "string". "test string" ends with "string".`);
  evaluation.result.expected.should.equal(`not to end with "string"`);
  evaluation.result.actual.should.equal(`"test string"`);

  evaluation = ({
    "test string".should.endWith('t');
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" does not end with 't'`);
  evaluation.result.expected.should.equal("to end with 't'");
  evaluation.result.actual.should.equal(`"test string"`);

  evaluation = ({
    "test string".should.not.endWith('g');
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" ends with 'g'`);
  evaluation.result.expected.should.equal("not to end with 'g'");
  evaluation.result.actual.should.equal(`"test string"`);
}

@("string contain")
unittest {
  "test string".should.contain(["string", "test"]);
  "test string".should.not.contain(["other", "message"]);

  "test string".should.contain("string");
  "test string".should.not.contain("other");

  "test string".should.contain('s');
  "test string".should.not.contain('z');

  auto evaluation = ({
    "test string".should.contain(["other", "message"]);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`["other", "message"] are missing from "test string"`);
  evaluation.result.expected.should.equal(`to contain all ["other", "message"]`);
  evaluation.result.actual.should.equal("test string");

  evaluation = ({
    "test string".should.not.contain(["test", "string"]);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`["test", "string"] are present in "test string"`);
  evaluation.result.expected.should.equal(`not to contain any ["test", "string"]`);
  evaluation.result.actual.should.equal("test string");

  evaluation = ({
    "test string".should.contain("other");
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`other is missing from "test string"`);
  evaluation.result.expected.should.equal(`to contain "other"`);
  evaluation.result.actual.should.equal("test string");

  evaluation = ({
    "test string".should.not.contain("test");
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`test is present in "test string"`);
  evaluation.result.expected.should.equal(`not to contain "test"`);
  evaluation.result.actual.should.equal("test string");

  evaluation = ({
    "test string".should.contain('o');
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`o is missing from "test string"`);
  evaluation.result.expected.should.equal("to contain 'o'");
  evaluation.result.actual.should.equal("test string");

  evaluation = ({
    "test string".should.not.contain('t');
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`t is present in "test string"`);
  evaluation.result.expected.should.equal("not to contain 't'");
  evaluation.result.actual.should.equal("test string");
}

@("string equal")
unittest {
  "test string".should.equal("test string");
  "test string".should.not.equal("test");

  auto evaluation = ({
    "test string".should.equal("test");
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" is not equal to "test"`);

  evaluation = ({
    "test string".should.not.equal("test string");
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`"test string" is equal to "test string"`);
}

@("shows null chars in the diff")
unittest {
  ubyte[] data = [115, 111, 109, 101, 32, 100, 97, 116, 97, 0, 0];

  auto evaluation = ({
    data.assumeUTF.to!string.should.equal("some data");
  }).recordEvaluation;

  evaluation.result.actual.should.equal(`"some data\0\0"`);
  evaluation.result.messageString.should.equal(`"some data\0\0" is not equal to "some data"`);
}

@("throws exceptions for delegates that return basic types")
unittest {
  string value() {
    throw new Exception("not implemented");
  }

  value().should.throwAnyException.withMessage.equal("not implemented");

  string noException() { return null; }

  auto evaluation = ({
    noException.should.throwAnyException;
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("noException should throw any exception. No exception was thrown.");
}

@("const string equal")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const string constValue = "test string";
  immutable string immutableValue = "test string";

  constValue.should.equal("test string");
  immutableValue.should.equal("test string");

  "test string".should.equal(constValue);
  "test string".should.equal(immutableValue);
}
