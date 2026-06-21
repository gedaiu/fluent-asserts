module fluentasserts.core.conversion.numericcompare;

import fluentasserts.core.conversion.tonumeric : toNumeric;
import fluentasserts.core.memory.heapstring : HeapString;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.memory.heapstring : toHeapString;
}

/// True for the types the numeric comparison operations accept. Matches the
/// constraint of `toNumeric`, so it also covers `char` and `bool` (unlike
/// `std.traits.isNumeric`).
enum isComparableNumeric(T) = __traits(isIntegral, T) || __traits(isFloating, T);

/// The numeric type two values are promoted to before they are compared.
enum CompareType : ubyte {
  asLong,
  asULong,
  asReal
}

/// The ordering of two numeric values parsed from their string form.
struct NumericComparison {
  bool success;
  int order; // -1 when a < b, 0 when equal, 1 when a > b
}

private bool isFloatingTypeName(const(char)[] name) @safe nothrow @nogc {
  return name == "float" || name == "double" || name == "real";
}

private bool isUnsignedTypeName(const(char)[] name) @safe nothrow @nogc {
  return name == "ubyte" || name == "ushort" || name == "uint" || name == "ulong";
}

private bool isSignedTypeName(const(char)[] name) @safe nothrow @nogc {
  return name == "byte" || name == "short" || name == "int" || name == "long";
}

/// Resolves the type two source types are compared in, following D's usual
/// arithmetic conversions. Mixed signed/unsigned operands are compared in
/// `real` (which never wraps) so the result matches their true mathematical
/// value instead of D's unsigned-wrap.
CompareType commonCompareType(const(char)[] typeA, const(char)[] typeB) @safe nothrow @nogc {
  if (isFloatingTypeName(typeA) || isFloatingTypeName(typeB)) {
    return CompareType.asReal;
  }

  if (isUnsignedTypeName(typeA) && isUnsignedTypeName(typeB)) {
    return CompareType.asULong;
  }

  if (isSignedTypeName(typeA) && isSignedTypeName(typeB)) {
    return CompareType.asLong;
  }

  return CompareType.asReal;
}

private NumericComparison compareAs(T)(HeapString a, HeapString b) @safe nothrow @nogc {
  auto parsedA = toNumeric!T(a);
  auto parsedB = toNumeric!T(b);

  if (!parsedA.success || !parsedB.success) {
    return NumericComparison(false, 0);
  }

  int order = parsedA.value < parsedB.value ? -1 : (parsedA.value > parsedB.value ? 1 : 0);
  return NumericComparison(true, order);
}

/// Parses both values using the common type of their source types and returns
/// their ordering. `success` is false when either value can not be parsed.
NumericComparison compareNumeric(const(char)[] typeA, HeapString a,
                                 const(char)[] typeB, HeapString b) @safe nothrow @nogc {
  final switch (commonCompareType(typeA, typeB)) {
    case CompareType.asLong:
      return compareAs!long(a, b);
    case CompareType.asULong:
      return compareAs!ulong(a, b);
    case CompareType.asReal:
      return compareAs!real(a, b);
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

@("isComparableNumeric accepts numeric types and rejects others")
unittest {
  static assert(isComparableNumeric!int);
  static assert(isComparableNumeric!double);
  static assert(isComparableNumeric!ulong);
  static assert(!isComparableNumeric!string);
  static assert(!isComparableNumeric!(int[]));
}

@("commonCompareType promotes a float operand to real")
unittest {
  expect(commonCompareType("int", "double")).to.equal(CompareType.asReal);
  expect(commonCompareType("float", "int")).to.equal(CompareType.asReal);
}

@("commonCompareType keeps two signed integers as long")
unittest {
  expect(commonCompareType("long", "int")).to.equal(CompareType.asLong);
  expect(commonCompareType("byte", "short")).to.equal(CompareType.asLong);
}

@("commonCompareType keeps two unsigned integers as ulong")
unittest {
  expect(commonCompareType("ulong", "ulong")).to.equal(CompareType.asULong);
  expect(commonCompareType("uint", "ulong")).to.equal(CompareType.asULong);
}

@("commonCompareType promotes a signed and unsigned mix to real")
unittest {
  expect(commonCompareType("int", "uint")).to.equal(CompareType.asReal);
  expect(commonCompareType("long", "ulong")).to.equal(CompareType.asReal);
}

@("compareNumeric orders a negative signed value below an unsigned value")
unittest {
  expect(compareNumeric("int", toHeapString("-1"), "uint", toHeapString("1")).order).to.equal(-1);
}

@("compareNumeric orders a larger double above a smaller int")
unittest {
  expect(compareNumeric("double", toHeapString("3.5"), "int", toHeapString("3")).order).to.equal(1);
}

@("compareNumeric reports equal values as zero")
unittest {
  expect(compareNumeric("int", toHeapString("5"), "int", toHeapString("5")).order).to.equal(0);
}

@("compareNumeric fails when a value can not be parsed")
unittest {
  expect(compareNumeric("int", toHeapString("abc"), "int", toHeapString("5")).success).to.equal(false);
}
