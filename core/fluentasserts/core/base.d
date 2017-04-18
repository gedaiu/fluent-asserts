module fluentasserts.core.base;

public import fluentasserts.core.array;
public import fluentasserts.core.string;
public import fluentasserts.core.numeric;

import fluentasserts.core.results;

import std.traits;
import std.stdio;
import std.algorithm;
import std.array;
import std.range;
import std.conv;
import std.string;
import std.file;

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

    void result(bool value, string msg, string file, size_t line) {
      if(expectedValue != value) {
        auto sourceResult = new SourceResult(file, line);
        auto message = sourceResult.getValue ~ " should " ~ messages.join(" ") ~ ". " ~ msg;
        IResult[] results = [ cast(IResult) new MessageResult(message), cast(IResult) sourceResult ];

        throw new TestException(results, file, line);
      }
    }

    void result(bool value, string actual, string expected, string file, size_t line) {
      if(expectedValue != value) {
        auto sourceResult = new SourceResult(file, line);
        auto message = sourceResult.getValue ~ " should " ~ messages.join(" ") ~ ".";

        IResult[] results = [ cast(IResult) new MessageResult(message), cast(IResult) new ExpectedActualResult(expected, actual), cast(IResult) sourceResult ];

        throw new TestException(results, file, line);
      }
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

  void print() {
    results.each!(a => a.print);
  }
}

@("TestException should concatenate all the Result strings")
unittest {
  class TestResult : IResult {
    override string toString() {
      return "message";
    }

    void print() {}
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

    void print() {
      count++;
    }
  }

  auto exception = new TestException([ new TestResult, new TestResult, new TestResult], "", 0);
  exception.print;

  count.should.equal(3);
}

@("Throw any exception")
unittest
{
  should.throwAnyException({
    throw new Exception("test");
  }).msg.should.startWith("test");

  should.not.throwAnyException({});
}

@("Throw any exception failures")
unittest
{
  bool foundException;

  try {
    should.not.throwAnyException({
      throw new Exception("test");
    });
  } catch(TestException e) {
    foundException = true;
  }
  assert(foundException);

  foundException = false;
  try {
    should.throwAnyException({});
  } catch(TestException e) {
    foundException = true;
  }
  assert(foundException);
}

struct Should {
  mixin ShouldCommons;

  auto throwAnyException(T)(T callable, string file = __FILE__, size_t line = __LINE__) {
    addMessage("throw any exception");
    beginCheck;

    return throwException!Exception(callable, file, line);
  }

  auto throwException(E : Exception, T)(T callable, string file = __FILE__, size_t line = __LINE__) {
    addMessage("throw " ~ E.stringof);
    beginCheck;

    string msg = "Exception not found.";

    bool isFailed = false;

    E foundException;

    try {
      callable();
    } catch(E exception) {
      isFailed = true;
      msg = "Exception thrown `" ~ exception.msg ~ "`";
      foundException = exception;
    }

    result(isFailed, msg, file, line);

    return foundException;
  }
}

auto should() {
  return Should();
}

auto should(T)(lazy const T testData) {
  static if(is(T == string)) {
    return ShouldString(testData);
  } else static if(isArray!T) {
    return ShouldList!T(testData);
  } else {
    return ShouldNumeric!T(testData);
  }
}
