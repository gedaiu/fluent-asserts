module fluentasserts.core.base;

public import fluentasserts.core.array;
public import fluentasserts.core.string;
public import fluentasserts.core.objects;
public import fluentasserts.core.basetype;
public import fluentasserts.core.callable;
public import fluentasserts.core.results;

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

mixin template DisabledShouldThrowableCommons() {
  auto throwSomething(string file = __FILE__, size_t line = __LINE__) {
    static assert("`throwSomething` does not work for arrays and ranges");
  }

  auto throwAnyException(const string file = __FILE__, const size_t line = __LINE__) {
    static assert("`throwAnyException` does not work for arrays and ranges");
  }

  auto throwException(T)(const string file = __FILE__, const size_t line = __LINE__) {
    static assert("`throwException` does not work for arrays and ranges");
  }
}

mixin template ShouldThrowableCommons() {
  auto throwSomething(string file = __FILE__, size_t line = __LINE__) {
    addMessage(" throw ");
    addValue("something");
    beginCheck;

    return throwException!Throwable(file, line);
  }

  auto throwAnyException(const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" throw ");
    addValue("any exception");
    beginCheck;

    return throwException!Exception(file, line);
  }

  auto throwException(T)(const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" throw a `");
    addValue(T.stringof);
    addMessage("`");

    return ThrowableProxy!T(valueEvaluation.throwable, expectedValue, messages, file, line);
  }

  private {
    ThrowableProxy!T throwExceptionImplementation(T)(Throwable t, string file = __FILE__, size_t line = __LINE__) {
      addMessage(" throw a `");
      addValue(T.stringof);
      addMessage("`");

      bool rightType = true;
      if(t !is null) {
        T castedThrowable = cast(T) t;
        rightType = castedThrowable !is null;
      }

      return ThrowableProxy!T(t, expectedValue, rightType, messages, file, line);
    }
  }
}

mixin template ShouldCommons()
{
  import std.string;
  import fluentasserts.core.results;

  auto be() {
    addMessage(" be");
    return this;
  }

  auto should() {
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

  auto forceMessage(Message[] messages) {
    this.messages = messages;

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

struct ThrowableProxy(T : Throwable) {
  import fluentasserts.core.results;

  private const {
    bool expectedValue;
    const string _file;
    size_t _line;
  }

  private {
    Message[] messages;
    string reason;
    bool check;
    Throwable thrown;
    T thrownTyped;
  }

  this(Throwable thrown, bool expectedValue, Message[] messages, const string file, size_t line) {
    this.expectedValue = expectedValue;
    this._file = file;
    this._line = line;
    this.thrown = thrown;
    this.thrownTyped = cast(T) thrown;
    this.messages = messages;
    this.check = true;
  }

  ~this() {
    checkException;
  }

  auto msg() {
    checkException;
    check = false;

    return thrown.msg.dup.to!string;
  }

  auto original() {
    checkException;
    check = false;

    return thrownTyped;
  }

  auto file() {
    checkException;
    check = false;

    return thrown.file;
  }

  auto info() {
    checkException;
    check = false;

    return thrown.info;
  }

  auto line() {
    checkException;
    check = false;

    return thrown.line;
  }

  auto next() {
    checkException;
    check = false;

    return thrown.next;
  }

  auto withMessage() {
    auto s = ShouldString(msg);
    check = false;

    return s.forceMessage(messages ~ Message(false, " with message"));
  }

  private void checkException() {
    if(!check) {
      return;
    }

    bool hasException = thrown !is null;
    bool hasTypedException = thrownTyped !is null;

    if(hasException == expectedValue && hasTypedException == expectedValue) {
      return;
    }

    auto sourceResult = new SourceResult(_file, _line);
    auto message = new MessageResult("");

    if(reason != "") {
      message.addText("Because " ~ reason ~ ", ");
    }

    message.addText(sourceResult.getValue ~ " should");

    foreach(msg; messages) {
      if(msg.isValue) {
        message.addValue(msg.text);
      } else {
        message.addText(msg.text);
      }
    }

    message.addText(".");

    if(thrown is null) {
      message.addText(" Nothing was thrown.");
    } else {
      message.addText(" An exception of type `");
      message.addValue(thrown.classinfo.name);
      message.addText("` saying `");
      message.addValue(thrown.msg);
      message.addText("` was thrown.");
    }

    throw new TestException([ cast(IResult) message ], _file, _line);
  }

  void because(string reason) {
    this.reason = reason;
  }
}

struct ValueEvaluation {
  Throwable throwable;
  Duration duration;
}

auto evaluate(T)(lazy T testData) {
  auto begin = Clock.currTime;
  alias Result = Tuple!(T, "value", ValueEvaluation, "evaluation");

  Result r;

  try {
    auto value = testData;

    static if(isCallable!T) {
      if(value !is null) {
        begin = Clock.currTime;
        value();
      }
    }

    auto duration = Clock.currTime - begin;
    r.value = value;
    r.evaluation = ValueEvaluation(null, duration);
  } catch(Throwable t) {
    r.evaluation = ValueEvaluation(t, Clock.currTime - begin);

    static if(isCallable!T) {
      r.value = testData;
    }
  }

  return r;
}

/// evaluate should capture an exception
unittest {
  int value() {
    throw new Exception("message");
  }

  auto result = evaluate(value);

  result.evaluation.throwable.should.not.beNull;
  result.evaluation.throwable.msg.should.equal("message");
}

/// evaluate should capture an exception thrown by a callable
unittest {
  void value() {
    throw new Exception("message");
  }

  auto result = evaluate(&value);

  result.evaluation.throwable.should.not.beNull;
  result.evaluation.throwable.msg.should.equal("message");
}

auto should(T)(lazy T testData) {
  version(Have_fluent_asserts_vibe) {
    import vibe.data.json;

    static if(is(T == Json)) {
      enum returned = true;
      return ShouldString(testData.to!string.evaluate);
    } else {
      enum returned = false;
    }
  } else {
    enum returned = false;
  }

  static if(is(T == void)) {
    auto callable = ({ testData; });
    return ShouldCallable!(typeof(callable))(callable);
  } else static if(!returned) {
    static if(is(T == class)) {
      return ShouldObject!T(testData.evaluate);
    } else static if(is(T == string)) {
      return ShouldString(testData.evaluate);
    } else static if(isInputRange!T) {
      return ShouldList!T(testData);
    } else static if(isCallable!T) {
      return ShouldCallable!T(testData);
    } else {
      return ShouldBaseType!T(testData.evaluate);
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

void fluentHandler(string file, size_t line, string msg) nothrow {
  import core.exception;

  auto message = new MessageResult("Assert failed. " ~ msg);
  auto source = new SourceResult(file, line);

  throw new AssertError(message.toString ~ "\n\n" ~ source.toString, file, line);
}

void setupFluentHandler() {
  import core.exception;
  core.exception.assertHandler = &fluentHandler;
}

/// It should call the fluent handler
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