module fluentasserts.core.conversion.floats;

import fluentasserts.core.memory.heapstring : HeapString, toHeapString;
import fluentasserts.core.conversion.types : ParsedResult, FractionResult;
import fluentasserts.core.conversion.digits : isDigit, parseDigitsInt;
import fluentasserts.core.conversion.integers : applySign, computeMultiplier;

version (unittest) {
  import fluent.asserts;
}

/// Parses a string as a double value.
///
/// A simple parser for numeric strings that handles integers, decimals,
/// and scientific notation (e.g., "1.0032e+06").
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
    } else if ((c == 'e' || c == 'E') && seenDigit) {
      // Handle scientific notation
      i++;
      if (i >= s.length) {
        return 0.0;
      }

      bool expNegative = false;
      if (s[i] == '-') {
        expNegative = true;
        i++;
      } else if (s[i] == '+') {
        i++;
      }

      if (i >= s.length) {
        return 0.0;
      }

      int exponent = 0;
      bool seenExpDigit = false;
      for (; i < s.length; i++) {
        char ec = s[i];
        if (ec >= '0' && ec <= '9') {
          seenExpDigit = true;
          exponent = exponent * 10 + (ec - '0');
        } else {
          return 0.0;
        }
      }

      if (!seenExpDigit) {
        return 0.0;
      }

      // Apply exponent
      double multiplier = 1.0;
      for (int j = 0; j < exponent; j++) {
        multiplier *= 10.0;
      }

      if (expNegative) {
        result /= multiplier;
      } else {
        result *= multiplier;
      }

      break;
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

// ---------------------------------------------------------------------------
// Unit tests
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

@("parseDouble parses scientific notation 1.0032e+06")
unittest {
  import std.math : abs;
  bool success;
  double val = parseDouble("1.0032e+06", success);
  assert(success, "parseDouble should succeed for scientific notation");
  // Use approximate comparison for floating point
  assert(abs(val - 1003200.0) < 0.01, "1.0032e+06 should parse to approximately 1003200.0");
}

@("parseDouble parses integer 1003200")
unittest {
  bool success;
  double val = parseDouble("1003200", success);
  assert(success, "parseDouble should succeed for integer");
  assert(val == 1003200.0, "1003200 should parse to 1003200.0");
}

