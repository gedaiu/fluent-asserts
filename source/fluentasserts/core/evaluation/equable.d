/// Equable value system for fluent-asserts.
/// Provides equableValue functions for converting values to HeapEquableValue for comparisons.
module fluentasserts.core.evaluation.equable;

import std.datetime;
import std.traits;
import std.conv;
import std.range;
import std.array;
import std.algorithm : map, sort;

import fluentasserts.core.memory.heapequable;
import fluentasserts.core.memory.heapstring : HeapData;
import fluentasserts.results.serializers.heap_registry : HeapSerializerRegistry;
import fluentasserts.core.evaluation.constraints;

version(unittest) {
  import fluentasserts.core.lifecycle;
}

/// Wraps a void array into a HeapEquableValue.
HeapEquableValue equableValue(T)(T value, string serialized) if(is(T == void[])) {
  return HeapEquableValue.createArray(serialized);
}

/// Wraps an array into a HeapEquableValue with recursive element conversion.
HeapEquableValue equableValue(T)(T value, string serialized) if(isRegularArray!T) {
  auto result = HeapEquableValue.createArray(serialized);
  foreach(ref elem; value) {
    auto elemSerialized = HeapSerializerRegistry.instance.niceValue(elem);
    result.addElement(equableValue(elem, elemSerialized));
  }
  return result;
}

/// Wraps an input range into a HeapEquableValue by converting to array first.
HeapEquableValue equableValue(T)(T value, string serialized) if(isNonArrayRange!T) {
  auto arr = value.array;
  auto result = HeapEquableValue.createArray(serialized);
  foreach(ref elem; arr) {
    auto elemSerialized = HeapSerializerRegistry.instance.niceValue(elem);
    result.addElement(equableValue(elem, elemSerialized));
  }
  return result;
}

/// Wraps an associative array into a HeapEquableValue with sorted keys.
HeapEquableValue equableValue(T)(T value, string serialized) if(isAssociativeArray!T) {
  auto result = HeapEquableValue.createAssocArray(serialized);
  auto sortedKeys = value.keys.sort;
  foreach(key; sortedKeys) {
    auto keyStr = HeapSerializerRegistry.instance.niceValue(key);
    auto valStr = HeapSerializerRegistry.instance.niceValue(value[key]);
    auto entryStr = keyStr ~ ": " ~ valStr;
    result.addElement(HeapEquableValue.createScalar(entryStr));
  }
  return result;
}

/// Wraps an object with byValue into a HeapEquableValue.
HeapEquableValue equableValue(T)(T value, string serialized) if(isObjectWithByValue!T) {
  if (value is null) {
    return HeapEquableValue.createScalar(serialized);
  }
  auto result = HeapEquableValue.createArray(serialized);
  try {
    foreach(elem; value.byValue) {
      auto elemSerialized = HeapSerializerRegistry.instance.niceValue(elem);
      result.addElement(equableValue(elem, elemSerialized));
    }
  } catch (Exception) {
    return HeapEquableValue.createScalar(serialized);
  }
  return result;
}

/// Wraps a string into a HeapEquableValue.
HeapEquableValue equableValue(T)(T value, string serialized) if(isSomeString!T) {
  return HeapEquableValue.createScalar(serialized);
}

/// Wraps a scalar value into a HeapEquableValue.
HeapEquableValue equableValue(T)(T value, string serialized)
  if(isSimpleValue!T && !isCallable!T && !is(T == class) && !is(T : Object))
{
  return HeapEquableValue.createScalar(serialized);
}

/// Simple wrapper to hold a callable for comparison.
class CallableWrapper(T) if(isCallable!T) {
  T func;

  this(T f) @trusted nothrow {
    func = f;
  }

  override bool opEquals(Object other) @trusted nothrow {
    auto o = cast(CallableWrapper!T)other;
    if (o is null) {
      return false;
    }
    static if (__traits(compiles, func == o.func)) {
      return func == o.func;
    } else {
      return false;
    }
  }
}

/// Wraps a callable into a HeapEquableValue using a wrapper object.
HeapEquableValue equableValue(T)(T value, string serialized)
  if(isCallable!T && !isObjectWithByValue!T)
{
  auto wrapper = new CallableWrapper!T(value);
  return HeapEquableValue.createObject(serialized, wrapper);
}

/// Wraps an object into a HeapEquableValue with object reference for opEquals comparison.
HeapEquableValue equableValue(T)(T value, string serialized)
  if((is(T == class) || is(T : Object)) && !isCallable!T && !isObjectWithByValue!T)
{
  return HeapEquableValue.createObject(serialized, cast(Object)value);
}

// --- @nogc versions for primitive types only ---
// Only void[] and string types have truly @nogc equableValue overloads.
// Other types (arrays, assoc arrays, objects) require GC allocations during
// recursive processing and should use the string-parameter versions above.

/// Wraps a void array into a HeapEquableValue (@nogc version).
/// This is one of only two truly @nogc equableValue overloads.
HeapEquableValue equableValue(T)(T value) @trusted nothrow @nogc if(is(T == void[])) {
  auto serialized = HeapSerializerRegistry.instance.serialize(value);
  return HeapEquableValue.createArray(serialized[]);
}

/// Wraps a string into a HeapEquableValue (@nogc version).
/// This is one of only two truly @nogc equableValue overloads.
/// Used by NoGCExpect for primitive type assertions.
HeapEquableValue equableValue(T)(T value) @trusted nothrow @nogc if(isSomeString!T) {
  auto serialized = HeapSerializerRegistry.instance.serialize(value);
  return HeapEquableValue.createScalar(serialized[]);
}

/// Wraps a scalar value into a HeapEquableValue (nothrow version).
/// Used by NoGCExpect for numeric primitive assertions.
/// Note: Not @nogc because numeric serialization uses .to!string which allocates.
HeapEquableValue equableValue(T)(T value) @trusted nothrow if(isSimpleValue!T && !isSomeString!T) {
  auto serialized = HeapSerializerRegistry.instance.serialize(value);
  return HeapEquableValue.createScalar(serialized[]);
}

// --- HeapData!char (HeapString) overloads ---
// These mirror the string overloads above but work with HeapString serialization

/// Wraps a void array into a HeapEquableValue (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted nothrow @nogc
  if(is(T == void[]) && is(U == HeapData!char))
{
  return HeapEquableValue.createArray(serialized[]);
}

/// Wraps an array into a HeapEquableValue with recursive element conversion (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted
  if(isRegularArray!T && is(U == HeapData!char))
{
  auto result = HeapEquableValue.createArray(serialized[]);
  foreach(ref elem; value) {
    auto elemSerialized = HeapSerializerRegistry.instance.niceValue(elem);
    result.addElement(equableValue(elem, elemSerialized));
  }
  return result;
}

/// Wraps an input range into a HeapEquableValue by converting to array first (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted
  if(isNonArrayRange!T && is(U == HeapData!char))
{
  auto arr = value.array;
  auto result = HeapEquableValue.createArray(serialized[]);
  foreach(ref elem; arr) {
    auto elemSerialized = HeapSerializerRegistry.instance.niceValue(elem);
    result.addElement(equableValue(elem, elemSerialized));
  }
  return result;
}

/// Wraps an associative array into a HeapEquableValue with sorted keys (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted
  if(isAssociativeArray!T && is(U == HeapData!char))
{
  auto result = HeapEquableValue.createAssocArray(serialized[]);
  auto sortedKeys = value.keys.sort;
  foreach(key; sortedKeys) {
    auto keyStr = HeapSerializerRegistry.instance.niceValue(key);
    auto valStr = HeapSerializerRegistry.instance.niceValue(value[key]);
    auto entryStr = keyStr ~ ": " ~ valStr;
    result.addElement(HeapEquableValue.createScalar(entryStr[]));
  }
  return result;
}

/// Wraps an object with byValue into a HeapEquableValue (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted
  if(isObjectWithByValue!T && is(U == HeapData!char))
{
  if (value is null) {
    return HeapEquableValue.createScalar(serialized[]);
  }
  auto result = HeapEquableValue.createArray(serialized[]);
  try {
    foreach(elem; value.byValue) {
      auto elemSerialized = HeapSerializerRegistry.instance.niceValue(elem);
      result.addElement(equableValue(elem, elemSerialized));
    }
  } catch (Exception) {
    return HeapEquableValue.createScalar(serialized[]);
  }
  return result;
}

/// Wraps a string into a HeapEquableValue (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted nothrow @nogc
  if(isSomeString!T && is(U == HeapData!char))
{
  return HeapEquableValue.createScalar(serialized[]);
}

/// Wraps a scalar value into a HeapEquableValue (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted nothrow @nogc
  if(isSimpleValue!T && !isCallable!T && !is(T == class) && !is(T : Object) && is(U == HeapData!char))
{
  return HeapEquableValue.createScalar(serialized[]);
}

/// Wraps a callable into a HeapEquableValue using a wrapper object (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted
  if(isCallable!T && !isObjectWithByValue!T && is(U == HeapData!char))
{
  auto wrapper = new CallableWrapper!T(value);
  return HeapEquableValue.createObject(serialized[], wrapper);
}

/// Wraps an object into a HeapEquableValue with object reference for opEquals comparison (HeapString version).
HeapEquableValue equableValue(T, U)(T value, U serialized) @trusted
  if((is(T == class) || is(T : Object)) && !isCallable!T && !isObjectWithByValue!T && is(U == HeapData!char))
{
  return HeapEquableValue.createObject(serialized[], cast(Object)value);
}
