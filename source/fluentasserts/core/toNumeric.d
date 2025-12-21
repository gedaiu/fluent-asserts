module fluentasserts.core.toNumeric;

import fluentasserts.core.memory.heapstring : HeapString, toHeapString;

version (unittest) {
  import fluent.asserts;
}

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

/// Result type for numeric parsing operations.
/// Contains the parsed value and a success flag.
///
/// Supports implicit conversion to bool for convenient use in conditions:
/// ---
/// if (auto result = toNumeric!int("42")) {
///   writeln(result.value); // 42
/// }
/// ---
struct ParsedResult(T) {
  /// The parsed numeric value. Only valid when `success` is true.
  T value;

  /// Indicates whether parsing succeeded.
  bool success;

  /// Allows using ParsedResult directly in boolean contexts.
  bool opCast(T : bool)() const @safe nothrow @nogc {
    return success;
  }
}

/// Result of sign parsing operation.
/// Contains the position after the sign and whether the value is negative.
struct SignResult {
  /// Position in the string after the sign character.
  size_t position;

  /// Whether a negative sign was found.
  bool negative;

  /// Whether the sign parsing was valid.
  bool valid;
}

/// Result of digit parsing operation.
/// Contains the parsed value, final position, and status flags.
struct DigitsResult(T) {
  /// The accumulated numeric value.
  T value;

  /// Position in the string after the last digit.
  size_t position;

  /// Whether at least one digit was parsed.
  bool hasDigits;

  /// Whether an overflow occurred during parsing.
  bool overflow;
}

/// Result of fraction parsing operation.
/// Contains the fractional value and parsing status.
struct FractionResult(T) {
  /// The fractional value (between 0 and 1).
  T value;

  /// Position in the string after the last digit.
  size_t position;

  /// Whether at least one digit was parsed.
  bool hasDigits;
}

// ---------------------------------------------------------------------------
// Main parsing function
// ---------------------------------------------------------------------------

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
// Character helpers
// ---------------------------------------------------------------------------

/// Checks if a character is a decimal digit (0-9).
///
/// Params:
///   c = The character to check
///
/// Returns:
///   true if the character is between '0' and '9', false otherwise.
bool isDigit(char c) @safe nothrow @nogc {
  return c >= '0' && c <= '9';
}

/// Parses a string as a double value.
///
/// A simple parser for numeric strings that handles integers and decimals.
/// Does not support scientific notation.
///
/// Params:
///   s = The string to parse
///   success = Output parameter set to true if parsing succeeded
///
/// Returns:
///   The parsed double value, or 0.0 if parsing failed.
double parseDouble(const(char)[] s, out bool success) @nogc nothrow pure @safe {
  success = false;
  if (s.length == 0) {
    return 0.0;
  }

  double result = 0.0;
  double fraction = 0.1;
  bool negative = false;
  bool seenDot = false;
  bool seenDigit = false;
  size_t i = 0;

  if (s[0] == '-') {
    negative = true;
    i = 1;
  } else if (s[0] == '+') {
    i = 1;
  }

  for (; i < s.length; i++) {
    char c = s[i];
    if (c >= '0' && c <= '9') {
      seenDigit = true;
      if (seenDot) {
        result += (c - '0') * fraction;
        fraction *= 0.1;
      } else {
        result = result * 10 + (c - '0');
      }
    } else if (c == '.' && !seenDot) {
      seenDot = true;
    } else {
      return 0.0;
    }
  }

  if (!seenDigit) {
    return 0.0;
  }

  success = true;
  return negative ? -result : result;
}

// ---------------------------------------------------------------------------
// Sign parsing
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Digit parsing
// ---------------------------------------------------------------------------

/// Parses consecutive digits into a long value with overflow detection.
///
/// Params:
///   input = The string to parse
///   i = Starting position in the string
///
/// Returns:
///   A DigitsResult containing the parsed value and status.
DigitsResult!long parseDigitsLong(HeapString input, size_t i) @safe nothrow @nogc {
  DigitsResult!long result;
  result.position = i;

  while (result.position < input.length && isDigit(input[result.position])) {
    result.hasDigits = true;
    int digit = input[result.position] - '0';

    if (result.value > (long.max - digit) / 10) {
      result.overflow = true;
      return result;
    }

    result.value = result.value * 10 + digit;
    result.position++;
  }

  return result;
}

/// Parses consecutive digits into a ulong value with overflow detection.
///
/// Params:
///   input = The string to parse
///   i = Starting position in the string
///
/// Returns:
///   A DigitsResult containing the parsed value and status.
DigitsResult!ulong parseDigitsUlong(HeapString input, size_t i) @safe nothrow @nogc {
  DigitsResult!ulong result;
  result.position = i;

  while (result.position < input.length && isDigit(input[result.position])) {
    result.hasDigits = true;
    uint digit = input[result.position] - '0';

    if (result.value > (ulong.max - digit) / 10) {
      result.overflow = true;
      return result;
    }

    result.value = result.value * 10 + digit;
    result.position++;
  }

  return result;
}

/// Parses consecutive digits into an int value.
///
/// Params:
///   input = The string to parse
///   i = Starting position in the string
///
/// Returns:
///   A DigitsResult containing the parsed value and status.
DigitsResult!int parseDigitsInt(HeapString input, size_t i) @safe nothrow @nogc {
  DigitsResult!int result;
  result.position = i;

  while (result.position < input.length && isDigit(input[result.position])) {
    result.hasDigits = true;
    result.value = result.value * 10 + (input[result.position] - '0');
    result.position++;
  }

  return result;
}

// ---------------------------------------------------------------------------
// Value helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Integral parsing
// ---------------------------------------------------------------------------

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
// Floating point parsing
// ---------------------------------------------------------------------------

/// Parses the fractional part of a floating point number.
///
/// Expects to start after the decimal point.
///
/// Params:
///   input = The string to parse
///   i = Starting position (after the decimal point)
///
/// Returns:
///   A FractionResult containing the fractional value (between 0 and 1).
FractionResult!T parseFraction(T)(HeapString input, size_t i) @safe nothrow @nogc {
  FractionResult!T result;
  result.position = i;

  T fraction = 0;
  T divisor = 1;

  while (result.position < input.length && isDigit(input[result.position])) {
    result.hasDigits = true;
    fraction = fraction * 10 + (input[result.position] - '0');
    divisor *= 10;
    result.position++;
  }

  result.value = fraction / divisor;
  return result;
}

/// Parses a floating point number from a string.
///
/// Supports decimal notation and scientific notation.
///
/// Params:
///   input = The string to parse
///   i = Starting position in the string
///   negative = Whether the value should be negated
///
/// Returns:
///   A ParsedResult containing the parsed floating point value.
ParsedResult!T parseFloating(T)(HeapString input, size_t i, bool negative) @safe nothrow @nogc {
  T value = 0;
  bool hasDigits = false;

  while (i < input.length && isDigit(input[i])) {
    hasDigits = true;
    value = value * 10 + (input[i] - '0');
    i++;
  }

  if (i < input.length && input[i] == '.') {
    auto frac = parseFraction!T(input, i + 1);
    hasDigits = hasDigits || frac.hasDigits;
    value += frac.value;
    i = frac.position;
  }

  if (i < input.length && (input[i] == 'e' || input[i] == 'E')) {
    auto expResult = parseExponent!T(input, i + 1, value);
    if (!expResult.success) {
      return ParsedResult!T();
    }
    value = expResult.value;
    i = input.length;
  }

  if (i != input.length || !hasDigits) {
    return ParsedResult!T();
  }

  return ParsedResult!T(applySign(value, negative), true);
}

/// Parses the exponent part of a floating point number in scientific notation.
///
/// Expects to start after the 'e' or 'E' character.
///
/// Params:
///   input = The string to parse
///   i = Starting position (after 'e' or 'E')
///   baseValue = The mantissa value to apply the exponent to
///
/// Returns:
///   A ParsedResult containing the value with exponent applied.
ParsedResult!T parseExponent(T)(HeapString input, size_t i, T baseValue) @safe nothrow @nogc {
  if (i >= input.length) {
    return ParsedResult!T();
  }

  bool expNegative = false;
  if (input[i] == '-') {
    expNegative = true;
    i++;
  } else if (input[i] == '+') {
    i++;
  }

  auto digits = parseDigitsInt(input, i);

  if (!digits.hasDigits || digits.position != input.length) {
    return ParsedResult!T();
  }

  T multiplier = computeMultiplier!T(digits.value);
  T value = expNegative ? baseValue / multiplier : baseValue * multiplier;

  return ParsedResult!T(value, true);
}

// ---------------------------------------------------------------------------
// Unit tests - isDigit
// ---------------------------------------------------------------------------

@("isDigit returns true for '0'")
unittest {
  expect(isDigit('0')).to.equal(true);
}

@("isDigit returns true for '9'")
unittest {
  expect(isDigit('9')).to.equal(true);
}

@("isDigit returns true for '5'")
unittest {
  expect(isDigit('5')).to.equal(true);
}

@("isDigit returns false for 'a'")
unittest {
  expect(isDigit('a')).to.equal(false);
}

@("isDigit returns false for ' '")
unittest {
  expect(isDigit(' ')).to.equal(false);
}

@("isDigit returns false for '-'")
unittest {
  expect(isDigit('-')).to.equal(false);
}

// ---------------------------------------------------------------------------
// Unit tests - parseSign
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

// ---------------------------------------------------------------------------
// Unit tests - parseDigitsLong
// ---------------------------------------------------------------------------

@("parseDigitsLong parses simple number")
unittest {
  auto result = parseDigitsLong(toHeapString("12345"), 0);
  expect(result.hasDigits).to.equal(true);
  expect(result.overflow).to.equal(false);
  expect(result.value).to.equal(12345);
  expect(result.position).to.equal(5);
}

@("parseDigitsLong parses from offset")
unittest {
  auto result = parseDigitsLong(toHeapString("abc123def"), 3);
  expect(result.hasDigits).to.equal(true);
  expect(result.value).to.equal(123);
  expect(result.position).to.equal(6);
}

@("parseDigitsLong handles no digits")
unittest {
  auto result = parseDigitsLong(toHeapString("abc"), 0);
  expect(result.hasDigits).to.equal(false);
  expect(result.position).to.equal(0);
}

@("parseDigitsLong detects overflow")
unittest {
  auto result = parseDigitsLong(toHeapString("99999999999999999999"), 0);
  expect(result.overflow).to.equal(true);
}

// ---------------------------------------------------------------------------
// Unit tests - parseDigitsUlong
// ---------------------------------------------------------------------------

@("parseDigitsUlong parses large number")
unittest {
  auto result = parseDigitsUlong(toHeapString("12345678901234567890"), 0);
  expect(result.hasDigits).to.equal(true);
  expect(result.overflow).to.equal(false);
  expect(result.value).to.equal(12345678901234567890UL);
}

@("parseDigitsUlong detects overflow")
unittest {
  auto result = parseDigitsUlong(toHeapString("99999999999999999999"), 0);
  expect(result.overflow).to.equal(true);
}

// ---------------------------------------------------------------------------
// Unit tests - parseDigitsInt
// ---------------------------------------------------------------------------

@("parseDigitsInt parses number")
unittest {
  auto result = parseDigitsInt(toHeapString("42"), 0);
  expect(result.hasDigits).to.equal(true);
  expect(result.value).to.equal(42);
}

// ---------------------------------------------------------------------------
// Unit tests - isInRange
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Unit tests - applySign
// ---------------------------------------------------------------------------

@("applySign negates when negative is true")
unittest {
  expect(applySign(42, true)).to.equal(-42);
}

@("applySign does not negate when negative is false")
unittest {
  expect(applySign(42, false)).to.equal(42);
}

// ---------------------------------------------------------------------------
// Unit tests - computeMultiplier
// ---------------------------------------------------------------------------

@("computeMultiplier computes 10^0")
unittest {
  expect(computeMultiplier!double(0)).to.be.approximately(1.0, 0.001);
}

@("computeMultiplier computes 10^3")
unittest {
  expect(computeMultiplier!double(3)).to.be.approximately(1000.0, 0.001);
}

// ---------------------------------------------------------------------------
// Unit tests - parseFraction
// ---------------------------------------------------------------------------

@("parseFraction parses .5")
unittest {
  auto result = parseFraction!double(toHeapString("5"), 0);
  expect(result.hasDigits).to.equal(true);
  expect(result.value).to.be.approximately(0.5, 0.001);
}

@("parseFraction parses .25")
unittest {
  auto result = parseFraction!double(toHeapString("25"), 0);
  expect(result.hasDigits).to.equal(true);
  expect(result.value).to.be.approximately(0.25, 0.001);
}

@("parseFraction parses .125")
unittest {
  auto result = parseFraction!double(toHeapString("125"), 0);
  expect(result.hasDigits).to.equal(true);
  expect(result.value).to.be.approximately(0.125, 0.001);
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
