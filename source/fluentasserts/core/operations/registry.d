module fluentasserts.core.operations.registry;

import fluentasserts.core.results;
import fluentasserts.core.evaluation;

import std.functional;
import std.string;
import std.array;
import std.algorithm;

/// Delegate type that can handle asserts
alias Operation     = IResult[] delegate(ref Evaluation) @safe nothrow;

/// ditto
alias OperationFunc = IResult[] delegate(ref Evaluation) @safe nothrow;


struct OperationPair {
  string valueType;
  string expectedValueType;
}

///
class Registry {
  /// Global instance for the assert operations
  static Registry instance;

  private {
    Operation[string] operations;
    OperationPair[][string] pairs;
    string[string] descriptions;
  }

  /// Register a new assert operation
  Registry register(T, U)(string name, Operation operation) {
    foreach(valueType; extractTypes!T) {
      foreach(expectedValueType; extractTypes!U) {
        register(valueType, expectedValueType, name, operation);
      }
    }

    return this;
  }

  /// ditto
  Registry register(T, U)(string name, IResult[] function(ref Evaluation) @safe nothrow operation) {
    const operationDelegate = operation.toDelegate;
    return this.register!(T, U)(name, operationDelegate);
  }

  /// ditto
  Registry register(string valueType, string expectedValueType, string name, Operation operation) {
    string key = valueType ~ "." ~ expectedValueType ~ "." ~ name;

    operations[key] = operation;
    pairs[name] ~= OperationPair(valueType, expectedValueType);

    return this;
  }

  /// ditto
  Registry register(string valueType, string expectedValueType, string name, IResult[] function(ref Evaluation) @safe nothrow operation) {
    return this.register(valueType, expectedValueType, name, operation.toDelegate);
  }

  /// Get an operation function
  Operation get(string valueType, string expectedValueType, string name) @safe nothrow {
    assert(valueType != "", "The value type is not set!");
    assert(name != "", "The operation name is not set!");

    auto genericKeys = [valueType ~ "." ~ expectedValueType ~ "." ~ name] ~ generalizeKey(valueType, expectedValueType, name);
    string matchedKey;

    foreach(key; genericKeys) {
      if(key in operations) {
        matchedKey = key;
        break;
      }
    }

    assert(matchedKey != "", "There are no matching assert operations. Register any of `" ~ genericKeys.join("`, `") ~ "` to perform this assert.");

    return operations[matchedKey];
  }

  ///
  IResult[] handle(ref Evaluation evaluation) @safe nothrow {
    if(evaluation.operationName == "" || evaluation.operationName == "to" || evaluation.operationName == "should") {
      return [];
    }

    auto operation = this.get(
      evaluation.currentValue.typeName,
      evaluation.expectedValue.typeName,
      evaluation.operationName);

    return operation(evaluation);
  }

  ///
  void describe(string name, string text) {
    descriptions[name] = text;
  }

  ///
  string describe(string name) {
    if(name !in descriptions) {
      return "";
    }

    return descriptions[name];
  }

  ///
  OperationPair[] bindingsForName(string name) {
    if (name !in pairs) {
      return [];
    }
    return pairs[name];
  }

  ///
  string[] registeredOperations() {
    return operations.keys
      .map!(a => a.split("."))
      .map!(a => a[a.length - 1])
      .array
      .sort
      .uniq
      .array;
  }

  ///
  string docs() {
    string result = "";

    string[] operationNames = registeredOperations
      .map!(a => "- [" ~ a ~ "](api/" ~ a ~ ".md)")
      .array;

    return operationNames.join("\n");
  }
}

@("generates a list of md links for docs")
unittest {
  import std.datetime;
  import fluentasserts.core.operations.equal;
  import fluentasserts.core.operations.lessThan;

  auto instance = new Registry();

  instance.register("*", "*", "equal", &equal);
  instance.register!(Duration, Duration)("lessThan", &lessThanDuration);

  instance.docs.should.equal("- [equal](api/equal.md)\n" ~ "- [lessThan](api/lessThan.md)");
}

string[] generalizeKey(string valueType, string expectedValueType, string name) @safe nothrow {
  string[] results;

  foreach (string generalizedValueType; generalizeType(valueType)) {
    foreach (string generalizedExpectedValueType; generalizeType(expectedValueType)) {
      results ~=  generalizedValueType ~ "." ~ generalizedExpectedValueType ~ "." ~ name;
    }
  }

  return  results;
}

string[] generalizeType(string typeName) @safe nothrow {
  auto pos = typeName.indexOf("[");
  if(pos == -1) {
    return ["*"];
  }

  string[] results = [];

  const pieces = typeName.split("[");

  string arrayType;
  bool isHashMap;
  int index = 0;
  int diff = 0;

  foreach (ch; typeName[pos..$]) {
    diff++;
    if(ch == '[') {
      index++;
    }

    if(ch == ']') {
      index--;
    }

    if(index == 0 && diff == 2) {
      arrayType ~= "[]";
    }

    if(index == 0 && diff != 2) {
      arrayType ~= "[*]";
      isHashMap = true;
    }

    if(index == 0) {
      diff = 0;
    }
  }

  if(isHashMap) {
    results ~= "*" ~ typeName[pos..$];
    results ~= pieces[0] ~ arrayType;
  }

  results ~= "*" ~ arrayType;

  return results;
}

version(unittest) {
  import fluentasserts.core.base;
}

@("generalizeType returns [*] for int")
unittest {
  generalizeType("int").should.equal(["*"]);
}

@("generalizeType returns [*[]] for int[]")
unittest {
  generalizeType("int[]").should.equal(["*[]"]);
}

@("generalizeType returns [*[][]] for int[][]")
unittest {
  generalizeType("int[][]").should.equal(["*[][]"]);
}

@("generalizeType returns generalized forms for int[int]")
unittest {
  generalizeType("int[int]").should.equal(["*[int]", "int[*]", "*[*]"]);
}

@("generalizeType returns generalized forms for int[int][][string][]")
unittest {
  generalizeType("int[int][][string][]").should.equal(["*[int][][string][]", "int[*][][*][]", "*[*][][*][]"]);
}

@("generalizeType returns generalized forms for int[int[]]")
unittest {
  generalizeType("int[int[]]").should.equal(["*[int[]]", "int[*]", "*[*]"]);
}
