module fluentasserts.assertions.basetype;

public import fluentasserts.core.base;
import fluentasserts.results.printer;

import std.string;
import std.conv;
import std.algorithm;

version(unittest) {
  import fluentasserts.core.lifecycle;
}

@("lazy number that throws propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int someLazyInt() {
    throw new Exception("This is it.");
  }

  ({
    someLazyInt.should.equal(3);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.greaterThan(3);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.lessThan(3);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.between(3, 4);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyInt.should.be.approximately(3, 4);
  }).should.throwAnyException.withMessage("This is it.");
}

@("numbers equal")
unittest {
  5.should.equal(5);
  5.should.not.equal(6);

  auto evaluation = ({
    5.should.equal(6);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is not equal to 6");

  evaluation = ({
    5.should.not.equal(5);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is equal to 5");
}

@("bools equal")
unittest {
  true.should.equal(true);
  true.should.not.equal(false);

  auto evaluation = ({
    true.should.equal(false);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("true should equal false.");
  evaluation.result.expected.should.equal("false");
  evaluation.result.actual.should.equal("true");

  evaluation = ({
    true.should.not.equal(true);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("true should not equal true.");
  evaluation.result.expected.should.equal("not true");
  evaluation.result.actual.should.equal("true");
}

@("numbers greater than")
unittest {
  5.should.be.greaterThan(4);
  5.should.not.be.greaterThan(6);

  5.should.be.above(4);
  5.should.not.be.above(6);

  auto evaluation = ({
    5.should.be.greaterThan(5);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is less than or equal to 5");

  evaluation = ({
    5.should.not.be.greaterThan(4);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is greater than 4");
}

@("numbers less than")
unittest {
  5.should.be.lessThan(6);
  5.should.not.be.lessThan(4);

  5.should.be.below(6);
  5.should.not.be.below(4);

  auto evaluation = ({
    5.should.be.lessThan(4);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is greater than or equal to 4");
  evaluation.result.expected.should.equal("less than 4");
  evaluation.result.actual.should.equal("5");

  evaluation = ({
    5.should.not.be.lessThan(6);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is less than 6");
}

@("numbers between")
unittest {
  5.should.be.between(4, 6);
  5.should.be.between(6, 4);
  5.should.not.be.between(5, 6);
  5.should.not.be.between(4, 5);

  5.should.be.within(4, 6);
  5.should.be.within(6, 4);
  5.should.not.be.within(5, 6);
  5.should.not.be.within(4, 5);

  auto evaluation = ({
    5.should.be.between(5, 6);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is less than or equal to 5");
  evaluation.result.expected.should.equal("a value inside (5, 6) interval");
  evaluation.result.actual.should.equal("5");

  evaluation = ({
    5.should.be.between(4, 5);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 is greater than or equal to 5");
  evaluation.result.expected.should.equal("a value inside (4, 5) interval");
  evaluation.result.actual.should.equal("5");

  evaluation = ({
    5.should.not.be.between(4, 6);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 should not be between 4 and 6");
  evaluation.result.expected.should.equal("a value outside (4, 6) interval");
  evaluation.result.actual.should.equal("5");

  evaluation = ({
    5.should.not.be.between(6, 4);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("5 should not be between 6 and 4");
  evaluation.result.expected.should.equal("a value outside (4, 6) interval");
  evaluation.result.actual.should.equal("5");
}

@("numbers approximately")
unittest {
  (10f/3f).should.be.approximately(3, 0.34);
  (10f/3f).should.not.be.approximately(3, 0.1);

  auto evaluation = ({
    (10f/3f).should.be.approximately(3, 0.1);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("(10f/3f) should be approximately 3");
  evaluation.result.expected.should.contain("3");
  evaluation.result.actual.should.contain("3.33333");

  evaluation = ({
    (10f/3f).should.not.be.approximately(3, 0.34);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("(10f/3f) should not be approximately 3");
  evaluation.result.expected.should.contain("not 3");
  evaluation.result.actual.should.contain("3.33333");
}

@("delegates returning basic types that throw propagate the exception")
unittest {
  int value() {
    throw new Exception("not implemented value");
  }

  void voidValue() {
    throw new Exception("nothing here");
  }

  void noException() { }

  value().should.throwAnyException.withMessage.equal("not implemented value");
  voidValue().should.throwAnyException.withMessage.equal("nothing here");

  auto evaluation = ({
    noException.should.throwAnyException;
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("noException should throw any exception. No exception was thrown.");

  evaluation = ({
    voidValue().should.not.throwAnyException;
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("voidValue() should not throw any exception");
  evaluation.result.messageString.should.contain("`nothing here` was thrown");
}

@("compiles const comparison")
unittest {
  const actual = 42;
  actual.should.equal(42);
}
