module fluentasserts.core.array;

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

    if(expectedValue) {
      valueList.each!(value => contain(value, file, line));

      foreach(i; 0..valueList.length) {
        try {
          valueList[i].should.equal(testData[i], file, line);
        } catch(TestException e) {
          auto index = testData.countUntil(valueList[i]) + 1;
          auto msg = "`" ~ testData[i].to!string ~ "` should be at index `" ~ i.to!string ~ "` not `" ~ index.to!string ~ "`";

          result(false, testData.to!string, msg, file, line);
        }
      }
    } else {
      bool allEqual = valueList.length == testData.length;

      foreach(i; 0..valueList.length) {
        allEqual = allEqual && (valueList[i] == testData[i]);
      }

      result(allEqual, testData.to!string, valueList.to!string ~"`", file, line);
    }
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

    result(isPresent, strVal ~ (isPresent ? " is present" : " is not present") ~ " in `" ~ testData.to!string ~ "`", file, line);
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
  }).should.throwException!TestException.msg.split('\n')[0].should.contain("`4` is not present");

  ({
    [1, 2, 3].should.contain(4);
  }).should.throwException!TestException.msg.split('\n')[0].should.contain("`4` is not present");
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
  }).should.throwException!TestException.msg.should.startWith("[1, 2, 3] should equal `[4, 5]`. `4` is not present in `[1, 2, 3]");

  ({
    [1, 2].should.equal([4, 5]);
  }).should.throwException!TestException.msg.should.startWith("[1, 2] should equal `[4, 5]`. `4` is not present in `[1, 2]`");

  ({
    [1, 2, 3].should.equal([2, 3, 1]);
  }).should.throwException!TestException.msg.split('\n')[0].should.contain("`1` should be at index `0` not `2`");

  ({
    [1, 2, 3].should.not.equal([1, 2, 3]);
  }).should.throwException!TestException.msg.should.startWith("[1, 2, 3] should not equal `[1, 2, 3]`. `[1, 2, 3]` is equal to `[1, 2, 3]`");
}
