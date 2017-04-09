module fluentasserts.core.base;

public import fluentasserts.core.array;
public import fluentasserts.core.string;
public import fluentasserts.core.numeric;

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
  string value;

  this(string message, string fileName = __FILE__, size_t line = __LINE__, size_t range = 6) {
    this.file = fileName;
    this.line = line;

    if(!fileName.exists) {
      this.message = message;
      return;
    }

    auto file = File(fileName);

    auto rawCode = file.byLine().map!(a => a.to!string).take(line + range).array;

    code = rawCode.enumerate(1).dropExactly(range < line ? line - range : 0)
        .map!(a => (a[0] == line ? ">" : " ") ~ rightJustifier(a[0].to!string, 5).to!string ~ ": " ~ a[1])
        .take(range * 2 - 1).join("\n")
        .to!string;

    value = evaluatedValue(rawCode);

    auto separator = "\n " ~ leftJustify("", 20, '-') ~ "\n";
    this.message = value ~ " " ~ message ~ separator ~ " " ~ fileName ~ separator ~ code ~ "\n";
  }

  private {
    auto evaluatedValue(string[] rawCode) {
      string result = "";

      auto value = rawCode.take(line)
        .filter!(a => a.indexOf("//") == -1)
        .map!(a => a.strip)
        .join("");

      auto end = valueEndIndex(value);

      if(end > 0) {
        auto begin = valueBeginIndex(value[0..end]);

        if(begin > 0) {
          result = value[begin..end];
        }
      }

      return result;
    }

    auto valueBeginIndex(string value) {

      auto tokens = ["{", ";", "*/", "+/"];

      auto positions =
        tokens
          .map!(a => [value.lastIndexOf(a), a.length])
          .filter!(a => a[0] != -1)
          .map!(a => a[0] + a[1])
            .array;

      if(positions.length == 0) {
        return -1;
      }

      return positions.sort!("a > b").front;
    }

    auto valueEndIndex(string value) {
      return value.lastIndexOf(".should");
    }
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
  auto exception = new TestException(Source("Some test error", "test/example.txt", 10));

  exception.msg.should.contain("Some test error");
  exception.msg.should.contain("test/example.txt");
  exception.msg.should.contain(">   10: line 10");
}

@("TestException should ignore missing files")
unittest
{
  auto exception = new TestException(Source("Some test error", "test/missing.txt", 10));

  exception.msg.should.contain("Some test error");
  exception.msg.should.not.contain("test/example.txt");
  exception.msg.should.not.contain(">   10: line 10");
}

@("Source struct should find the tested value on scope start")
unittest
{
  Source("should contain `4`", "test/values.d", 4).message
    .should.startWith("[1, 2, 3] should contain `4`");
}

@("Source struct should find the tested value after a statment")
unittest
{
  Source("should contain `4`", "test/values.d", 12).message
    .should.startWith("[1, 2, 3] should contain `4`");
}

@("Source struct should find the tested value after a */ comment")
unittest
{
  Source("should contain `4`", "test/values.d", 20).message
    .should.startWith("[1, 2, 3] should contain `4`");
}

@("Source struct should find the tested value after a +/ comment")
unittest
{
  Source("should contain `4`", "test/values.d", 28).message
    .should.startWith("[1, 2, 3] should contain `4`");
}

@("Source struct should find the tested value after a // comment")
unittest
{
  Source("should contain `4`", "test/values.d", 36).message
    .should.startWith("[1, 2, 3] should contain `4`");
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
