module fluentasserts.core.numeric;

public import fluentasserts.core.base;

import std.string;
import std.conv;
import std.algorithm;

struct ShouldNumeric(T) {
  private const T testData;

  mixin ShouldCommons;

  void equal(const T someValue, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage("equal");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isSame = testData == someValue;

    result(isSame, "`" ~ testData.to!string ~ "`" ~ (isSame ? " is equal" : " is not equal") ~ " to `" ~ someValue.to!string ~"`.", file, line);
  }

  void graterThan(const T someValue, const string file = __FILE__, const size_t line = __LINE__){
    addMessage("greater then");
    addMessage("`" ~ someValue.to!string ~ "`");
    beginCheck;

    auto isGreater = testData > someValue;

    result(isGreater, "`" ~ testData.to!string ~ "`" ~ (isGreater ? " is greater" : " is not greater") ~ " than `" ~ someValue.to!string ~"`.", file, line);
  }
}
