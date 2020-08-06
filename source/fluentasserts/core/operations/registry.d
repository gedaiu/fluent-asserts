module fluentasserts.core.operations.registry;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import std.functional;

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

    assert(key in operations, "There is no `" ~ key ~ "` registered to the assert operations.");

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
