module fluentasserts.core.conversion.integers;

import fluentasserts.core.memory.heapstring : HeapString, toHeapString;
import fluentasserts.core.conversion.types : ParsedResult, SignResult;
import fluentasserts.core.conversion.digits : parseDigitsLong, parseDigitsUlong;

version (unittest) {
  import fluent.asserts;
}

/// Parses an optional leading sign (+/-) from a string.
///
/// For unsigned types, a negative sign results in an invalid result.
///
/// Params:
///   input = The string to parse
///
/// Returns:
///   A SignResult containing the position after the sign and validity status.
SignResult parseSign(T)(HeapString input) @safe nothrow @nogc {
  SignResult result;
  result.valid = true;

  if (input[0] == '-') {
    static if (__traits(isUnsigned, T)) {
      result.valid = false;
      return result;
    } else {
      result.negative = true;
      result.position = 1;
    }
  } else if (input[0] == '+') {
    result.position = 1;
  }

  if (result.position >= input.length) {
    result.valid = false;
  }

  return result;
}

/// Checks if a long value is within the range of type T.
///
/// Params:
///   value = The value to check
///
/// Returns:
///   true if the value fits in type T, false otherwise.
bool isInRange(T)(long value) @safe nothrow @nogc {
  static if (__traits(isUnsigned, T)) {
    return value >= 0 && value <= T.max;
  } else {
    return value >= T.min && value <= T.max;
  }
}

/// Applies a sign to a value.
///
/// Params:
///   value = The value to modify
///   negative = Whether to negate the value
///
/// Returns:
///   The negated value if negative is true, otherwise the original value.
T applySign(T)(T value, bool negative) @safe nothrow @nogc {
  return negative ? -value : value;
}

/// Computes 10 raised to the power of exp.
///
/// Params:
///   exp = The exponent
///
/// Returns:
///   10^exp as type T.
T computeMultiplier(T)(int exp) @safe nothrow @nogc {
  T multiplier = 1;
  foreach (_; 0 .. exp) {
    multiplier *= 10;
  }
  return multiplier;
}

/// Parses a string as an unsigned long value.
///
/// Params:
///   input = The string to parse
///   i = Starting position in the string
///
/// Returns:
///   A ParsedResult containing the parsed ulong value.
ParsedResult!ulong parseUlong(HeapString input, size_t i) @safe nothrow @nogc {
  auto digits = parseDigitsUlong(input, i);

  if (!digits.hasDigits || digits.overflow || digits.position != input.length) {
    return ParsedResult!ulong();
  }

  return ParsedResult!ulong(digits.value, true);
}

/// Parses a string as a signed integral value.
///
/// Params:
///   input = The string to parse
///   i = Starting position in the string
///   negative = Whether the value should be negated
///
/// Returns:
///   A ParsedResult containing the parsed value.
ParsedResult!T parseSignedIntegral(T)(HeapString input, size_t i, bool negative) @safe nothrow @nogc {
  auto digits = parseDigitsLong(input, i);

  if (!digits.hasDigits || digits.overflow || digits.position != input.length) {
    return ParsedResult!T();
  }

  long value = applySign(digits.value, negative);

  if (!isInRange!T(value)) {
    return ParsedResult!T();
  }

  return ParsedResult!T(cast(T) value, true);
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

@("parseSign detects negative sign for int")
unittest {
  auto result = parseSign!int(toHeapString("-42"));
  expect(result.valid).to.equal(true);
  expect(result.negative).to.equal(true);
  expect(result.position).to.equal(1);
}

@("parseSign detects positive sign")
unittest {
  auto result = parseSign!int(toHeapString("+42"));
  expect(result.valid).to.equal(true);
  expect(result.negative).to.equal(false);
  expect(result.position).to.equal(1);
}

@("parseSign handles no sign")
unittest {
  auto result = parseSign!int(toHeapString("42"));
  expect(result.valid).to.equal(true);
  expect(result.negative).to.equal(false);
  expect(result.position).to.equal(0);
}

@("parseSign rejects negative for unsigned")
unittest {
  auto result = parseSign!uint(toHeapString("-42"));
  expect(result.valid).to.equal(false);
}

@("parseSign rejects sign-only string")
unittest {
  auto result = parseSign!int(toHeapString("-"));
  expect(result.valid).to.equal(false);
}

@("isInRange returns true for value in byte range")
unittest {
  expect(isInRange!byte(127)).to.equal(true);
  expect(isInRange!byte(-128)).to.equal(true);
}

@("isInRange returns false for value outside byte range")
unittest {
  expect(isInRange!byte(128)).to.equal(false);
  expect(isInRange!byte(-129)).to.equal(false);
}

@("isInRange returns false for negative value in unsigned type")
unittest {
  expect(isInRange!ubyte(-1)).to.equal(false);
}

@("applySign negates when negative is true")
unittest {
  expect(applySign(42, true)).to.equal(-42);
}

@("applySign does not negate when negative is false")
unittest {
  expect(applySign(42, false)).to.equal(42);
}

@("computeMultiplier computes 10^0")
unittest {
  expect(computeMultiplier!double(0)).to.be.approximately(1.0, 0.001);
}

@("computeMultiplier computes 10^3")
unittest {
  expect(computeMultiplier!double(3)).to.be.approximately(1000.0, 0.001);
}

