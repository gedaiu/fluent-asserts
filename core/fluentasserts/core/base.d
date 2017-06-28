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

  string message;

  string file;
  size_t line;

  void because(string reason) {
    message = "Because " ~ reason ~ ", " ~ message;
  }

  void perform() {
    if(!willThrow) {
      return;
    }

    throw new TestException(cast(IResult) new MessageResult(message) ~ results, file, line);
  }

  ~this() {
    this.perform;
  }
}

mixin template ShouldCommons()
{
  import std.string;
  import fluentasserts.core.results;

  auto be() {
    return this;
  }

  auto not() {
    addMessage("not");
    expectedValue = !expectedValue;
    return this;
  }

  private {
    string[] messages;
    ulong mesageCheckIndex;

    bool expectedValue = true;

    void addMessage(string msg) {
      if(mesageCheckIndex != 0) {
        return;
      }

      messages ~= msg;
    }

    void beginCheck() {
      if(mesageCheckIndex != 0) {
        return;
      }

      mesageCheckIndex = messages.length;
    }

    Result simpleResult(bool value, string msg, string file, size_t line) {
      return result(value, msg, [ ], file, line);
    }

    Result result(bool value, string msg, IResult res, string file, size_t line) {
      return result(value, msg, [ res ], file, line);
    }

    Result result(bool value, IResult res, string file, size_t line) {
       return result(value, "", [ res ], file, line);
    }

    Result result(bool value, string msg, IResult[] res, const string file, const size_t line) {
      auto sourceResult = new SourceResult(file, line);
      auto message = sourceResult.getValue ~ " should " ~ messages.join(" ") ~ ".";

      if(msg != "") {
        message ~= " " ~ msg;
      }

      IResult[] results = res ~ cast(IResult) sourceResult;

      return Result(expectedValue != value, results, message, file, line);
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