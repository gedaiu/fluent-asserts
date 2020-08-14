module fluentasserts.core.operations.registry;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import std.functional;
import std.string;

/// Delegate type that can handle asserts
alias Operation = IResult[] delegate(ref Evaluation) @safe nothrow;

///
class Registry {
  /// Global instance for the assert operations
  static Registry instance;

  private {
    Operation[string] operations;
  }

  /// Register a new assert operation
  Registry register(string valueType, string expectedValueType, string name, Operation operation) {
    string key = valueType ~ "." ~ expectedValueType ~ "." ~ name;

    operations[key] = operation;

    return this;
  }

  /// Register a new assert operation
  Registry register(string valueType, string expectedValueType, string name, IResult[] function(ref Evaluation) @safe nothrow operation) {
    return this.register(valueType, expectedValueType, name, operation.toDelegate);
  }

  /// Get an operation function
  Operation get(string valueType, string expectedValueType, string name) @safe nothrow {
    assert(valueType != "", "The value type is not set!");
    assert(name != "", "The operation name is not set!");

    string key = valueType ~ "." ~ expectedValueType ~ "." ~ name;

    if(key !in operations) {
      auto genericKey = generalizeKey(valueType, expectedValueType, name);

      assert(key in operations || genericKey in operations, "There is no `" ~ key ~ "` or `" ~ genericKey ~ "` registered to the assert operations.");

      key = genericKey;
    }

    return operations[key];
  }

  ///
  IResult[] handle(ref Evaluation evaluation) @safe nothrow {
    auto operation = this.get(
      evaluation.currentValue.typeName,
      evaluation.expectedValue.typeName,
      evaluation.operationName);

    return operation(evaluation);
  }
}

string generalizeKey(string valueType, string expectedValueType, string name) @safe nothrow {
  return generalizeType(valueType) ~ "." ~ generalizeType(expectedValueType) ~ "." ~ name;
}

string generalizeType(string typeName) @safe nothrow {
  auto pos = typeName.indexOf("[");
  if(pos == -1) {
    return "*";
  }

  return "*" ~ typeName[pos..$];
}