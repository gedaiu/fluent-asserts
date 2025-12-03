module fluentasserts.assertions.objects;

public import fluentasserts.core.base;
import fluentasserts.results.printer;

import std.string;
import std.stdio;
import std.traits;
import std.conv;

version(unittest) {
  import fluentasserts.core.lifecycle;
}

@("lazy object that throws propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Object someLazyObject() {
    throw new Exception("This is it.");
  }

  ({
    someLazyObject.should.not.beNull;
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyObject.should.be.instanceOf!Object;
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyObject.should.equal(new Object);
  }).should.throwAnyException.withMessage("This is it.");
}

@("object beNull")
unittest {
  Object o = null;

  o.should.beNull;
  (new Object).should.not.beNull;

  auto evaluation = ({
    o.should.not.beNull;
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("o should not be null.");
  evaluation.result.expected.should.equal("not null");
  evaluation.result.actual.should.equal("object.Object");

  evaluation = ({
    (new Object).should.beNull;
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("(new Object) should be null.");
  evaluation.result.expected.should.equal("null");
  evaluation.result.actual.should.equal("object.Object");
}

@("object instanceOf")
unittest {
  class BaseClass { }
  class ExtendedClass : BaseClass { }
  class SomeClass { }
  class OtherClass { }

  auto someObject = new SomeClass;
  auto otherObject = new OtherClass;
  auto extendedObject = new ExtendedClass;

  someObject.should.be.instanceOf!SomeClass;
  extendedObject.should.be.instanceOf!BaseClass;

  someObject.should.not.be.instanceOf!OtherClass;
  someObject.should.not.be.instanceOf!BaseClass;

  auto evaluation = ({
    otherObject.should.be.instanceOf!SomeClass;
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`otherObject should be instance of`);
  evaluation.result.messageString.should.contain(`SomeClass`);
  evaluation.result.expected.should.contain("SomeClass");
  evaluation.result.actual.should.contain("OtherClass");

  evaluation = ({
    otherObject.should.not.be.instanceOf!OtherClass;
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`otherObject should not be instance of`);
  evaluation.result.messageString.should.contain(`OtherClass`);
  evaluation.result.expected.should.contain("not typeof");
  evaluation.result.actual.should.contain("OtherClass");
}

@("object instanceOf interface")
unittest {
  interface MyInterface { }
  class BaseClass : MyInterface { }
  class OtherClass { }

  auto someObject = new BaseClass;
  MyInterface someInterface = new BaseClass;
  auto otherObject = new OtherClass;

  someInterface.should.be.instanceOf!MyInterface;
  someInterface.should.not.be.instanceOf!BaseClass;

  someObject.should.be.instanceOf!MyInterface;

  auto evaluation = ({
    otherObject.should.be.instanceOf!MyInterface;
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`otherObject should be instance of`);
  evaluation.result.messageString.should.contain(`MyInterface`);
  evaluation.result.expected.should.contain("MyInterface");
  evaluation.result.actual.should.contain("OtherClass");

  evaluation = ({
    someObject.should.not.be.instanceOf!MyInterface;
  }).recordEvaluation;

  evaluation.result.messageString.should.contain(`someObject should not be instance of`);
  evaluation.result.messageString.should.contain(`MyInterface`);
  evaluation.result.expected.should.contain("not typeof");
  evaluation.result.actual.should.contain("BaseClass");
}

@("delegates returning objects that throw propagate the exception")
unittest {
  class SomeClass { }

  SomeClass value() {
    throw new Exception("not implemented");
  }

  SomeClass noException() { return null; }

  value().should.throwAnyException.withMessage.equal("not implemented");

  auto evaluation = ({
    noException.should.throwAnyException;
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("noException should throw any exception. No exception was thrown.");
}

@("object equal")
unittest {
  class TestEqual {
    private int value;

    this(int value) {
      this.value = value;
    }
  }

  auto instance = new TestEqual(1);

  instance.should.equal(instance);
  instance.should.not.equal(new TestEqual(1));

  auto evaluation = ({
    instance.should.not.equal(instance);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("instance should not equal TestEqual");

  evaluation = ({
    instance.should.equal(new TestEqual(1));
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("instance should equal TestEqual");
}

@("null object comparison")
unittest {
  Object nullObject;

  auto evaluation = ({
    nullObject.should.equal(new Object);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("nullObject should equal Object(");

  evaluation = ({
    (new Object).should.equal(null);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("(new Object) should equal null.");
}
