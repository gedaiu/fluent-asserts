module fluentasserts.core.conversion.digits;

import fluentasserts.core.memory.heapstring : HeapString, toHeapString;
import fluentasserts.core.conversion.types : DigitsResult;

version (unittest) {
  import fluent.asserts;
}

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
// Unit tests
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

@("parseDigitsInt parses number")
unittest {
  auto result = parseDigitsInt(toHeapString("42"), 0);
  expect(result.hasDigits).to.equal(true);
  expect(result.value).to.equal(42);
}

