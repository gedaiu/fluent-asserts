module bdd.base;

public import bdd.array;
public import bdd.string;
public import bdd.numeric;

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
        auto message = "should " ~ messages.join(" ") ~ ". " ~ msg;

        throw new TestException(Source(message, file, line));
      }
    }
  }
}

struct Source {
  string file;
  size_t line;

  string code;
  string message;

  this(string message, string fileName = __FILE__, size_t line = __LINE__, size_t range = 3) {
    this.file = fileName;
    this.line = line;

    if(!fileName.exists) {
      this.message = message;
      return;
    }

    auto file = File(fileName);

    code =
      file.byLine().enumerate(1)
        .dropExactly(line - range)
        .map!(a => (a[0] == line ? ">" : " ") ~ rightJustifier(a[0].to!string, 5).to!string ~ ": " ~ a[1])
        .take(range * 2 - 1).join("\n")
        .to!string;

    auto separator = "\n" ~ leftJustify("", 20, '-') ~ "\n";
    this.message = "\n" ~ message ~ separator ~ fileName ~ separator ~ code ~ "\n";
  }
}

class TestException : Exception {
  pure nothrow @nogc @safe this(Source source, Throwable next = null) {
    super(source.message, source.file, source.line, next);
  }
}

@("TestException should read the code from the file")
unittest
{
  import std.conv, std.stdio;

  auto exception = new TestException(Source("Some test error", "test/example.txt", 10));

  exception.msg.should.contain("Some test error");
  exception.msg.should.contain("test/example.txt");
  exception.msg.should.contain(">   10: line 10");
}

@("TestException should read the code from the file")
unittest
{
  import std.conv, std.stdio;

  auto exception = new TestException(Source("Some test error", "test/missing.txt", 10));

  exception.msg.should.contain("Some test error");
  exception.msg.should.not.contain("test/example.txt");
  exception.msg.should.not.contain(">   10: line 10");
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
