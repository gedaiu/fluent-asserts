module fluentasserts.assertions.array;

public import fluentasserts.assertions.listcomparison;

version(unittest) {
  import fluentasserts.core.base;
  import std.algorithm : map;
  import std.string : split, strip;

  import fluentasserts.core.lifecycle;}

@("lazy array that throws propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
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
  [1, 2, 3].map!"a".should.contain([2, 1]);
  [1, 2, 3].map!"a".should.not.contain([4, 5, 6, 7]);
  [1, 2, 3].map!"a".should.contain(1);

  auto evaluation = ({
    [1, 2, 3].map!"a".should.contain([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("[4, 5] are missing from [1, 2, 3].");

  evaluation = ({
    [1, 2, 3].map!"a".should.not.contain([1, 2]);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("[1, 2] are present in [1, 2, 3].");

  evaluation = ({
    [1, 2, 3].map!"a".should.contain(4);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("4 is missing from [1, 2, 3]");
}

@("const range contain")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
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
  Lifecycle.instance.disableFailureHandling = false;
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
  [1, 2, 3].should.containOnly([3, 2, 1]);
  [1, 2, 3].should.not.containOnly([2, 1]);

  [1, 2, 2].should.not.containOnly([2, 1]);
  [1, 2, 2].should.containOnly([2, 1, 2]);

  [2, 2].should.containOnly([2, 2]);
  [2, 2, 2].should.not.containOnly([2, 2]);

  auto evaluation = ({
    [1, 2, 3].should.containOnly([2, 1]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should contain only [2, 1].");

  evaluation = ({
    [1, 2].should.not.containOnly([2, 1]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2] should not contain only [2, 1].");

  evaluation = ({
    [2, 2].should.containOnly([2]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[2, 2] should contain only [2].");

  evaluation = ({
    [3, 3].should.containOnly([2]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[3, 3] should contain only [2].");

  evaluation = ({
    [2, 2].should.not.containOnly([2, 2]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[2, 2] should not contain only [2, 2].");
}

@("contain only with void array")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[] list;
  list.should.containOnly([]);
}


@("const range containOnly")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
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
  Lifecycle.instance.disableFailureHandling = false;
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
  [1, 2, 3].should.contain([2, 1]);
  [1, 2, 3].should.not.contain([4, 5, 6, 7]);
  [1, 2, 3].should.contain(1);

  auto evaluation = ({
    [1, 2, 3].should.contain([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should contain [4, 5]. [4, 5] are missing from [1, 2, 3].");

  evaluation = ({
    [1, 2, 3].should.not.contain([2, 3]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should not contain [2, 3]. [2, 3] are present in [1, 2, 3].");

  evaluation = ({
    [1, 2, 3].should.not.contain([4, 3]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should not contain [4, 3]. 3 is present in [1, 2, 3].");

  evaluation = ({
    [1, 2, 3].should.contain(4);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should contain 4. 4 is missing from [1, 2, 3].");

  evaluation = ({
    [1, 2, 3].should.not.contain(2);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should not contain 2. 2 is present in [1, 2, 3].");
}

@("array equals")
unittest {
  [1, 2, 3].should.equal([1, 2, 3]);

  [1, 2, 3].should.not.equal([2, 1, 3]);
  [1, 2, 3].should.not.equal([2, 3]);
  [2, 3].should.not.equal([1, 2, 3]);

  auto evaluation = ({
    [1, 2, 3].should.equal([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should equal [4, 5].");

  evaluation = ({
    [1, 2].should.equal([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2] should equal [4, 5].");

  evaluation = ({
    [1, 2, 3].should.equal([2, 3, 1]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should equal [2, 3, 1].");

  evaluation = ({
    [1, 2, 3].should.not.equal([1, 2, 3]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[1, 2, 3] should not equal [1, 2, 3]");
}

@("array equals with structs")
unittest {
  struct TestStruct {
    int value;

    void f() {}
  }

  [TestStruct(1)].should.equal([TestStruct(1)]);

  auto evaluation = ({
    [TestStruct(2)].should.equal([TestStruct(1)]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("[TestStruct(2)] should equal [TestStruct(1)].");
}

@("const array equal")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
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
  auto instance = new TestEqualsClass(1);
  [instance].should.equal([instance]);

  auto evaluation = ({
    [new TestEqualsClass(2)].should.equal([new TestEqualsClass(1)]);
  }).recordEvaluation;

  evaluation.result.hasContent.should.equal(true);
}

@("range equals")
unittest {
  [1, 2, 3].map!"a".should.equal([1, 2, 3]);

  [1, 2, 3].map!"a".should.not.equal([2, 1, 3]);
  [1, 2, 3].map!"a".should.not.equal([2, 3]);
  [2, 3].map!"a".should.not.equal([1, 2, 3]);

  auto evaluation = ({
    [1, 2, 3].map!"a".should.equal([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith(`[1, 2, 3].map!"a" should equal [4, 5].`);

  evaluation = ({
    [1, 2].map!"a".should.equal([4, 5]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith(`[1, 2].map!"a" should equal [4, 5].`);

  evaluation = ({
    [1, 2, 3].map!"a".should.equal([2, 3, 1]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith(`[1, 2, 3].map!"a" should equal [2, 3, 1].`);

  evaluation = ({
    [1, 2, 3].map!"a".should.not.equal([1, 2, 3]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith(`[1, 2, 3].map!"a" should not equal [1, 2, 3]`);
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

  auto evaluation = ({
    Range().should.equal([0,1]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("Range() should equal [0, 1]");

  evaluation = ({
    Range().should.contain([2, 3]);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("Range() should contain [2, 3]. 3 is missing from [0, 1, 2].");

  evaluation = ({
    Range().should.contain(3);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("Range() should contain 3. 3 is missing from [0, 1, 2].");
}

@("custom const range equals")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
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
  Lifecycle.instance.disableFailureHandling = false;
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

  auto evaluation = ({
    [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.0001);
  }).recordEvaluation;

  evaluation.result.expected.should.equal("[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
  evaluation.result.missing.length.should.equal(2);
}

@("approximately equals with Assert")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Assert.approximately([0.350, 0.501, 0.341], [0.35, 0.50, 0.34], 0.01);
  Assert.notApproximately([0.350, 0.501, 0.341], [0.350, 0.501], 0.0001);
}

@("immutable string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable string[] someList;

  someList.should.equal([]);
}

@("compare const objects")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  class A {}
  A a = new A();
  const(A)[] arr = [a];
  arr.should.equal([a]);
}