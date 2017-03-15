module bdd.array;

public import bdd.base;

import std.algorithm;
import std.conv;
import std.traits;
import std.range;

struct ShouldList(T : T[]) {
  private const T[] testData;

  mixin ShouldCommons;

  void equal(const T[] valueList, const string file = __FILE__, const size_t line = __LINE__) {
    import bdd.numeric;
    addMessage("equal");
    addMessage("`" ~ valueList.to!string ~ "`");
    beginCheck;

    valueList.each!(value => contain(value, file, line));
    valueList.enumerate.each!((i, value) => value.should.equal(testData[i], file, line));
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
  import std.stdio;

  should.not.throwAnyException({
    [1, 2, 3].should.contain([2, 1]);
  });

  should.not.throwAnyException({
    [1, 2, 3].should.contain(1);
  });

  should.throwException!TestException({
    [1, 2, 3].should.contain([4, 5]);
  }).msg.should.contain("`4` is not present");

  should.throwException!TestException({
    [1, 2, 3].should.contain(4);
  }).msg.should.contain("`4` is not present");
}

@("array equals")
unittest {
  import std.stdio;

  should.not.throwAnyException({
    [1, 2, 3].should.equal([1, 2, 3]);
  });

  should.throwException!TestException({
    [1, 2, 3].should.equal([4, 5]);
  }).msg.should.contain("`4` is not present");
}
