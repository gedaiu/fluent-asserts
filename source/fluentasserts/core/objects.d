module fluentasserts.core.objects;

public import fluentasserts.core.base;
import fluentasserts.core.results;

import std.string;
import std.stdio;
import std.traits;
import std.conv;

@("lazy object that throws propagates the exception")
unittest {
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

  ({
    o.should.beNull;
    (new Object).should.not.beNull;
  }).should.not.throwAnyException;

  auto msg = ({
    o.should.not.beNull;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("o should not be null.");
  msg.split("\n")[1].strip.should.equal("Expected:not null");
  msg.split("\n")[2].strip.should.equal("Actual:object.Object");

  msg = ({
    (new Object).should.beNull;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("(new Object) should be null.");
  msg.split("\n")[1].strip.should.equal("Expected:null");
  msg.split("\n")[2].strip.strip.should.equal("Actual:object.Object");
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

  auto msg = ({
    otherObject.should.be.instanceOf!SomeClass;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.startWith(`otherObject should be instance of "fluentasserts.core.objects.__unittest_L57_C1.SomeClass".`);
  msg.split("\n")[1].strip.should.equal("Expected:typeof fluentasserts.core.objects.__unittest_L57_C1.SomeClass");
  msg.split("\n")[2].strip.should.equal("Actual:typeof fluentasserts.core.objects.__unittest_L57_C1.OtherClass");

  msg = ({
    otherObject.should.not.be.instanceOf!OtherClass;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.startWith(`otherObject should not be instance of "fluentasserts.core.objects.__unittest_L57_C1.OtherClass"`);
  msg.split("\n")[1].strip.should.equal("Expected:not typeof fluentasserts.core.objects.__unittest_L57_C1.OtherClass");
  msg.split("\n")[2].strip.should.equal("Actual:typeof fluentasserts.core.objects.__unittest_L57_C1.OtherClass");
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

  auto msg = ({
    otherObject.should.be.instanceOf!MyInterface;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.startWith(`otherObject should be instance of "fluentasserts.core.objects.__unittest_L91_C1.MyInterface".`);
  msg.split("\n")[1].strip.should.equal("Expected:typeof fluentasserts.core.objects.__unittest_L91_C1.MyInterface");
  msg.split("\n")[2].strip.should.equal("Actual:typeof fluentasserts.core.objects.__unittest_L91_C1.OtherClass");

  msg = ({
    someObject.should.not.be.instanceOf!MyInterface;
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.contain(`someObject should not be instance of "fluentasserts.core.objects.__unittest_L91_C1.MyInterface".`);
  msg.split("\n")[1].strip.should.equal("Expected:not typeof fluentasserts.core.objects.__unittest_L91_C1.MyInterface");
  msg.split("\n")[2].strip.should.equal("Actual:typeof fluentasserts.core.objects.__unittest_L91_C1.BaseClass");
}

@("delegates returning objects that throw propagate the exception")
unittest {
  class SomeClass { }

  SomeClass value() {
    throw new Exception("not implemented");
  }

  SomeClass noException() { return null; }

  value().should.throwAnyException.withMessage.equal("not implemented");

  bool thrown;

  try {
    noException.should.throwAnyException;
  } catch (TestException e) {
    e.msg.should.startWith("noException should throw any exception. No exception was thrown.");
    thrown = true;
  }

  thrown.should.equal(true);
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

  auto msg = ({
    instance.should.not.equal(instance);
  }).should.throwException!TestException.msg;

  msg.should.startWith("instance should not equal TestEqual");

  msg = ({
    instance.should.equal(new TestEqual(1));
  }).should.throwException!TestException.msg;

  msg.should.startWith("instance should equal TestEqual");
}

@("null object comparison")
unittest
{
  Object nullObject;

  auto msg = ({
    nullObject.should.equal(new Object);
  }).should.throwException!TestException.msg;

  msg.should.startWith("nullObject should equal Object(");

  msg = ({
    (new Object).should.equal(null);
  }).should.throwException!TestException.msg;

  msg.should.startWith("(new Object) should equal null.");
}
