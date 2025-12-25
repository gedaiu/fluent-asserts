module fluentasserts.core.conversion.types;

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
