module fluentasserts.core.base;

public import fluentasserts.core.array;
public import fluentasserts.core.string;
public import fluentasserts.core.objects;
public import fluentasserts.core.basetype;
public import fluentasserts.core.results;
public import fluentasserts.core.lifecycle;
public import fluentasserts.core.expect;
public import fluentasserts.core.evaluation;

import std.traits;
import std.stdio;
import std.algorithm;
import std.array;
import std.range;
import std.conv;
import std.string;
import std.file;
import std.datetime;
import std.range.primitives;
import std.typecons;

@safe:

version(Have_unit_threaded) {
  import unit_threaded.should;
  alias ReferenceException = UnitTestException;
} else {
  alias ReferenceException = Exception;
}

class TestException : ReferenceException {
  private {
    immutable(Message)[] messages;
  }

  this(string message, string fileName, size_t line, Throwable next = null) {
    super(message ~ '\n', fileName, line, next);
  }

  this(immutable(Message)[] messages, string fileName, size_t line, Throwable next = null) {
    string msg;
    foreach(m; messages) {
      msg ~= m.toString;
    }
    msg ~= '\n';
    this.messages = messages;

    super(msg, fileName, line, next);
  }

  void print(ResultPrinter printer) {
    foreach(message; messages) {
      printer.print(message);
    }
    printer.primary("\n");
  }
}

auto should(T)(lazy T testData, const string file = __FILE__, const size_t line = __LINE__) @trusted {
  static if(is(T == void)) {
    auto callable = ({ testData; });
    return expect(callable, file, line);
  } else {
    return expect(testData, file, line);
  }
}

@("because adds a text before the assert message")
unittest {
  auto msg = ({
    true.should.equal(false).because("of test reasons");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Because of test reasons, true should equal false. ");
}

struct Assert {
  static void opDispatch(string s, T, U)(T actual, U expected, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto sh = expect(actual);

    static if(s[0..3] == "not") {
      sh.not;
      enum assertName = s[3..4].toLower ~ s[4..$];
    } else {
      enum assertName = s;
    }

    static if(assertName == "greaterThan" ||
              assertName == "lessThan" ||
              assertName == "above" ||
              assertName == "below" ||
              assertName == "between" ||
              assertName == "within" ||
              assertName == "approximately") {
      sh.be;
    }

    mixin("auto result = sh." ~ assertName ~ "(expected);");

    if(reason != "") {
      result.because(reason);
    }
  }

  static void between(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notBetween(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).not.to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void within(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notWithin(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).not.to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void approximately(T, U, V)(T actual, U expected, V delta, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.be.approximately(expected, delta);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notApproximately(T, U, V)(T actual, U expected, V delta, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).not.to.be.approximately(expected, delta);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void beNull(T)(T actual, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.beNull;

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notNull(T)(T actual, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).not.to.beNull;

    if(reason != "") {
      s.because(reason);
    }
  }
}

@("Assert works for base types")
unittest {
  Assert.equal(1, 1, "they are the same value");
  Assert.notEqual(1, 2, "they are not the same value");

  Assert.greaterThan(1, 0);
  Assert.notGreaterThan(0, 1);

  Assert.lessThan(0, 1);
  Assert.notLessThan(1, 0);

  Assert.above(1, 0);
  Assert.notAbove(0, 1);

  Assert.below(0, 1);
  Assert.notBelow(1, 0);

  Assert.between(1, 0, 2);
  Assert.notBetween(3, 0, 2);

  Assert.within(1, 0, 2);
  Assert.notWithin(3, 0, 2);

  Assert.approximately(1.5f, 1, 0.6f);
  Assert.notApproximately(1.5f, 1, 0.2f);
}

@("Assert works for objects")
unittest {
  Object o = null;
  Assert.beNull(o, "it's a null");
  Assert.notNull(new Object, "it's not a null");
}

@("Assert works for strings")
unittest {
  Assert.equal("abcd", "abcd");
  Assert.notEqual("abcd", "abwcd");

  Assert.contain("abcd", "bc");
  Assert.notContain("abcd", 'e');

  Assert.startWith("abcd", "ab");
  Assert.notStartWith("abcd", "bc");

  Assert.startWith("abcd", 'a');
  Assert.notStartWith("abcd", 'b');

  Assert.endWith("abcd", "cd");
  Assert.notEndWith("abcd", "bc");

  Assert.endWith("abcd", 'd');
  Assert.notEndWith("abcd", 'c');
}

@("Assert works for ranges")
unittest {
  Assert.equal([1, 2, 3], [1, 2, 3]);
  Assert.notEqual([1, 2, 3], [1, 1, 3]);

  Assert.contain([1, 2, 3], 3);
  Assert.notContain([1, 2, 3], [5, 6]);

  Assert.containOnly([1, 2, 3], [3, 2, 1]);
  Assert.notContainOnly([1, 2, 3], [3, 1]);
}

void fluentHandler(string file, size_t line, string msg) nothrow {
  import core.exception;

  string errorMsg = "Assert failed. " ~ msg ~ "\n\n" ~ file ~ ":" ~ line.to!string ~ "\n";

  throw new AssertError(errorMsg, file, line);
}

void setupFluentHandler() {
  import core.exception;
  core.exception.assertHandler = &fluentHandler;
}

@("calls the fluent handler")
@trusted
unittest {
  import core.exception;

  setupFluentHandler;
  scope(exit) core.exception.assertHandler = null;

  bool thrown = false;

  try {
    assert(false, "What?");
  } catch(Throwable t) {
    thrown = true;
    t.msg.should.startWith("Assert failed. What?\n");
  }

  thrown.should.equal(true);
}
