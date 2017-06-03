module fluentasserts.core.array;

import fluentasserts.core.results;
public import fluentasserts.core.base;

import std.algorithm;
import std.conv;
import std.traits;
import std.range;
import std.array;

struct ShouldList(T : T[]) {
  private const T[] testData;

  mixin ShouldCommons;

  void equal(T)(const T[] valueList, const string file = __FILE__, const size_t line = __LINE__) {
    import fluentasserts.core.basetype;
    addMessage("equal");
    addMessage("`" ~ valueList.to!string ~ "`");
    beginCheck;

    bool allEqual = valueList.length == testData.length;

    foreach(i; 0..valueList.length) {
      allEqual = allEqual && (valueList[i] == testData[i]);
    }

    result(allEqual, new DiffResult(valueList.to!string, testData.to!string), file, line);
  }

  void contain(const T[] valueList, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("contain");
    addMessage("`" ~ valueList.to!string ~ "`");
    beginCheck;

    valueList.each!(value => contain(value, file, line));
  }

  void contain(const T value, const string file = __FILE__, const size_t line = __LINE__) {
    auto strVal = "`" ~ value.to!string ~ "`";

    addMessage("contain");
    addMessage(strVal);
    beginCheck;

    auto isPresent = testData.canFind(value);
    auto msg = strVal ~ (isPresent ? " is present in " : " is missing from ") ~ testData.to!string ~ "`";

    result(isPresent, msg, new ExpectedActualResult(" to contain " ~ value.to!string, testData.to!string), file, line);
  }
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
  }).should.throwException!TestException.msg.split('\n')[0].should.contain("`4` is missing from [1, 2, 3]");

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

  ({
    [1, 2, 3].should.equal([4, 5]);
  }).should.throwException!TestException.msg.should.startWith("[1, 2, 3] should equal `[4, 5]");

  ({
    [1, 2].should.equal([4, 5]);
  }).should.throwException!TestException.msg.should.startWith("[1, 2] should equal `[4, 5]");

  ({
    [1, 2, 3].should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg.should.contain("`1` should be at index `0` not `2`");

  ({
    [1, 2, 3].should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg.should.startWith("[1, 2, 3] should not equal `[1, 2, 3]`");
}
