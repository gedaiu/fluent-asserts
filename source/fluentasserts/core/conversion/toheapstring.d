module fluentasserts.core.conversion.toheapstring;

import fluentasserts.core.memory.heapstring : HeapString;
import fluentasserts.core.config : config = FluentAssertsConfig;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.memory.heapstring : toHeapString;
}

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

/// Result type for string conversion operations.
/// Contains the string value and a success flag.
///
/// Supports implicit conversion to bool for convenient use in conditions:
/// ---
/// if (auto result = toHeapString(42)) {
///   writeln(result.value[]); // "42"
/// }
/// ---
struct StringResult {
  /// The string value. Only valid when `success` is true.
  HeapString value;

  /// Indicates whether conversion succeeded.
  bool success;

  /// Allows using StringResult directly in boolean contexts.
  bool opCast(T : bool)() const @safe nothrow @nogc {
    return success;
  }
}

// ---------------------------------------------------------------------------
// Main conversion function
// ---------------------------------------------------------------------------

/// Converts a primitive value to a HeapString without GC allocations.
///
/// Supports all integral types (bool, byte, ubyte, short, ushort, int, uint, long, ulong, char, wchar, dchar)
/// and floating point types (float, double, real).
///
/// Params:
///   value = The primitive value to convert
///
/// Returns:
///   A StringResult containing the string representation and success status.
///
/// Features:
///   $(UL
///     $(LI @nogc, nothrow, @safe - no GC allocations or exceptions)
///     $(LI Handles negative numbers with '-' prefix)
///     $(LI Handles boolean values as "true" or "false")
///     $(LI Handles floating point with decimal notation)
///   )
///
/// Example:
/// ---
/// auto s1 = toHeapString(42);
/// assert(s1.success && s1.value[] == "42");
///
/// auto s2 = toHeapString(-123);
/// assert(s2.success && s2.value[] == "-123");
///
/// auto s3 = toHeapString(true);
/// assert(s3.success && s3.value[] == "true");
///
/// auto s4 = toHeapString(3.14);
/// assert(s4.success);
/// ---
StringResult toHeapString(T)(T value) @safe nothrow @nogc
if (__traits(isIntegral, T) || __traits(isFloating, T)) {
  static if (is(T == bool)) {
    return StringResult(toBoolString(value), true);
  } else static if (__traits(isIntegral, T)) {
    return StringResult(toIntegralString(value), true);
  } else static if (__traits(isFloating, T)) {
    return StringResult(toFloatingString(value), true);
  }
}

// ---------------------------------------------------------------------------
// Boolean conversion
// ---------------------------------------------------------------------------

/// Converts a boolean value to a HeapString.
///
/// Params:
///   value = The boolean value to convert
///
/// Returns:
///   "true" or "false" as a HeapString.
HeapString toBoolString(bool value) @safe nothrow @nogc {
  auto result = HeapString.create(value ? 4 : 5);
  if (value) {
    result.put("true");
  } else {
    result.put("false");
  }
  return result;
}

// ---------------------------------------------------------------------------
// Integral conversion
// ---------------------------------------------------------------------------

/// Converts an integral value to a HeapString.
///
/// Handles signed and unsigned integers of all sizes.
///
/// Params:
///   value = The integral value to convert
///
/// Returns:
///   The string representation of the value.
HeapString toIntegralString(T)(T value) @safe nothrow @nogc
if (__traits(isIntegral, T) && !is(T == bool)) {
  // Handle special case of 0
  if (value == 0) {
    auto result = HeapString.create(1);
    result.put("0");
    return result;
  }

  // Determine if negative and get absolute value
  bool isNegative = false;
  static if (__traits(isUnsigned, T)) {
    ulong absValue = value;
  } else {
    ulong absValue;
    if (value < 0) {
      isNegative = true;
      // Handle T.min specially to avoid overflow
      if (value == T.min) {
        absValue = cast(ulong)(-(value + 1)) + 1;
      } else {
        absValue = cast(ulong)(-value);
      }
    } else {
      absValue = cast(ulong)value;
    }
  }

  // Count digits
  ulong temp = absValue;
  size_t digitCount = 0;
  while (temp > 0) {
    digitCount++;
    temp /= 10;
  }

  // Calculate total length (digits + sign if negative)
  size_t totalLength = digitCount + (isNegative ? 1 : 0);
  auto result = HeapString.create(totalLength);

  // Add negative sign if needed
  if (isNegative) {
    result.put("-");
  }

  // Convert digits in reverse order, then reverse the string
  char[config.numeric.digitConversionBufferSize] buffer;
  size_t bufferIdx = 0;

  temp = absValue;
  while (temp > 0) {
    buffer[bufferIdx++] = cast(char)('0' + (temp % 10));
    temp /= 10;
  }

  // Reverse and add to result
  for (size_t i = bufferIdx; i > 0; i--) {
    result.put(buffer[i - 1]);
  }

  return result;
}

// ---------------------------------------------------------------------------
// Floating point conversion
// ---------------------------------------------------------------------------

/// Converts a floating point value to a HeapString.
///
/// Handles float, double, and real types with reasonable precision.
///
/// Params:
///   value = The floating point value to convert
///   precision = Maximum decimal places (0 = use config default)
///
/// Returns:
///   The string representation of the value.
HeapString toFloatingString(T)(T value, size_t precision = 0) @safe nothrow @nogc
if (__traits(isFloating, T)) {
  // Handle special cases
  if (value != value) { // NaN check
    auto result = HeapString.create(3);
    result.put("nan");
    return result;
  }

  if (value == T.infinity) {
    auto result = HeapString.create(3);
    result.put("inf");
    return result;
  }

  if (value == -T.infinity) {
    auto result = HeapString.create(4);
    result.put("-inf");
    return result;
  }

  // Handle zero
  if (value == 0.0) {
    auto result = HeapString.create(1);
    result.put("0");
    return result;
  }

  auto result = HeapString.create();

  // Handle negative
  bool isNegative = value < 0;
  if (isNegative) {
    result.put("-");
    value = -value;
  }

  // Get integral part
  ulong integralPart = cast(ulong)value;
  auto integralStr = toIntegralString(integralPart);
  result.put(integralStr[]);

  // Get fractional part
  T fractional = value - integralPart;

  // Use provided precision or fall back to config default
  immutable maxDecimals = precision > 0 ? precision : config.numeric.floatingPointDecimals;

  // Only add decimal point if there's a fractional part
  if (fractional > 0.0) {
    result.put(".");

    // Convert up to specified decimal places
    for (size_t i = 0; i < maxDecimals && fractional > 0.0; i++) {
      fractional *= 10;
      int digit = cast(int)fractional;
      result.put(cast(char)('0' + digit));
      fractional -= digit;
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// Unit tests - bool conversion
// ---------------------------------------------------------------------------

@("toHeapString converts true to 'true'")
unittest {
  auto result = toHeapString(true);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("true");
}

@("toHeapString converts false to 'false'")
unittest {
  auto result = toHeapString(false);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("false");
}

// ---------------------------------------------------------------------------
// Unit tests - integral conversion
// ---------------------------------------------------------------------------

@("toHeapString converts zero")
unittest {
  auto result = toHeapString(0);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("0");
}

@("toHeapString converts positive int")
unittest {
  auto result = toHeapString(42);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("42");
}

@("toHeapString converts negative int")
unittest {
  auto result = toHeapString(-42);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("-42");
}

@("toHeapString converts large number")
unittest {
  auto result = toHeapString(123456789);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("123456789");
}

@("toHeapString converts byte max")
unittest {
  auto result = toHeapString(cast(byte)127);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("127");
}

@("toHeapString converts byte min")
unittest {
  auto result = toHeapString(cast(byte)-128);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("-128");
}

@("toHeapString converts ubyte max")
unittest {
  auto result = toHeapString(cast(ubyte)255);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("255");
}

@("toHeapString converts short max")
unittest {
  auto result = toHeapString(cast(short)32767);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("32767");
}

@("toHeapString converts short min")
unittest {
  auto result = toHeapString(cast(short)-32768);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("-32768");
}

@("toHeapString converts int max")
unittest {
  auto result = toHeapString(2147483647);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("2147483647");
}

@("toHeapString converts int min")
unittest {
  auto result = toHeapString(-2147483648);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("-2147483648");
}

@("toHeapString converts long")
unittest {
  auto result = toHeapString(9223372036854775807L);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("9223372036854775807");
}

@("toHeapString converts long min")
unittest {
  long minValue = long.min;
  auto result = toHeapString(minValue);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("-9223372036854775808");
}

@("toHeapString converts ulong max")
unittest {
  auto result = toHeapString(18446744073709551615UL);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("18446744073709551615");
}

// ---------------------------------------------------------------------------
// Unit tests - floating point conversion
// ---------------------------------------------------------------------------

@("toHeapString converts float zero")
unittest {
  auto result = toHeapString(0.0f);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("0");
}

@("toHeapString converts double zero")
unittest {
  auto result = toHeapString(0.0);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("0");
}

@("toHeapString converts positive float")
unittest {
  auto result = toHeapString(3.14f);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.startWith("3.14");
}

@("toHeapString converts negative float")
unittest {
  auto result = toHeapString(-2.5f);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.startWith("-2.5");
}

@("toHeapString converts float with no fractional part")
unittest {
  auto result = toHeapString(42.0f);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("42");
}

@("toHeapString converts double")
unittest {
  auto result = toHeapString(1.5);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.startWith("1.5");
}

@("toHeapString converts float NaN")
unittest {
  auto result = toHeapString(float.nan);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("nan");
}

@("toHeapString converts float infinity")
unittest {
  auto result = toHeapString(float.infinity);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("inf");
}

@("toHeapString converts float negative infinity")
unittest {
  auto result = toHeapString(-float.infinity);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("-inf");
}

@("toHeapString converts large float")
unittest {
  auto result = toHeapString(123456.789f);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.startWith("123456.78");
}

// ---------------------------------------------------------------------------
// Unit tests - character types
// ---------------------------------------------------------------------------

@("toHeapString converts char")
unittest {
  auto result = toHeapString(cast(char)65);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("65");
}

@("toHeapString converts wchar")
unittest {
  auto result = toHeapString(cast(wchar)65);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("65");
}

@("toHeapString converts dchar")
unittest {
  auto result = toHeapString(cast(dchar)65);
  expect(result.success).to.equal(true);
  expect(result.value[]).to.equal("65");
}
