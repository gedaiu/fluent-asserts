module fluentasserts.core.base;

public import fluentasserts.core.array;
public import fluentasserts.core.string;
public import fluentasserts.core.objects;
public import fluentasserts.core.basetype;
public import fluentasserts.core.callable;

import fluentasserts.core.results;

import std.traits;
import std.stdio;
import std.algorithm;
import std.array;
import std.range;
import std.conv;
import std.string;
import std.file;
import std.range.primitives;

struct Result {
  bool willThrow;
  IResult[] results;

  MessageResult message;

  string file;
  size_t line;

  void because(string reason) {
    message.prependText("Because " ~ reason ~ ", ");
  }

  void perform() {
    if(!willThrow) {
      return;
    }

    throw new TestException(cast(IResult) message ~ results, file, line);
  }

  ~this() {
    this.perform;
  }
}

struct Message {
  bool isValue;
  string text;
}

mixin template ShouldCommons()
{
  import std.string;
  import fluentasserts.core.results;

  auto be() {
    addMessage(" be");
    return this;
  }

  auto not() {
    addMessage(" not");
    expectedValue = !expectedValue;
    return this;
  }

  auto forceMessage(string message) {
    messages = [];

    addMessage(message);

    return this;
  }

  private {
    Message[] messages;
    ulong mesageCheckIndex;

    bool expectedValue = true;

    void addMessage(string msg) {
      if(mesageCheckIndex != 0) {
        return;
      }

      messages ~= Message(false, msg);
    }

    void addValue(string msg) {
      if(mesageCheckIndex != 0) {
        return;
      }

      messages ~= Message(true, msg);
    }

    void beginCheck() {
      if(mesageCheckIndex != 0) {
        return;
      }

      mesageCheckIndex = messages.length;
    }

    Result simpleResult(bool value, Message[] msg, string file, size_t line) {
      return result(value, msg, [ ], file, line);
    }

    Result result(bool value, Message[] msg, IResult res, string file, size_t line) {
      return result(value, msg, [ res ], file, line);
    }

    Result result(bool value, IResult res, string file, size_t line) {
       return result(value, [], [ res ], file, line);
    }

    Result result(bool value, Message[] msg, IResult[] res, const string file, const size_t line) {
      auto sourceResult = new SourceResult(file, line);
      auto finalMessage = new MessageResult(sourceResult.getValue ~ " should");

      messages ~= Message(false, ".");

      if(msg.length > 0) {
        messages ~= Message(false, " ") ~ msg;
      }

      foreach(message; messages) {
        if(message.isValue) {
          finalMessage.addValue(message.text);
        } else {
          finalMessage.addText(message.text);
        }
      }

      IResult[] results = res ~ cast(IResult) sourceResult;

      return Result(expectedValue != value, results, finalMessage, file, line);
    }
  }
}

version(Have_unit_threaded) {
  import unit_threaded.should;
  alias ReferenceException = UnitTestException;
} else {
  alias ReferenceException = Exception;
}

class TestException : ReferenceException {
  private {
    IResult[] results;
  }

  this(IResult[] results, string fileName, size_t line, Throwable next = null) {
    auto msg = results.map!(a => a.toString).join("\n\n") ~ '\n';
    this.results = results;

    super(msg, fileName, line, next);
  }

  void print(ResultPrinter printer) {
    results.each!(a => a.print(printer));
  }
}

/// Test Exception should sepparate the results by a new line
unittest {
  import std.stdio;
  IResult[] results = [
    cast(IResult) new MessageResult("message"),
    cast(IResult) new SourceResult("test/missing.txt", 10),
    cast(IResult) new DiffResult("a", "b"),
    cast(IResult) new ExpectedActualResult("a", "b"),
    cast(IResult) new ExtraMissingResult("a", "b") ];

  auto exception = new TestException(results, "unknown", 0);

  exception.msg.should.equal(`message

--------------------
test/missing.txt:10
--------------------

--------------------

Diff:
[-a][+b]

 Expected:a
   Actual:b

    Extra:a
  Missing:b
`);
}

@("TestException should concatenate all the Result strings")
unittest {
  class TestResult : IResult {
    override string toString() {
      return "message";
    }

    void print(ResultPrinter) {}
  }

  auto exception = new TestException([ new TestResult, new TestResult, new TestResult], "", 0);

  exception.msg.should.equal("message\n\nmessage\n\nmessage\n");
}

@("TestException should call all the result print methods on print")
unittest {
  int count;

  class TestResult : IResult {
    override string toString() {
      return "";
    }

    void print(ResultPrinter) {
      count++;
    }
  }

  auto exception = new TestException([ new TestResult, new TestResult, new TestResult], "", 0);
  exception.print(new DefaultResultPrinter);

  count.should.equal(3);
}

auto should(T)(lazy T testData) {
  version(Have_fluent_asserts_vibe) {
    import vibe.data.json;

    static if(is(T == Json)) {
      enum returned = true;
      return ShouldString(testData.to!string);
    } else {
      enum returned = false;
    }
  } else {
    enum returned = false;
  }

  static if(!returned) {
    static if(is(T == class)) {
      return ShouldObject!T(testData);
    } else static if(is(T == string)) {
      return ShouldString(testData);
    } else static if(isInputRange!T) {
      return ShouldList!T(testData);
    } else static if(isCallable!T) {
      return ShouldCallable!T(testData);
    } else {
      return ShouldBaseType!T(testData);
    }
  }
}

@("because")
unittest {
  auto msg = ({
    true.should.equal(false).because("of test reasons");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Because of test reasons, true should equal `false`.");
}

struct Assert {
  static void opDispatch(string s, T, U)(T actual, U expected, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto sh = actual.should;

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

    mixin("auto result = sh." ~ assertName ~ "(expected, file, line);");

    if(reason != "") {
      result.because(reason);
    }
  }

  static void between(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.be.between(begin, end, file, line);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notBetween(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.not.be.between(begin, end, file, line);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void within(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.be.within(begin, end, file, line);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notWithin(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.not.be.within(begin, end, file, line);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void approximately(T, U, V)(T actual, U expected, V delta, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.be.approximately(expected, delta, file, line);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notApproximately(T, U, V)(T actual, U expected, V delta, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.not.be.approximately(expected, delta, file, line);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void beNull(T)(T actual, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.beNull(file, line);

    if(reason != "") {
      s.because(reason);
    }
  }

  static void notNull(T)(T actual, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = actual.should.not.beNull(file, line);

    if(reason != "") {
      s.because(reason);
    }
  }
}

/// Assert should work for base types
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

/// Assert should work for objects
unittest {
  Object o = null;
  Assert.beNull(o, "it's a null");
  Assert.notNull(new Object, "it's not a null");
}

/// Assert should work for strings
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

/// Assert should work for ranges
unittest {
  Assert.equal([1, 2, 3], [1, 2, 3]);
  Assert.notEqual([1, 2, 3], [1, 1, 3]);

  Assert.contain([1, 2, 3], 3);
  Assert.notContain([1, 2, 3], [5, 6]);

  Assert.containOnly([1, 2, 3], [3, 2, 1]);
  Assert.notContainOnly([1, 2, 3], [3, 1]);
}