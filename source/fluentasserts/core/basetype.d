module fluentasserts.core.basetype;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.conv;
import std.algorithm;

@("lazy number that throws propagates the exception")
unittest {
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
  ({
    5.should.equal(5);
    5.should.not.equal(6);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.equal(6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should equal 6. 5 is not equal to 6. ");

  msg = ({
    5.should.not.equal(5);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should not equal 5. 5 is equal to 5. ");
}

@("bools equal")
unittest {
  ({
    true.should.equal(true);
    true.should.not.equal(false);
  }).should.not.throwAnyException;

  auto msg = ({
    true.should.equal(false);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("true should equal false. ");
  msg.split("\n")[2].strip.should.equal("Expected:false");
  msg.split("\n")[3].strip.should.equal("Actual:true");

  msg = ({
    true.should.not.equal(true);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("true should not equal true. ");
  msg.split("\n")[2].strip.should.equal("Expected:not true");
  msg.split("\n")[3].strip.should.equal("Actual:true");
}

@("numbers greater than")
unittest {
  ({
    5.should.be.greaterThan(4);
    5.should.not.be.greaterThan(6);

    5.should.be.above(4);
    5.should.not.be.above(6);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.be.greaterThan(5);
    5.should.be.above(5);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be greater than 5. 5 is less than or equal to 5.");

  msg = ({
    5.should.not.be.greaterThan(4);
    5.should.not.be.above(4);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should not be greater than 4. 5 is greater than 4.");
}

@("numbers less than")
unittest {
  ({
    5.should.be.lessThan(6);
    5.should.not.be.lessThan(4);

    5.should.be.below(6);
    5.should.not.be.below(4);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.be.lessThan(4);
    5.should.be.below(4);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be less than 4. 5 is greater than or equal to 4.");
  msg.split("\n")[2].strip.should.equal("Expected:less than 4");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.lessThan(6);
    5.should.not.be.below(6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should not be less than 6. 5 is less than 6.");
}

@("numbers between")
unittest {
  ({
    5.should.be.between(4, 6);
    5.should.be.between(6, 4);
    5.should.not.be.between(5, 6);
    5.should.not.be.between(4, 5);

    5.should.be.within(4, 6);
    5.should.be.within(6, 4);
    5.should.not.be.within(5, 6);
    5.should.not.be.within(4, 5);
  }).should.not.throwAnyException;

  auto msg = ({
    5.should.be.between(5, 6);
    5.should.be.within(5, 6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be between 5 and 6. 5 is less than or equal to 5.");
  msg.split("\n")[2].strip.should.equal("Expected:a value inside (5, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.be.between(4, 5);
    5.should.be.within(4, 5);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("5 should be between 4 and 5. 5 is greater than or equal to 5.");
  msg.split("\n")[2].strip.should.equal("Expected:a value inside (4, 5) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.between(4, 6);
    5.should.not.be.within(4, 6);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("5 should not be between 4 and 6.");
  msg.split("\n")[2].strip.should.equal("Expected:a value outside (4, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");

  msg = ({
    5.should.not.be.between(6, 4);
    5.should.not.be.within(6, 4);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("5 should not be between 6 and 4.");
  msg.split("\n")[2].strip.should.equal("Expected:a value outside (4, 6) interval");
  msg.split("\n")[3].strip.should.equal("Actual:5");
}

@("numbers approximately")
unittest {
  ({
    (10f/3f).should.be.approximately(3, 0.34);
    (10f/3f).should.not.be.approximately(3, 0.1);
  }).should.not.throwAnyException;

  auto msg = ({
    (10f/3f).should.be.approximately(3, 0.1);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.contain("(10f/3f) should be approximately 3±0.1.");
  msg.split("\n")[2].strip.should.contain("Expected:3±0.1");
  msg.split("\n")[3].strip.should.contain("Actual:3.33333");

  msg = ({
    (10f/3f).should.not.be.approximately(3, 0.34);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.contain("(10f/3f) should not be approximately 3±0.34.");
  msg.split("\n")[2].strip.should.contain("Expected:not 3±0.34");
  msg.split("\n")[3].strip.should.contain("Actual:3.33333");
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

  bool thrown;

  try {
    noException.should.throwAnyException;
  } catch (TestException e) {
    e.msg.should.startWith("noException should throw any exception. No exception was thrown.");
    thrown = true;
  }
  thrown.should.equal(true);

  thrown = false;

  try {
    voidValue().should.not.throwAnyException;
  } catch(TestException e) {
    thrown = true;
    e.msg.split("\n")[0].should.equal("voidValue() should not throw any exception. `object.Exception` saying `nothing here` was thrown.");
  }

  thrown.should.equal(true);
}

@("compiles const comparison")
unittest {
  const actual = 42;
  actual.should.equal(42);
}
