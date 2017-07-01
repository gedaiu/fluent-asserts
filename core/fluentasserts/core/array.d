module fluentasserts.core.array;

import fluentasserts.core.results;
public import fluentasserts.core.base;

import std.algorithm;
import std.conv;
import std.traits;
import std.range;
import std.array;
import std.string;

struct ShouldList(T) if(isInputRange!(T)) {
  private T testData;
  
  alias U = ElementType!T;
  mixin ShouldCommons;

  auto equal(T)(const T[] valueList, const string file = __FILE__, const size_t line = __LINE__) {
    import fluentasserts.core.basetype;
    addMessage("equal");
    addMessage("`" ~ valueList.to!string ~ "`");
    beginCheck;

    auto arrayTestData = testData.array;

    bool allEqual = valueList.length == arrayTestData.length;

    foreach(i; 0..valueList.length) {
      allEqual = allEqual && (valueList[i] == arrayTestData[i]);
    }

    if(expectedValue) {
      return result(allEqual,"", cast(IResult[]) [ 
        new ExpectedActualResult(valueList.to!string, arrayTestData.to!string), 
        new DiffResult(valueList.to!string, arrayTestData.to!string) 
      ], file, line);
    } else {
      return result(allEqual, 
        cast(IResult) new ExpectedActualResult("not " ~ valueList.to!string, arrayTestData.to!string), 
        file, line);
    }
  }

  auto contain(const U[] valueList, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("contain");
    addMessage(valueList.to!string);
    beginCheck;

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
        notFound.to!string ~ " " ~ isString ~ " missing from " ~ testData.to!string ~ ".", 
        new ExpectedActualResult("all of " ~ valueList.to!string, testData.to!string), 
        file, line);
    } else {
      string isString = found.length == 1 ? "is" : "are";

      return result(arePresent, 
        found.to!string ~ " " ~ isString ~ " present in " ~ testData.to!string ~ ".", 
        new ExpectedActualResult("none of " ~ valueList.to!string, testData.to!string), 
        file, line);
    }
  }

  auto contain(const U value, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ value.to!string ~ "`";

    addMessage("contain");
    addMessage(strVal);
    beginCheck;

    auto isPresent = testData.canFind(value);
    auto msg = strVal ~ (isPresent ? " is present in " : " is missing from ") ~ testData.to!string ~ ".";

    return result(isPresent, msg, new ExpectedActualResult("to contain `" ~ value.to!string ~ "`", testData.to!string), file, line);
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
  msg.split('\n')[2].should.equal("Expected:all of [4, 5]");
  msg.split('\n')[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].map!"a".should.not.contain([1, 2]);
  }).should.throwException!TestException.msg;

  msg.split('\n')[0].should.equal("[1, 2, 3].map!\"a\" should not contain [1, 2]. [1, 2] are present in [1, 2, 3].");
  msg.split('\n')[2].should.equal("Expected:none of [1, 2]");
  msg.split('\n')[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].map!"a".should.contain(4);
  }).should.throwException!TestException.msg;
  
  msg.split('\n')[0].should.contain("`4` is missing from [1, 2, 3]");
  msg.split('\n')[2].should.equal("Expected:to contain `4`");
  msg.split('\n')[3].strip.should.equal("Actual:[1, 2, 3]");
}

@("array contain")
unittest {
  ({
    [1, 2, 3].should.contain([2, 1]);
    [1, 2, 3].should.not.contain([4, 5, 6, 7]);
  }).should.not.throwException!TestException;

  ({
    [1, 2, 3].should.contain(1);
  }).should.not.throwException!TestException;

  ({
    [1, 2, 3].should.contain([4, 5]);
  }).should.throwException!TestException.msg.split('\n')[0].should.contain("[4, 5] are missing from [1, 2, 3]");

  ({
    [1, 2, 3].should.contain(4);
  }).should.throwException!TestException.msg.split('\n')[0].should.contain("`4` is missing from [1, 2, 3]");
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
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("[1, 2, 3] should equal `[4, 5]`.");
  msg.split("\n")[2].should.equal("Expected:[4, 5]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2].should.equal([4, 5]);
  }).should.throwException!TestException.msg;
  
  msg.split("\n")[0].strip.should.equal("[1, 2] should equal `[4, 5]`.");
  msg.split("\n")[2].should.equal("Expected:[4, 5]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2]");

  msg = ({
    [1, 2, 3].should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("[1, 2, 3] should equal `[2, 3, 1]`.");
  msg.split("\n")[2].should.equal("Expected:[2, 3, 1]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("[1, 2, 3] should not equal `[1, 2, 3]`");
  msg.split("\n")[2].should.equal("Expected:not [1, 2, 3]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");
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
  msg.split("\n")[2].should.equal("Expected:[4, 5]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2].map!"a".should.equal([4, 5]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("[1, 2].map!\"a\" should equal `[4, 5]`.");
  msg.split("\n")[2].should.equal("Expected:[4, 5]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2]");

  msg = ({
    [1, 2, 3].map!"a".should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("[1, 2, 3].map!\"a\" should equal `[2, 3, 1]`.");
  msg.split("\n")[2].should.equal("Expected:[2, 3, 1]");
  msg.split("\n")[3].strip.should.equal("Actual:[1, 2, 3]");

  msg = ({
    [1, 2, 3].map!"a".should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("[1, 2, 3].map!\"a\" should not equal `[1, 2, 3]`");
  msg.split("\n")[2].should.equal("Expected:not [1, 2, 3]");
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
  msg.split("\n")[2].should.equal("Expected:[0, 1]");
  msg.split("\n")[3].strip.should.equal("Actual:[0, 1, 2]");

  msg = ({
    Range().should.contain([2, 3]);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("Range() should contain [2, 3]. [3] is missing from [0, 1, 2].");
  msg.split("\n")[2].should.equal("Expected:all of [2, 3]");
  msg.split("\n")[3].strip.should.equal("Actual:[0, 1, 2]");

  msg = ({
    Range().should.contain(3);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.startWith("Range() should contain `3`. `3` is missing from [0, 1, 2].");
  msg.split("\n")[2].should.equal("Expected:to contain `3`");
  msg.split("\n")[3].strip.should.equal("Actual:[0, 1, 2]");
}
