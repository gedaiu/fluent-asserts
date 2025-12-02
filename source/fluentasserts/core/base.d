/// Base module for fluent-asserts.
/// Re-exports all core assertion modules and provides the Assert struct
/// for traditional-style assertions.
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

/// Exception thrown when an assertion fails.
/// Contains the failure message and optionally structured message segments
/// for rich output formatting.
class TestException : ReferenceException {
  private {
    immutable(Message)[] messages;
  }

  /// Constructs a TestException with a simple string message.
  this(string message, string fileName, size_t line, Throwable next = null) {
    super(message ~ '\n', fileName, line, next);
  }

  /// Constructs a TestException with structured message segments.
  this(immutable(Message)[] messages, string fileName, size_t line, Throwable next = null) {
    string msg;
    foreach(m; messages) {
      msg ~= m.toString;
    }
    msg ~= '\n';
    this.messages = messages;

    super(msg, fileName, line, next);
  }

  /// Prints the exception message using a ResultPrinter for formatted output.
  void print(ResultPrinter printer) {
    foreach(message; messages) {
      printer.print(message);
    }
    printer.primary("\n");
  }
}

/// Creates a fluent assertion using UFCS syntax.
/// This is an alias for `expect` that reads more naturally with UFCS.
/// Example: `value.should.equal(42)`
/// Params:
///   testData = The value to test
///   file = Source file (auto-captured)
///   line = Source line (auto-captured)
/// Returns: An Expect struct for chaining assertions.
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

/// Provides a traditional assertion API as an alternative to fluent syntax.
/// All methods are static and can be called as `Assert.equal(a, b)`.
/// Supports negation by prefixing with "not": `Assert.notEqual(a, b)`.
struct Assert {
  /// Dispatches assertion calls dynamically based on the method name.
  /// Supports negation with "not" prefix (e.g., notEqual, notContain).
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

  /// Asserts that a value is between two bounds (exclusive).
  static void between(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  /// Asserts that a value is NOT between two bounds.
  static void notBetween(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).not.to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  /// Asserts that a value is within two bounds (alias for between).
  static void within(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  /// Asserts that a value is NOT within two bounds.
  static void notWithin(T, U)(T actual, U begin, U end, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).not.to.be.between(begin, end);

    if(reason != "") {
      s.because(reason);
    }
  }

  /// Asserts that a value is approximately equal to expected within delta.
  static void approximately(T, U, V)(T actual, U expected, V delta, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.be.approximately(expected, delta);

    if(reason != "") {
      s.because(reason);
    }
  }

  /// Asserts that a value is NOT approximately equal to expected.
  static void notApproximately(T, U, V)(T actual, U expected, V delta, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).not.to.be.approximately(expected, delta);

    if(reason != "") {
      s.because(reason);
    }
  }

  /// Asserts that a value is null.
  static void beNull(T)(T actual, string reason = "", const string file = __FILE__, const size_t line = __LINE__)
  {
    auto s = expect(actual, file, line).to.beNull;

    if(reason != "") {
      s.because(reason);
    }
  }

  /// Asserts that a value is NOT null.
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

/// Custom assert handler that provides better error messages.
/// Replaces the default D runtime assert handler to show fluent-asserts style output.
void fluentHandler(string file, size_t line, string msg) nothrow {
  import core.exception;

  string errorMsg = "Assert failed. " ~ msg ~ "\n\n" ~ file ~ ":" ~ line.to!string ~ "\n";

  throw new AssertError(errorMsg, file, line);
}

/// Installs the fluent handler as the global assert handler.
/// Call this at program startup to enable fluent-asserts style messages for assert().
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
