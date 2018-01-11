module fluentasserts.core.array;

import fluentasserts.core.results;
public import fluentasserts.core.base;

import std.algorithm;
import std.conv;
import std.traits;
import std.range;
import std.array;
import std.string;
import std.math;


U[] toValueList(U, V)(V expectedValueList) {
  static if(is(U == immutable) || is(U == const)) {
    return expectedValueList.array.idup;
  } else static if(is(V == void[])) {
    return [];
  } else {
    return expectedValueList.array.dup;
  }
}

struct ListComparison(T) {
  private {
    T[] referenceList;
    T[] list;
    double maxRelDiff;
  }

  this(U, V)(U reference, V list, double maxRelDiff = 0) {
    this.referenceList = toValueList!T(reference);
    this.list = list;
    this.maxRelDiff = maxRelDiff;
  }

  T[] missing() {
    T[] result;

    auto tmpList = list.dup;

    foreach(element; referenceList) {
      static if(std.traits.isNumeric!(T)) {
        auto index = tmpList.countUntil!(a => approxEqual(element, a, maxRelDiff));
      } else {
        auto index = tmpList.countUntil(element);
      }

      if(index == -1) {
        result ~= element;
      } else {
        tmpList = remove(tmpList, index);
      }
    }

    return result;
  }

  T[] extra() {
    T[] result;

    auto tmpReferenceList = referenceList.dup;

    foreach(element; list) {
      static if(isFloatingPoint!(T)) {
        auto index = tmpReferenceList.countUntil!(a => approxEqual(element, a, maxRelDiff));
      } else {
        auto index = tmpReferenceList.countUntil(element);
      }

      if(index == -1) {
        result ~= element;
      } else {
        tmpReferenceList = remove(tmpReferenceList, index);
      }
    }

    return result;
  }

  T[] common() {
    T[] result;

    auto tmpList = list.dup;

    foreach(element; referenceList) {
      if(tmpList.length == 0) {
        break;
      }

      static if(isFloatingPoint!(T)) {
        auto index = tmpList.countUntil!(a => approxEqual(element, a, maxRelDiff));
      } else {
        auto index = tmpList.countUntil(element);
      }

      if(index >= 0) {
        result ~= element;
        tmpList = std.algorithm.remove(tmpList, index);
      }
    }

    return result;
  }
}

/// ListComparison should be able to get the missing elements
unittest {
  auto comparison = ListComparison!int([1, 2, 3], [4]);

  auto missing = comparison.missing;

  assert(missing.length == 3);
  assert(missing[0] == 1);
  assert(missing[1] == 2);
  assert(missing[2] == 3);
}

/// ListComparison should be able to get the missing elements with duplicates
unittest {
  auto comparison = ListComparison!int([2, 2], [2]);

  auto missing = comparison.missing;

  assert(missing.length == 1);
  assert(missing[0] == 2);
}

/// ListComparison should be able to get the extra elements
unittest {
  auto comparison = ListComparison!int([4], [1, 2, 3]);

  auto extra = comparison.extra;

  assert(extra.length == 3);
  assert(extra[0] == 1);
  assert(extra[1] == 2);
  assert(extra[2] == 3);
}

/// ListComparison should be able to get the extra elements with duplicates
unittest {
  auto comparison = ListComparison!int([2], [2, 2]);

  auto extra = comparison.extra;

  assert(extra.length == 1);
  assert(extra[0] == 2);
}

/// ListComparison should be able to get the common elements
unittest {
  auto comparison = ListComparison!int([1, 2, 3, 4], [2, 3]);

  auto common = comparison.common;

  assert(common.length == 2);
  assert(common[0] == 2);
  assert(common[1] == 3);
}

/// ListComparison should be able to get the common elements with duplicates
unittest {
  auto comparison = ListComparison!int([2, 2, 2, 2], [2, 2]);

  auto common = comparison.common;

  assert(common.length == 2);
  assert(common[0] == 2);
  assert(common[1] == 2);
}

struct ShouldList(T) if(isInputRange!(T)) {
  private T testData;

  alias U = ElementType!T;
  mixin ShouldCommons;
  mixin DisabledShouldThrowableCommons;

  auto equal(V)(V expectedValueList, const string file = __FILE__, const size_t line = __LINE__) {
    U[] valueList = toValueList!U(expectedValueList);

    addMessage(" equal");
    addMessage(" `");
    addValue(valueList.to!string);
    addMessage("`");
    beginCheck;

    return approximately(expectedValueList, 0, file, line);
  }

  auto approximately(V)(V expectedValueList, double maxRelDiff = 1e-05, const string file = __FILE__, const size_t line = __LINE__) {
    import fluentasserts.core.basetype;

    U[] valueList = toValueList!U(expectedValueList);

    addMessage(" approximately");
    addMessage(" `");
    addValue(valueList.to!string);
    addMessage("`");
    beginCheck;

    auto comparison = ListComparison!U(valueList, testData.array, maxRelDiff);

    auto missing = comparison.missing;
    auto extra = comparison.extra;
    auto common = comparison.common;

    auto arrayTestData = testData.array;
    auto strArrayTestData = arrayTestData.to!string;

    static if(std.traits.isNumeric!(U)) {
      string strValueList;

      if(maxRelDiff == 0) {
        strValueList = valueList.to!string;
      } else {
        strValueList = "[" ~ valueList.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ") ~ "]";
      }
    } else {
      auto strValueList = valueList.to!string;
    }

    static if(std.traits.isNumeric!(U)) {
      string strMissing;

      if(maxRelDiff == 0 || missing.length == 0) {
        strMissing = missing.length == 0 ? "" : missing.to!string;
      } else {
        strMissing = "[" ~ missing.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ") ~ "]";
      }
    } else {
      string strMissing = missing.length == 0 ? "" : missing.to!string;
    }

    bool allEqual = valueList.length == arrayTestData.length;

    foreach(i; 0..valueList.length) {
      static if(std.traits.isNumeric!(U)) {
        allEqual = allEqual && approxEqual(valueList[i], arrayTestData[i], maxRelDiff);
      } else {
        allEqual = allEqual && (valueList[i] == arrayTestData[i]);
      }
    }

    if(expectedValue) {
      return result(allEqual, [], [
        cast(IResult) new ExpectedActualResult(strValueList, strArrayTestData),
        cast(IResult) new ExtraMissingResult(extra.length == 0 ? "" : extra.to!string, strMissing)
      ], file, line);
    } else {
      return result(allEqual, [], [
        cast(IResult) new ExpectedActualResult("not " ~ strValueList, strArrayTestData),
        cast(IResult) new ExtraMissingResult(extra.length == 0 ? "" : extra.to!string, strMissing)
      ], file, line);
    }
  }

  auto containOnly(V)(V expectedValueList, const string file = __FILE__, const size_t line = __LINE__) {
    U[] valueList = toValueList!U(expectedValueList);

    addMessage(" contain only ");
    addValue(valueList.to!string);
    beginCheck;

    auto comparison = ListComparison!U(testData.array, valueList);

    auto missing = comparison.missing;
    auto extra = comparison.extra;
    auto common = comparison.common;
    string missingString;
    string extraString;

    bool isSuccess;
    string expected;

    if(expectedValue) {
      isSuccess = missing.length == 0 && extra.length == 0 && common.length == valueList.length;

      if(extra.length > 0) {
        missingString = extra.to!string;
      }

      if(missing.length > 0) {
        extraString = missing.to!string;
      }

    } else {
      isSuccess = (missing.length != 0 || extra.length != 0) || common.length != valueList.length;
      isSuccess = !isSuccess;

      if(common.length > 0) {
        extraString = common.to!string;
      }
    }

    return result(isSuccess, [], [
          cast(IResult) new ExpectedActualResult("", testData.to!string),
          cast(IResult) new ExtraMissingResult(extraString, missingString)
      ], file, line);
  }

  auto contain(V)(V expectedValueList, const string file = __FILE__, const size_t line = __LINE__) {

    U[] valueList = toValueList!U(expectedValueList);

    addMessage(" contain ");
    addValue(valueList.to!string);
    beginCheck;

    auto comparison = ListComparison!U(testData.array, valueList);

    auto missing = comparison.missing;
    auto extra = comparison.extra;
    auto common = comparison.common;

    ulong[size_t] indexes;

    foreach(value; testData) {
      auto index = valueList.countUntil(value);

      if(index != -1) {
        indexes[index]++;
      }
    }

    auto found = indexes.keys.map!(a => valueList[a]).array;
    auto notFound = iota(0, valueList.length).filter!(a => !indexes.keys.canFind(a)).map!(a => valueList[a]).array;

    auto arePresent = indexes.keys.length == valueList.length;

    if(expectedValue) {
      string isString = notFound.length == 1 ? "is" : "are";

      return result(arePresent,
        [ Message(true, notFound.to!string),
          Message(false, " " ~ isString ~ " missing from "),
          Message(true, testData.to!string),
          Message(false, ".")
        ],
        [
          cast(IResult) new ExpectedActualResult("all of " ~ valueList.to!string, testData.to!string),
          cast(IResult) new ExtraMissingResult("", notFound.to!string)
        ], file, line);
    } else {
      string isString = found.length == 1 ? "is" : "are";

      return result(common.length != 0,
        [ Message(true, common.to!string),
          Message(false, " " ~ isString ~ " present in "),
          Message(true, testData.to!string),
          Message(false, ".")
        ],
        [
          cast(IResult) new ExpectedActualResult("none of " ~ valueList.to!string, testData.to!string),
          cast(IResult) new ExtraMissingResult(common.to!string, "")
        ],
        file, line);
    }
  }

  auto contain(U value, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" contain `");
    addValue(value.to!string);
    addMessage("`");

    beginCheck;

    auto isPresent = testData.canFind(value);
    auto msg = [
      Message(true, value.to!string),
      Message(false, isPresent ? " is present in " : " is missing from "),
      Message(true, testData.to!string),
      Message(false, ".")
    ];

    if(expectedValue) {
      return result(isPresent, msg, [
        cast(IResult) new ExpectedActualResult("to contain `" ~ value.to!string ~ "`", testData.to!string),
        cast(IResult) new ExtraMissingResult("", value.to!string)
      ], file, line);
    } else {
      return result(isPresent, msg, [
        cast(IResult) new ExpectedActualResult("to not contain `" ~ value.to!string ~ "`", testData.to!string),
        cast(IResult) new ExtraMissingResult(value.to!string, "")
      ], file, line);
    }
  }
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
  msg.split('\n')[2].strip.should.equal("Expected:all of [4, 5]");
  msg.split('\n')[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].map!"a".should.not.contain([1, 2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[1, 2, 3].map!\"a\" should not contain [1, 2]. [1, 2] are present in [1, 2, 3].");
  msg.split('\n')[2].strip.should.equal("Expected:none of [1, 2]");
  msg.split('\n')[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].map!"a".should.contain(4);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.contain("4 is missing from [1, 2, 3]");
  msg.split('\n')[2].strip.should.equal("Expected:to contain `4`");
  msg.split('\n')[3].strip.should.equal("Actual:[1, 2, 3]");
}

/// const range contain
unittest {
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
  data.map!"a".should.contain(data);
  [1, 2, 3].should.contain(data);

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

/// immutable range contain
unittest {
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.contain([2, 1]);
  data.map!"a".should.contain(data);
  [1, 2, 3].should.contain(data);

  ({
    data.map!"a * 4".should.not.contain(data);
  }).should.not.throwAnyException;
}

/// contain only
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
  msg.split('\n')[2].strip.should.equal("Actual:[1, 2, 3]");
  msg.split('\n')[4].strip.should.equal("Extra:[3]");

  msg = ({
    [1, 2].should.not.containOnly([2, 1]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].strip.should.equal("[1, 2] should not contain only [2, 1].");
  msg.split('\n')[2].strip.should.equal("Actual:[1, 2]");

  msg = ({
    [2, 2].should.containOnly([2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[2, 2] should contain only [2].");
  msg.split('\n')[2].strip.should.equal("Actual:[2, 2]");
  msg.split('\n')[4].strip.should.equal("Extra:[2]");

  msg = ({
    [3, 3].should.containOnly([2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[3, 3] should contain only [2].");
  msg.split('\n')[2].strip.should.equal("Actual:[3, 3]");
  msg.split('\n')[4].strip.should.equal("Extra:[3, 3]");
  msg.split('\n')[5].strip.should.equal("Missing:[2]");

  msg = ({
    [2, 2].should.not.containOnly([2, 2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[2, 2] should not contain only [2, 2].");
  msg.split('\n')[2].strip.should.equal("Actual:[2, 2]");
  msg.split('\n')[4].strip.should.equal("Extra:[2, 2]");
}

/// contain only with  void array
unittest {
  int[] list;
  list.should.containOnly([]);
}


/// const range containOnly
unittest {
  const(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([3, 2, 1]);
  data.map!"a".should.containOnly(data);
  [1, 2, 3].should.containOnly(data);

  ({
    data.map!"a * 4".should.not.containOnly(data);
  }).should.not.throwAnyException;
}

/// immutable range containOnly
unittest {
  immutable(int)[] data = [1, 2, 3];
  data.map!"a".should.containOnly([2, 1, 3]);
  data.map!"a".should.containOnly(data);
  [1, 2, 3].should.containOnly(data);

  ({
    data.map!"a * 4".should.not.containOnly(data);
  }).should.not.throwAnyException;
}

/// array contain
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
  msg[2].strip.should.equal("Expected:all of [4, 5]");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");
  msg[5].strip.should.equal("Missing:[4, 5]");

  msg = ({
    [1, 2, 3].should.not.contain([2, 3]);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should not contain [2, 3]. [2, 3] are present in [1, 2, 3].");
  msg[2].strip.should.equal("Expected:none of [2, 3]");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");
  msg[5].strip.should.equal("Extra:[2, 3]");

  msg = ({
    [1, 2, 3].should.not.contain([4, 3]);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should not contain [4, 3]. [3] is present in [1, 2, 3].");
  msg[2].strip.should.equal("Expected:none of [4, 3]");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");
  msg[5].strip.should.equal("Extra:[3]");

  msg = ({
    [1, 2, 3].should.contain(4);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should contain `4`. 4 is missing from [1, 2, 3].");
  msg[2].strip.should.equal("Expected:to contain `4`");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");
  msg[5].strip.should.equal("Missing:4");

  msg = ({
    [1, 2, 3].should.not.contain(2);
  }).should.throwException!TestException.msg.split('\n');

  msg[0].should.equal("[1, 2, 3] should not contain `2`. 2 is present in [1, 2, 3].");
  msg[2].strip.should.equal("Expected:to not contain `2`");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");
  msg[5].strip.should.equal("Extra:2");
}

/// array equals
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

  msg[0].strip.should.equal("[1, 2, 3] should equal `[4, 5]`.");
  msg[2].strip.should.equal("Expected:[4, 5]");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2].should.equal([4, 5]);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.equal("[1, 2] should equal `[4, 5]`.");
  msg[2].strip.should.equal("Expected:[4, 5]");
  msg[3].strip.should.equal("Actual:[1, 2]");
  msg[5].strip.should.equal("Extra:[1, 2]");
  msg[6].strip.should.equal("Missing:[4, 5]");

  msg = ({
    [1, 2, 3].should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.equal("[1, 2, 3] should equal `[2, 3, 1]`.");
  msg[2].strip.should.equal("Expected:[2, 3, 1]");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg.split("\n");

  msg[0].strip.should.startWith("[1, 2, 3] should not equal `[1, 2, 3]`");
  msg[2].strip.should.equal("Expected:not [1, 2, 3]");
  msg[3].strip.should.equal("Actual:[1, 2, 3]");
}

///array equals with structs
unittest {
  struct TestStruct {
    int value;

    void f() {}
  }

  ({
    [TestStruct(1)].should.equal([TestStruct(1)]);
  }).should.not.throwAnyException;

  ({
    [TestStruct(2)].should.equal([TestStruct(1)]);
  }).should.throwException!TestException.withMessage.startWith("[TestStruct(2)] should equal `[TestStruct(1, null)]`");
}

/// const array equal
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

///array equals with classes
unittest {

  ({
    auto instance = new TestEqualsClass(1);
    [instance].should.equal([instance]);
  }).should.not.throwAnyException;

  ({
    [new TestEqualsClass(2)].should.equal([new TestEqualsClass(1)]);
  }).should.throwException!TestException.withMessage.startWith("[new TestEqualsClass(2)] should equal `[fluentasserts.core.array.TestEqualsClass]`.");
}

/// range equals
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

  msg.split("\n")[0].strip.should.equal("[1, 2, 3].map!\"a\" should equal `[4, 5]`.");
  msg.split("\n")[2].strip.should.equal("Expected:[4, 5]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2].map!"a".should.equal([4, 5]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("[1, 2].map!\"a\" should equal `[4, 5]`.");
  msg.split("\n")[2].strip.should.equal("Expected:[4, 5]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2]");

  msg = ({
    [1, 2, 3].map!"a".should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("[1, 2, 3].map!\"a\" should equal `[2, 3, 1]`.");
  msg.split("\n")[2].strip.should.equal("Expected:[2, 3, 1]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].map!"a".should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("[1, 2, 3].map!\"a\" should not equal `[1, 2, 3]`");
  msg.split("\n")[2].strip.should.equal("Expected:not [1, 2, 3]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");
}

/// custom range asserts
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

  msg.split("\n")[0].strip.should.startWith("Range() should equal `[0, 1]`");
  msg.split("\n")[2].strip.should.equal("Expected:[0, 1]");
  msg.split("\n")[3].strip.should.equal("Actual:[0, 1, 2]");

  msg = ({
    Range().should.contain([2, 3]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("Range() should contain [2, 3]. [3] is missing from [0, 1, 2].");
  msg.split("\n")[2].strip.should.equal("Expected:all of [2, 3]");
  msg.split("\n")[3].strip.should.equal("Actual:[0, 1, 2]");

  msg = ({
    Range().should.contain(3);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("Range() should contain `3`. 3 is missing from [0, 1, 2].");
  msg.split("\n")[2].strip.should.equal("Expected:to contain `3`");
  msg.split("\n")[3].strip.should.equal("Actual:[0, 1, 2]");
}

/// custom const range equals
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

/// custom immutable range equals
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

/// approximately equals
unittest {
  [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.01);

  ({
    [0.350, 0.501, 0.341].should.not.be.approximately([0.35, 0.50, 0.34], 0.00001);
    [0.350, 0.501, 0.341].should.not.be.approximately([0.501, 0.350, 0.341], 0.001);
    [0.350, 0.501, 0.341].should.not.be.approximately([0.350, 0.501], 0.001);
    [0.350, 0.501].should.not.be.approximately([0.350, 0.501, 0.341], 0.001);
  }).should.not.throwAnyException;

  auto msg = ({
    [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.0001);
  }).should.throwException!TestException.msg;

  msg.should.contain("Expected:[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
  msg.should.contain("Missing:[0.5±0.0001, 0.34±0.0001]");
}