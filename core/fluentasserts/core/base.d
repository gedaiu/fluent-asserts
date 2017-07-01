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