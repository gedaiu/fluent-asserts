module fluentasserts.core.base;

public import fluentasserts.core.array;
public import fluentasserts.core.string;
public import fluentasserts.core.objects;
public import fluentasserts.core.basetype;
public import fluentasserts.core.callable;
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

struct Result {
  bool willThrow;
  IResult[] results;

  MessageResult message;

  string file;
  size_t line;

  private string reason;

  auto because(string reason) {
    this.reason = "Because " ~ reason ~ ", ";
    return this;
  }

  void perform() {
    if(!willThrow) {
      return;
    }

    version(DisableMessageResult) {
      IResult[] localResults = this.results;
    } else {
      IResult[] localResults = message ~ this.results;
    }

    version(DisableSourceResult) {} else {
      auto sourceResult = new SourceResult(file, line);
      message.prependValue(sourceResult.getValue);
      message.prependText(reason);

      localResults ~= sourceResult;
    }

    throw new TestException(localResults, file, line);
  }

  ~this() {
    this.perform;
  }

  static Result success() {
    return Result(false);
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

  private ValueEvaluation valueEvaluation;
  private bool isNegation;

  private void validateException() {
    if(valueEvaluation.throwable !is null) {
      throw valueEvaluation.throwable;
    }
  }

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
    isNegation = !isNegation;

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
      if(res.length == 0 && msg.length == 0) {
        return Result(false);
      }

      auto finalMessage = new MessageResult(" should");

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

      return Result(expectedValue != value, res, finalMessage, file, line);
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
    auto msg = results.map!"a.toString".filter!"a != ``".join("\n") ~ '\n';
    this.results = results;

    super(msg, fileName, line, next);
  }

  void print(ResultPrinter printer) {
    foreach(result; results) {
      result.print(printer);
      printer.primary("\n");
    }
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

  exception.msg.should.equal("message\nmessage\nmessage\n");
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

    return thrown.msg.dup.to!string.strip;
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

  auto withMessage(string expectedMessage) {
    auto s = ShouldString(msg);
    check = false;

    return s.forceMessage(messages ~ Message(false, " with message")).equal(expectedMessage);
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

  auto because(string reason) {
    this.reason = reason;

    return this;
  }
}

auto should(T)(lazy T testData, const string file = __FILE__, const size_t line = __LINE__) @trusted {
  import std.stdio;

  version(Have_vibe_d_data) {
    version(Have_fluent_asserts_vibe) {
      import vibe.data.json;
      import fluentasserts.vibe.json;

      static if(is(Unqual!T == Json)) {
        enum returned = true;
        return ShouldJson!T(testData.evaluate);
      } else {
        enum returned = false;
      }
    } else {
      enum returned = false;
    }
  } else {
    enum returned = false;
  }

  static if(is(T == void)) {
    auto callable = ({ testData; });
    return expect(callable, file, line);
  } else static if(!returned) {

    static if(is(T == class) || is(T == interface)) {
      return expect(testData, file, line);
    } else {
      return expect(testData, file, line);
    }
  }
}

@("because")
unittest {
  auto msg = ({
    true.should.equal(false).because("of test reasons");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Because of test reasons, true should equal false.");
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
