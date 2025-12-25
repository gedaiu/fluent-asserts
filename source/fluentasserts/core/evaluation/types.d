/// Type extraction utilities for fluent-asserts.
/// Provides functions to extract type names including base classes and interfaces.
module fluentasserts.core.evaluation.types;

import std.traits;
import fluentasserts.core.memory.typenamelist;
import fluentasserts.results.serializers.typenames : unqualString;
import fluentasserts.core.evaluation.constraints;

/// Extracts the type names for a non-array, non-associative-array type.
/// For classes, includes base classes and implemented interfaces.
/// Params:
///   T = The type to extract names from
/// Returns: A TypeNameList of fully qualified type names.
TypeNameList extractTypes(T)() if(isScalarOrString!T) {
  TypeNameList types;

  types.put(unqualString!T);

  static if(is(T == class)) {
    static foreach(Type; BaseClassesTuple!T) {
      types.put(unqualString!Type);
    }
  }

  static if(is(T == interface) || is(T == class)) {
    static foreach(Type; InterfacesTuple!T) {
      types.put(unqualString!Type);
    }
  }

  return types;
}

/// Extracts the type names for void[].
TypeNameList extractTypes(T)() if(is(T == void[])) {
  TypeNameList types;
  types.put("void[]");
  return types;
}

/// Extracts the type names for an array type.
/// Appends "[]" to each element type name.
/// Params:
///   T = The array type
///   U = The element type
/// Returns: A TypeNameList of type names with "[]" suffix.
TypeNameList extractTypes(T: U[], U)() if(isRegularArray!T) {
  auto elementTypes = extractTypes!(U);
  TypeNameList types;

  foreach (i; 0 .. elementTypes.length) {
    auto name = elementTypes[i][] ~ "[]";
    types.put(name);
  }

  return types;
}

/// Extracts the type names for an associative array type.
/// Formats as "ValueType[KeyType]".
/// Params:
///   T = The associative array type
///   U = The value type
///   K = The key type
/// Returns: A TypeNameList of type names in associative array format.
TypeNameList extractTypes(T: U[K], U, K)() {
  string k = unqualString!(K);
  auto valueTypes = extractTypes!(U);
  TypeNameList types;

  foreach (i; 0 .. valueTypes.length) {
    auto name = valueTypes[i][] ~ "[" ~ k ~ "]";
    types.put(name);
  }

  return types;
}

version(unittest) {
  import fluentasserts.core.lifecycle;

  interface ExtractTypesTestInterface {}
  class ExtractTypesTestClass : ExtractTypesTestInterface {}
}

@("extractTypes returns [string] for string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = extractTypes!string;
  assert(result.length == 1, "Expected length 1");
  assert(result[0][] == "string", "Expected \"string\"");
}

@("extractTypes returns [string[]] for string[]")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = extractTypes!(string[]);
  assert(result.length == 1, "Expected length 1");
  assert(result[0][] == "string[]", "Expected \"string[]\"");
}

@("extractTypes returns [string[string]] for string[string]")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = extractTypes!(string[string]);
  assert(result.length == 1, "Expected length 1");
  assert(result[0][] == "string[string]", "Expected \"string[string]\"");
}

@("extractTypes returns all types of a class")
unittest {
  Lifecycle.instance.disableFailureHandling = false;

  auto result = extractTypes!(ExtractTypesTestClass[]);

  assert(result[0][] == "fluentasserts.core.evaluation.types.ExtractTypesTestClass[]", `Expected: "fluentasserts.core.evaluation.types.ExtractTypesTestClass[]"`);
  assert(result[1][] == "object.Object[]", `Expected: "object.Object[]"`);
  assert(result[2][] == "fluentasserts.core.evaluation.types.ExtractTypesTestInterface[]", `Expected: "fluentasserts.core.evaluation.types.ExtractTypesTestInterface[]"`);
}
