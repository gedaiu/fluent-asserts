/// Value evaluation structures for fluent-asserts.
/// Provides ValueEvaluation and EvaluationResult for capturing assertion state.
module fluentasserts.core.evaluation.value;

import std.datetime;
import std.traits;

import fluentasserts.core.memory.heapstring;
import fluentasserts.core.memory.fixedmeta;
import fluentasserts.core.memory.typenamelist;
import fluentasserts.core.memory.heapequable;
import fluentasserts.core.evaluation.equable;

struct ValueEvaluation {
  /// The exception thrown during evaluation
  Throwable throwable;

  /// Time needed to evaluate the value
  Duration duration;

  /// Garbage Collector memory used during evaluation (in bytes)
  size_t gcMemoryUsed;

  /// Non Garbage Collector memory used during evaluation (in bytes)
  size_t nonGCMemoryUsed;

  /// Serialized value as string
  HeapString strValue;

  /// Proxy object holding the evaluated value to help doing better comparisions
  HeapEquableValue proxyValue;

  /// Human readable value
  HeapString niceValue;

  /// The name of the type before it was converted to string (using TypeNameList for @nogc compatibility)
  TypeNameList typeNames;

  /// Other info about the value (using FixedMeta for @nogc compatibility)
  FixedMeta meta;

  /// The file name containing the evaluated value
  HeapString fileName;

  /// The line number of the evaluated value
  size_t line;

  /// a custom text to be prepended to the value
  HeapString prependText;

  /// Disable postblit - use copy constructor instead
  @disable this(this);

  /// Copy constructor - creates a deep copy from the source.
  this(ref return scope const ValueEvaluation rhs) @safe nothrow {
    () @trusted { throwable = cast(Throwable) rhs.throwable; }();
    duration = rhs.duration;
    gcMemoryUsed = rhs.gcMemoryUsed;
    nonGCMemoryUsed = rhs.nonGCMemoryUsed;
    strValue = rhs.strValue;
    proxyValue = HeapEquableValue(rhs.proxyValue);
    niceValue = rhs.niceValue;
    typeNames = rhs.typeNames;
    meta = rhs.meta;
    fileName = rhs.fileName;
    line = rhs.line;
    prependText = rhs.prependText;
  }

  /// Assignment operator - creates a deep copy from the source.
  void opAssign(ref const ValueEvaluation rhs) @trusted nothrow {
    throwable = cast(Throwable) rhs.throwable;
    duration = rhs.duration;
    gcMemoryUsed = rhs.gcMemoryUsed;
    nonGCMemoryUsed = rhs.nonGCMemoryUsed;
    strValue = rhs.strValue;
    proxyValue = HeapEquableValue(rhs.proxyValue);
    niceValue = rhs.niceValue;
    typeNames = rhs.typeNames;
    meta = rhs.meta;
    fileName = rhs.fileName;
    line = rhs.line;
    prependText = rhs.prependText;
  }


  /// Returns true if this ValueEvaluation's HeapString fields are valid.
  bool isValid() @trusted nothrow @nogc const {
    return strValue.isValid() && niceValue.isValid();
  }

  /// Returns the primary type name of the evaluated value.
  const(char)[] typeName() @safe nothrow @nogc {
    if (typeNames.length == 0) {
      return "unknown";
    }
    return typeNames[0][];
  }
}

struct EvaluationResult(T) {
  import std.traits : Unqual, isCopyable;

  Unqual!T value;
  ValueEvaluation evaluation;

  /// Disable postblit - use copy constructor instead
  @disable this(this);

  private static void assignValue(ref Unqual!T dest, ref const EvaluationResult src) @trusted nothrow {
    static if (__traits(compiles, { Unqual!T v; v = cast(Unqual!T) src.value; }())) {
      static if (__traits(compiles, (ref Unqual!T v, ref const EvaluationResult s) nothrow { v = cast(Unqual!T) s.value; })) {
        dest = cast(Unqual!T) src.value;
      }
    } else static if (isCopyable!(const(Unqual!T))) {
      static if (__traits(compiles, (ref Unqual!T v, ref const EvaluationResult s) nothrow { v = s.value; })) {
        dest = src.value;
      }
    }
  }

  /// Copy constructor - creates a deep copy from the source.
  this(ref return scope const EvaluationResult rhs) @trusted nothrow {
    assignValue(value, rhs);
    evaluation.opAssign(rhs.evaluation);
  }

  void opAssign(ref const EvaluationResult rhs) @trusted nothrow {
    assignValue(value, rhs);
    evaluation.opAssign(rhs.evaluation);
  }
}
