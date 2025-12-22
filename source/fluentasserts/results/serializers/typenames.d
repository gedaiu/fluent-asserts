/// Type name extraction and formatting functions.
module fluentasserts.results.serializers.typenames;

import std.array;
import std.traits;

/// Returns the unqualified type name for an array type.
/// Appends "[]" to the element type name.
string unqualString(T: U[], U)() pure @safe if(isArray!T && !isSomeString!T) {
  Appender!string result;
  result.put(unqualString!U);
  result.put("[]");
  return result[];
}

/// Returns the unqualified type name for an associative array type.
/// Formats as "ValueType[KeyType]".
string unqualString(T: V[K], V, K)() pure @safe if(isAssociativeArray!T) {
  Appender!string result;
  result.put(unqualString!V);
  result.put("[");
  result.put(unqualString!K);
  result.put("]");
  return result[];
}

/// Returns the unqualified type name for a non-array type.
/// Uses fully qualified names for classes, structs, and interfaces.
string unqualString(T)() pure @safe if(isScalarOrStringType!T) {
  static if(is(T == class) || is(T == struct) || is(T == interface)) {
    return fullyQualifiedName!(Unqual!(T));
  } else {
    return Unqual!T.stringof;
  }
}

/// Joins the type names of a class hierarchy.
/// Includes base classes and implemented interfaces.
string joinClassTypes(T)() pure @safe {
  Appender!string result;

  static if(is(T == class)) {
    static foreach(Type; BaseClassesTuple!T) {
      result.put(Type.stringof);
    }
  }

  static if(is(T == interface) || is(T == class)) {
    static foreach(Type; InterfacesTuple!T) {
      if(result[].length > 0) result.put(":");
      result.put(Type.stringof);
    }
  }

  static if(!is(T == interface) && !is(T == class)) {
    result.put(Unqual!T.stringof);
  }

  return result[];
}

// Helper template to check if a type is scalar or string
private template isScalarOrStringType(T) {
  import fluentasserts.core.evaluation.constraints : isScalarOrString;
  enum bool isScalarOrStringType = isScalarOrString!T;
}
