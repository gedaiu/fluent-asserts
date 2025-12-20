/// Template constraint helpers for fluent-asserts evaluation module.
/// Provides reusable type predicates to simplify template constraints.
module fluentasserts.core.evaluation.constraints;

public import std.traits : isArray, isAssociativeArray, isSomeString, isAggregateType;
public import std.range : isInputRange;

/// True if T is a regular array but not a string or void[].
enum bool isRegularArray(T) = isArray!T && !isSomeString!T && !is(T == void[]);

/// True if T is an input range but not an array, associative array, or string.
enum bool isNonArrayRange(T) = isInputRange!T && !isArray!T && !isAssociativeArray!T && !isSomeString!T;

/// True if T has byValue but not byKeyValue (objects with iterable values).
enum bool hasIterableValues(T) = __traits(hasMember, T, "byValue") && !__traits(hasMember, T, "byKeyValue");

/// True if T is an object with byValue that's not an array or associative array.
enum bool isObjectWithByValue(T) = hasIterableValues!T && !isArray!T && !isAssociativeArray!T;

/// True if T is a simple value (not array, range, or associative array, and no byValue).
/// This includes basic types like int, bool, float, structs, classes, etc.
enum bool isSimpleValue(T) = !isArray!T && !isInputRange!T && !isAssociativeArray!T && !hasIterableValues!T;

/// True if T is either a non-array/non-AA type or a string.
/// Used for extractTypes to handle scalars and strings together.
enum bool isScalarOrString(T) = (!isArray!T && !isAssociativeArray!T) || isSomeString!T;

/// True if T is not an input range, or is an array/associative array.
/// Used for evaluate() to handle non-range types and collections.
enum bool isNotRangeOrIsCollection(T) = !isInputRange!T || isArray!T || isAssociativeArray!T;

/// True if T is a primitive type (string, char, or non-collection/non-aggregate type).
/// Used for serialization of basic values.
enum bool isPrimitiveType(T) = isSomeString!T || (!isArray!T && !isAssociativeArray!T && !isAggregateType!T);
