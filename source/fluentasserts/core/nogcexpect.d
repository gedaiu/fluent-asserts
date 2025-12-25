/// Nothrow fluent API for assertions on primitive types with minimal GC usage.
/// Note: Not fully @nogc (numeric serialization allocates), but nothrow and GC-light.
/// Integrates with fluent-asserts infrastructure using HeapString and HeapEquableValue.
module fluentasserts.core.nogcexpect;

import fluentasserts.core.evaluation.constraints : isPrimitiveType;
import fluentasserts.core.evaluation.equable : equableValue;
import fluentasserts.core.memory.heapstring : HeapString;
import fluentasserts.core.memory.heapequable : HeapEquableValue;
import fluentasserts.results.serializers.heap_registry : HeapSerializerRegistry;

import std.traits;

/// Nothrow assertion result with minimal GC usage.
/// Can be checked inline or enforced later (throws exception).
struct NoGCAssertResult {
  HeapEquableValue actual;
  HeapEquableValue expected;
  HeapString operation;
  HeapString fileName;
  size_t line;
  bool isNegated;
  bool passed;

  @disable this(this);

  /// Throws an exception if the assertion failed (non-@nogc).
  void enforce() @safe {
    if (!passed) {
      throw new Exception("Assertion failed");
    }
  }
}

/// A lightweight nothrow assertion struct for primitive types with minimal GC.
/// Provides fluent API for assertions on numbers, strings, and chars.
/// Note: Not @nogc for numerics (serialization allocates), but nothrow and GC-light.
@safe struct NoGCExpect(T) if(isPrimitiveType!T) {

  private {
    HeapEquableValue _actualValue;
    HeapString _fileName;
    size_t _line;
    bool _isNegated;
  }

  @disable this(this);

  /// Constructor - nothrow but not @nogc for numeric types (serialization allocates).
  this(T value, string file, size_t line) nothrow {
    _actualValue = equableValue(value);
    _fileName = HeapString.create(file.length);
    _fileName.put(file);
    _line = line;
    _isNegated = false;
  }

  /// Syntactic sugar - returns self for chaining.
  ref NoGCExpect to() return @nogc nothrow {
    return this;
  }

  /// Syntactic sugar - returns self for chaining.
  ref NoGCExpect be() return @nogc nothrow {
    return this;
  }

  /// Negates the assertion condition.
  ref NoGCExpect not() return @nogc nothrow {
    _isNegated = !_isNegated;
    return this;
  }

  /// Asserts that the actual value equals the expected value.
  /// Note: Not @nogc for numeric types (serialization allocates).
  NoGCAssertResult equal(T expected, string file = __FILE__, size_t line = __LINE__) nothrow {
    auto expectedValue = equableValue(expected);

    bool isEqual = _actualValue.isEqualTo(expectedValue);
    if (_isNegated) {
      isEqual = !isEqual;
    }

    NoGCAssertResult result;
    result.actual = _actualValue;
    result.expected = expectedValue;
    result.operation = createOperationString("equal");
    result.fileName = _fileName;
    result.line = _line;
    result.isNegated = _isNegated;
    result.passed = isEqual;

    return result;
  }

  /// Asserts that the actual value is greater than the expected value.
  /// Note: Not @nogc for numeric types (serialization allocates).
  NoGCAssertResult greaterThan(T expected, string file = __FILE__, size_t line = __LINE__) nothrow {
    static if (isNumeric!T) {
      auto expectedValue = equableValue(expected);

      bool isGreater = _actualValue.isLessThan(expectedValue);
      isGreater = !isGreater && !_actualValue.isEqualTo(expectedValue);

      if (_isNegated) {
        isGreater = !isGreater;
      }

      NoGCAssertResult result;
      result.actual = _actualValue;
      result.expected = expectedValue;
      result.operation = createOperationString("greaterThan");
      result.fileName = _fileName;
      result.line = _line;
      result.isNegated = _isNegated;
      result.passed = isGreater;

      return result;
    } else {
      NoGCAssertResult result;
      result.passed = false;
      return result;
    }
  }

  /// Asserts that the actual value is less than the expected value.
  /// Note: Not @nogc for numeric types (serialization allocates).
  NoGCAssertResult lessThan(T expected, string file = __FILE__, size_t line = __LINE__) nothrow {
    static if (isNumeric!T) {
      auto expectedValue = equableValue(expected);

      bool isLess = _actualValue.isLessThan(expectedValue);
      if (_isNegated) {
        isLess = !isLess;
      }

      NoGCAssertResult result;
      result.actual = _actualValue;
      result.expected = expectedValue;
      result.operation = createOperationString("lessThan");
      result.fileName = _fileName;
      result.line = _line;
      result.isNegated = _isNegated;
      result.passed = isLess;

      return result;
    } else {
      NoGCAssertResult result;
      result.passed = false;
      return result;
    }
  }

  /// Asserts that the actual value is greater than or equal to the expected value.
  /// Note: Not @nogc for numeric types (serialization allocates).
  NoGCAssertResult greaterOrEqualTo(T expected, string file = __FILE__, size_t line = __LINE__) nothrow {
    static if (isNumeric!T) {
      auto expectedValue = equableValue(expected);

      bool isGreaterOrEqual = !_actualValue.isLessThan(expectedValue);
      if (_isNegated) {
        isGreaterOrEqual = !isGreaterOrEqual;
      }

      NoGCAssertResult result;
      result.actual = _actualValue;
      result.expected = expectedValue;
      result.operation = createOperationString("greaterOrEqualTo");
      result.fileName = _fileName;
      result.line = _line;
      result.isNegated = _isNegated;
      result.passed = isGreaterOrEqual;

      return result;
    } else {
      NoGCAssertResult result;
      result.passed = false;
      return result;
    }
  }

  /// Asserts that the actual value is less than or equal to the expected value.
  /// Note: Not @nogc for numeric types (serialization allocates).
  NoGCAssertResult lessOrEqualTo(T expected, string file = __FILE__, size_t line = __LINE__) nothrow {
    static if (isNumeric!T) {
      auto expectedValue = equableValue(expected);

      bool isLessOrEqual = _actualValue.isLessThan(expectedValue) || _actualValue.isEqualTo(expectedValue);
      if (_isNegated) {
        isLessOrEqual = !isLessOrEqual;
      }

      NoGCAssertResult result;
      result.actual = _actualValue;
      result.expected = expectedValue;
      result.operation = createOperationString("lessOrEqualTo");
      result.fileName = _fileName;
      result.line = _line;
      result.isNegated = _isNegated;
      result.passed = isLessOrEqual;

      return result;
    } else {
      NoGCAssertResult result;
      result.passed = false;
      return result;
    }
  }

  /// Asserts that the actual value is above (greater than) the expected value.
  NoGCAssertResult above(T expected, string file = __FILE__, size_t line = __LINE__) nothrow {
    return greaterThan(expected, file, line);
  }

  /// Asserts that the actual value is below (less than) the expected value.
  NoGCAssertResult below(T expected, string file = __FILE__, size_t line = __LINE__) nothrow {
    return lessThan(expected, file, line);
  }

  private HeapString createOperationString(string op) @nogc nothrow {
    auto result = HeapString.create(op.length + (_isNegated ? 4 : 0));
    if (_isNegated) {
      result.put("not ");
    }
    result.put(op);
    return result;
  }
}

/// Creates a NoGCExpect from a primitive value.
/// Only works with primitive types (numbers, strings, chars).
/// Note: This is nothrow but NOT @nogc for numeric types (serialization allocates).
/// Params:
///   value = The primitive value to test
///   file = Source file (auto-filled)
///   line = Source line (auto-filled)
/// Returns: A NoGCExpect struct for fluent assertions with minimal GC usage
auto nogcExpect(T)(T value, const string file = __FILE__, const size_t line = __LINE__) nothrow
  if(isPrimitiveType!T)
{
  return NoGCExpect!T(value, file, line);
}

version(unittest) {
  @("nogcExpect supports primitive equality")
  nothrow unittest {
    auto result = nogcExpect(42).equal(42);
    assert(result.passed);
  }

  @("nogcExpect detects inequality")
  nothrow unittest {
    auto result = nogcExpect(42).equal(43);
    assert(!result.passed);
  }

  @("nogcExpect supports negation")
  nothrow unittest {
    auto result = nogcExpect(42).not.equal(43);
    assert(result.passed);
  }

  @("nogcExpect supports greater than")
  nothrow unittest {
    auto result = nogcExpect(10).greaterThan(5);
    assert(result.passed);
  }

  @("nogcExpect supports less than")
  nothrow unittest {
    auto result = nogcExpect(5).lessThan(10);
    assert(result.passed);
  }

  @("nogcExpect works with strings")
  nothrow unittest {
    auto result = nogcExpect("hello").equal("hello");
    assert(result.passed);
  }

  @("nogcExpect result can be enforced outside @nogc")
  unittest {
    auto result = ({
      return nogcExpect(42).equal(42);
    })();

    result.enforce(); // Should not throw
  }
}
