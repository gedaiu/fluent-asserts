module bdd.base;

public import bdd.array;
public import bdd.string;
public import bdd.numeric;

import std.traits;

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
        throw new TestException(message, file, line);
      }
    }
  }
}

class TestException : Exception {
  pure nothrow @nogc @safe this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    super(msg, file, line, next);
  }
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
