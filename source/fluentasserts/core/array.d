module fluentasserts.core.array;

public import fluentasserts.core.listcomparison;

version(unittest) {
  import fluentasserts.core.base;
  import std.algorithm : map;
  import std.string : split, strip;
}

@("lazy array that throws propagates the exception")
unittest {
  int[] someLazyArray() {
    throw new Exception("This is it.");
  }

  ({
    someLazyArray.should.equal([]);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyArray.should.approximately([], 3);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyArray.should.contain([]);
  }).should.throwAnyException.withMessage("This is it.");

  ({
    someLazyArray.should.contain(3);
  }).should.throwAnyException.withMessage("This is it.");
}

@("range contain")
unittest {
  ({
    [1, 2, 3].map!"a".should.contain([2, 1]);
    [1, 2, 3].map!"a".should.not.contain([4, 5, 6, 7]);
  }).should.not.throwException!TestException;

  ({
    [1, 2, 3].map!"a".should.contain(1);
  }).should.not.throwException!TestException;

  auto msg = ({
    [1, 2, 3].map!"a".should.contain([4, 5]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[1, 2, 3].map!\"a\" should contain [4, 5]. [4, 5] are missing from [1, 2, 3].");

  msg = ({
    [1, 2, 3].map!"a".should.not.contain([1, 2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[1, 2, 3].map!\"a\" should not contain [1, 2]. [1, 2] are present in [1, 2, 3].");

  msg = ({
    [1, 2, 3].map!"a".should.contain(4);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.contain("4 is missing from [1, 2, 3]");
}

@("const range contain")
unittest {
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
  data.map!"a".should.contain(data);
  [1, 2, 3].should.contain(data);

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

@("immutable range contain")
unittest {
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
  data.map!"a".should.contain(data);
  [1, 2, 3].should.contain(data);

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

@("contain only")
unittest {
  ({
    [1, 2, 3].should.containOnly([3, 2, 1]);
    [1, 2, 3].should.not.containOnly([2, 1]);

    [1, 2, 2].should.not.containOnly([2, 1]);
    [1, 2, 2].should.containOnly([2, 1, 2]);

    [2, 2].should.containOnly([2, 2]);
    [2, 2, 2].should.not.containOnly([2, 2]);
  }).should.not.throwException!TestException;

  auto msg = ({
    [1, 2, 3].should.containOnly([2, 1]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[1, 2, 3] should contain only [2, 1].");

  msg = ({
    [1, 2].should.not.containOnly([2, 1]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].strip.should.equal("[1, 2] should not contain only [2, 1].");

  msg = ({
    [2, 2].should.containOnly([2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[2, 2] should contain only [2].");

  msg = ({
    [3, 3].should.containOnly([2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[3, 3] should contain only [2].");

  msg = ({
    [2, 2].should.not.containOnly([2, 2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[2, 2] should not contain only [2, 2].");
}

@("contain only with void array")
unittest {
  int[] list;
  list.should.containOnly([]);
}


@("const range containOnly")
unittest {
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([3, 2, 1]);
  data.map!"a".should.containOnly(data);
  [1, 2, 3].should.containOnly(data);

  ({
    data.map!"a * 4".should.not.containOnly(data);
  }).should.not.throwAnyException;
}

@("immutable range containOnly")
unittest {
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([2, 1, 3]);
  data.map!"a".should.containOnly(data);
  [1, 2, 3].should.containOnly(data);

  ({
    data.map!"a * 4".should.not.containOnly(data);
  }).should.not.throwAnyException;
}

@("array contain")
unittest {
  ({
    [1, 2, 3].should.contain([2, 1]);
    [1, 2, 3].should.not.contain([4, 5, 6, 7]);

    [1, 2, 3].should.contain(1);
  }).should.not.throwException!TestException;

  auto msg = ({
    [1, 2, 3].should.contain([4, 5]);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should contain [4, 5]. [4, 5] are missing from [1, 2, 3].");

  msg = ({
    [1, 2, 3].should.not.contain([2, 3]);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should not contain [2, 3]. [2, 3] are present in [1, 2, 3].");

  msg = ({
    [1, 2, 3].should.not.contain([4, 3]);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should not contain [4, 3]. 3 is present in [1, 2, 3].");

  msg = ({
    [1, 2, 3].should.contain(4);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should contain 4. 4 is missing from [1, 2, 3].");

  msg = ({
    [1, 2, 3].should.not.contain(2);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should not contain 2. 2 is present in [1, 2, 3].");
}

@("array equals")
unittest {
  ({
    [1, 2, 3].should.equal([1, 2, 3]);
  }).should.not.throwAnyException;

  ({
    [1, 2, 3].should.not.equal([2, 1, 3]);
    [1, 2, 3].should.not.equal([2, 3]);
    [2, 3].should.not.equal([1, 2, 3]);
  }).should.not.throwAnyException;

  auto msg = ({
    [1, 2, 3].should.equal([4, 5]);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.startWith("[1, 2, 3] should equal [4, 5].");

  msg = ({
    [1, 2].should.equal([4, 5]);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.startWith("[1, 2] should equal [4, 5].");

  msg = ({
    [1, 2, 3].should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.startWith("[1, 2, 3] should equal [2, 3, 1].");

  msg = ({
    [1, 2, 3].should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.startWith("[1, 2, 3] should not equal [1, 2, 3]");
}

@("array equals with structs")
unittest {
  struct TestStruct {
    int value;

    void f() {}
  }

  ({
    [TestStruct(1)].should.equal([TestStruct(1)]);
  }).should.not.throwAnyException;

  auto msg = ({
    [TestStruct(2)].should.equal([TestStruct(1)]);
  }).should.throwException!TestException.msg;

  msg.should.startWith("[TestStruct(2)] should equal [TestStruct(1)].");
}

@("const array equal")
unittest {
  const(string)[] constValue = ["test", "string"];
  immutable(string)[] immutableValue = ["test", "string"];

  constValue.should.equal(["test", "string"]);
  immutableValue.should.equal(["test", "string"]);

  ["test", "string"].should.equal(constValue);
  ["test", "string"].should.equal(immutableValue);
}

version(unittest) {
  class TestEqualsClass {
    int value;

    this(int value) { this.value = value; }
    void f() {}
  }
}

@("array equals with classes")
unittest {

  ({
    auto instance = new TestEqualsClass(1);
    [instance].should.equal([instance]);
  }).should.not.throwAnyException;

  ({
    [new TestEqualsClass(2)].should.equal([new TestEqualsClass(1)]);
  }).should.throwException!TestException;
}

@("range equals")
unittest {
  ({
    [1, 2, 3].map!"a".should.equal([1, 2, 3]);
  }).should.not.throwAnyException;

  ({
    [1, 2, 3].map!"a".should.not.equal([2, 1, 3]);
    [1, 2, 3].map!"a".should.not.equal([2, 3]);
    [2, 3].map!"a".should.not.equal([1, 2, 3]);
  }).should.not.throwAnyException;

  auto msg = ({
    [1, 2, 3].map!"a".should.equal([4, 5]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith(`[1, 2, 3].map!"a" should equal [4, 5].`);

  msg = ({
    [1, 2].map!"a".should.equal([4, 5]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith(`[1, 2].map!"a" should equal [4, 5].`);

  msg = ({
    [1, 2, 3].map!"a".should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith(`[1, 2, 3].map!"a" should equal [2, 3, 1].`);

  msg = ({
    [1, 2, 3].map!"a".should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith(`[1, 2, 3].map!"a" should not equal [1, 2, 3]`);
}

@("custom range asserts")
unittest {
  struct Range {
    int n;
    int front() {
      return n;
    }
    void popFront() {
      ++n;
    }
    bool empty() {
      return n == 3;
    }
  }

  Range().should.equal([0,1,2]);
  Range().should.contain([0,1]);
  Range().should.contain(0);

  auto msg = ({
    Range().should.equal([0,1]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("Range() should equal [0, 1]");

  msg = ({
    Range().should.contain([2, 3]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("Range() should contain [2, 3]. 3 is missing from [0, 1, 2].");

  msg = ({
    Range().should.contain(3);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("Range() should contain 3. 3 is missing from [0, 1, 2].");
}

@("custom const range equals")
unittest {
  struct ConstRange {
    int n;
    const(int) front() {
      return n;
    }

    void popFront() {
      ++n;
    }

    bool empty() {
      return n == 3;
    }
  }

  [0,1,2].should.equal(ConstRange());
  ConstRange().should.equal([0,1,2]);
}

@("custom immutable range equals")
unittest {
  struct ImmutableRange {
    int n;
    immutable(int) front() {
      return n;
    }

    void popFront() {
      ++n;
    }

    bool empty() {
      return n == 3;
    }
  }

  [0,1,2].should.equal(ImmutableRange());
  ImmutableRange().should.equal([0,1,2]);
}

@("approximately equals")
unittest {
  [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.01);

  [0.350, 0.501, 0.341].should.not.be.approximately([0.35, 0.50, 0.34], 0.00001);
  [0.350, 0.501, 0.341].should.not.be.approximately([0.501, 0.350, 0.341], 0.001);
  [0.350, 0.501, 0.341].should.not.be.approximately([0.350, 0.501], 0.001);
  [0.350, 0.501].should.not.be.approximately([0.350, 0.501, 0.341], 0.001);

  auto msg = ({
    [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.0001);
  }).should.throwException!TestException.msg;

  msg.should.contain("Expected:[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
  msg.should.contain("Missing:0.501±0.0001,0.341±0.0001");
}

@("approximately equals with Assert")
unittest {
  Assert.approximately([0.350, 0.501, 0.341], [0.35, 0.50, 0.34], 0.01);
  Assert.notApproximately([0.350, 0.501, 0.341], [0.350, 0.501], 0.0001);
}

@("immutable string")
unittest {
  immutable string[] someList;

  someList.should.equal([]);
}

@("compare const objects")
unittest {
  class A {}
  A a = new A();
  const(A)[] arr = [a];
  arr.should.equal([a]);
}