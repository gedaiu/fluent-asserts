module fluentasserts.core.conversion.tonumeric;

import fluentasserts.core.memory.heapstring : HeapString, toHeapString;
import fluentasserts.core.conversion.types : ParsedResult;
import fluentasserts.core.conversion.integers : parseSign, parseUlong, parseSignedIntegral;
import fluentasserts.core.conversion.floats : parseFloating;

version (unittest) {
  import fluent.asserts;
}

/// Parses a string to a numeric type without GC allocations.
///
/// Supports all integral types (byte, ubyte, short, ushort, int, uint, long, ulong)
/// and floating point types (float, double, real).
///
/// Params:
///   input = The string to parse
///
/// Returns:
///   A ParsedResult containing the parsed value and success status.
///
/// Features:
///   $(UL
///     $(LI Handles optional leading '+' or '-' sign)
///     $(LI Detects overflow/underflow for bounded types)
///     $(LI Supports decimal notation for floats (e.g., "3.14"))
///     $(LI Supports scientific notation (e.g., "1.5e-3", "2E10"))
///   )
///
/// Example:
/// ---
/// auto r1 = toNumeric!int("42");
/// assert(r1.success && r1.value == 42);
///
/// auto r2 = toNumeric!double("3.14e2");
/// assert(r2.success && r2.value == 314.0);
///
/// auto r3 = toNumeric!int("not a number");
/// assert(!r3.success);
/// ---
ParsedResult!T toNumeric(T)(HeapString input) @safe nothrow @nogc
if (__traits(isIntegral, T) || __traits(isFloating, T)) {
  if (input.length == 0) {
    return ParsedResult!T();
  }

  auto signResult = parseSign!T(input);
  if (!signResult.valid) {
    return ParsedResult!T();
  }

  static if (__traits(isFloating, T)) {
    return parseFloating!T(input, signResult.position, signResult.negative);
  } else static if (is(T == ulong)) {
    return parseUlong(input, signResult.position);
  } else {
    return parseSignedIntegral!T(input, signResult.position, signResult.negative);
  }
}

// ---------------------------------------------------------------------------
// Unit tests - toNumeric (integral types)
// ---------------------------------------------------------------------------

@("toNumeric parses positive int")
unittest {
  auto result = toNumeric!int(toHeapString("42"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(42);
}

@("toNumeric parses negative int")
unittest {
  auto result = toNumeric!int(toHeapString("-42"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(-42);
}

@("toNumeric parses zero")
unittest {
  auto result = toNumeric!int(toHeapString("0"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(0);
}

@("toNumeric fails on empty string")
unittest {
  auto result = toNumeric!int(toHeapString(""));
  expect(result.success).to.equal(false);
}

@("toNumeric fails on non-numeric string")
unittest {
  auto result = toNumeric!int(toHeapString("abc"));
  expect(result.success).to.equal(false);
}

@("toNumeric fails on mixed content")
unittest {
  auto result = toNumeric!int(toHeapString("42abc"));
  expect(result.success).to.equal(false);
}

@("toNumeric fails on negative for unsigned")
unittest {
  auto result = toNumeric!uint(toHeapString("-1"));
  expect(result.success).to.equal(false);
}

@("toNumeric parses max byte value")
unittest {
  auto result = toNumeric!byte(toHeapString("127"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(127);
}

@("toNumeric fails on overflow for byte")
unittest {
  auto result = toNumeric!byte(toHeapString("128"));
  expect(result.success).to.equal(false);
}

@("toNumeric parses min byte value")
unittest {
  auto result = toNumeric!byte(toHeapString("-128"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(-128);
}

@("toNumeric fails on underflow for byte")
unittest {
  auto result = toNumeric!byte(toHeapString("-129"));
  expect(result.success).to.equal(false);
}

@("toNumeric parses ubyte")
unittest {
  auto result = toNumeric!ubyte(toHeapString("255"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(255);
}

@("toNumeric parses short")
unittest {
  auto result = toNumeric!short(toHeapString("32767"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(32767);
}

@("toNumeric parses ushort")
unittest {
  auto result = toNumeric!ushort(toHeapString("65535"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(65535);
}

@("toNumeric parses long")
unittest {
  auto result = toNumeric!long(toHeapString("9223372036854775807"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(long.max);
}

@("toNumeric parses ulong")
unittest {
  auto result = toNumeric!ulong(toHeapString("12345678901234567890"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(12345678901234567890UL);
}

@("toNumeric handles leading plus sign")
unittest {
  auto result = toNumeric!int(toHeapString("+42"));
  expect(result.success).to.equal(true);
  expect(result.value).to.equal(42);
}

@("toNumeric fails on just minus sign")
unittest {
  auto result = toNumeric!int(toHeapString("-"));
  expect(result.success).to.equal(false);
}

@("toNumeric fails on just plus sign")
unittest {
  auto result = toNumeric!int(toHeapString("+"));
  expect(result.success).to.equal(false);
}

// ---------------------------------------------------------------------------
// Unit tests - toNumeric (floating point types)
// ---------------------------------------------------------------------------

@("toNumeric parses positive float")
unittest {
  auto result = toNumeric!float(toHeapString("3.14"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(3.14, 0.001);
}

@("toNumeric parses negative float")
unittest {
  auto result = toNumeric!float(toHeapString("-3.14"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(-3.14, 0.001);
}

@("toNumeric parses double")
unittest {
  auto result = toNumeric!double(toHeapString("123.456789"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(123.456789, 0.000001);
}

@("toNumeric parses real")
unittest {
  auto result = toNumeric!real(toHeapString("999.999"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(999.999, 0.001);
}

@("toNumeric parses float without decimal part")
unittest {
  auto result = toNumeric!float(toHeapString("42"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(42.0, 0.001);
}

@("toNumeric parses float with trailing decimal")
unittest {
  auto result = toNumeric!float(toHeapString("42."));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(42.0, 0.001);
}

@("toNumeric parses float with scientific notation")
unittest {
  auto result = toNumeric!double(toHeapString("1.5e3"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(1500.0, 0.001);
}

@("toNumeric parses float with negative exponent")
unittest {
  auto result = toNumeric!double(toHeapString("1.5e-3"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(0.0015, 0.0001);
}

@("toNumeric parses float with uppercase E")
unittest {
  auto result = toNumeric!double(toHeapString("2.5E2"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(250.0, 0.001);
}

@("toNumeric parses float with positive exponent sign")
unittest {
  auto result = toNumeric!double(toHeapString("1e+2"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(100.0, 0.001);
}

@("toNumeric fails on invalid exponent")
unittest {
  auto result = toNumeric!double(toHeapString("1e"));
  expect(result.success).to.equal(false);
}

@("toNumeric parses zero float")
unittest {
  auto result = toNumeric!float(toHeapString("0.0"));
  expect(result.success).to.equal(true);
  expect(result.value).to.be.approximately(0.0, 0.001);
}

// ---------------------------------------------------------------------------
// Unit tests - ParsedResult bool cast
// ---------------------------------------------------------------------------

@("ParsedResult casts to bool for success")
unittest {
  auto result = toNumeric!int(toHeapString("42"));
  expect(cast(bool) result).to.equal(true);
}

@("ParsedResult casts to bool for failure")
unittest {
  auto result = toNumeric!int(toHeapString("abc"));
  expect(cast(bool) result).to.equal(false);
}

@("ParsedResult works in if condition")
unittest {
  if (auto result = toNumeric!int(toHeapString("42"))) {
    expect(result.value).to.equal(42);
  } else {
    expect(false).to.equal(true);
  }
}
