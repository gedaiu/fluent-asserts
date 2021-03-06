module fluentasserts.core.evaluation;

import std.datetime;
import std.typecons;
import std.traits;
import std.conv;
import std.range;
import std.array;
import std.algorithm : map;

import fluentasserts.core.serializers;
import fluentasserts.core.results;
import fluentasserts.core.base : TestException;

///
struct ValueEvaluation {
  /// The exception thrown during evaluation
  Throwable throwable;

  /// Time needed to evaluate the value
  Duration duration;

  /// Serialized value as string
  string strValue;

  /// Human readable value
  string niceValue;

  /// The name of the type before it was converted to string
  string[] typeNames;

  /// Other info about the value
  string[string] meta;

  string typeName() @safe nothrow {
    if(typeNames.length == 0) {
      return "unknown";
    }

    return typeNames[0];
  }
}

///
class Evaluation {
  /// The id of the current evaluation
  size_t id;

  /// The value that will be validated
  ValueEvaluation currentValue;

  /// The expected value that we will use to perform the comparison
  ValueEvaluation expectedValue;

  /// The operation name
  string operationName;

  /// True if the operation result needs to be negated to have a successful result
  bool isNegated;

  /// The nice message printed to the user
  MessageResult message;

  /// The source code where the assert is located
  SourceResult source;

  /// Results generated during evaluation
  IResult[] results;

  /// The throwable generated by the evaluation
  Throwable throwable;

  /// True when the evaluation is done
  bool isEvaluated;
}

///
auto evaluate(T)(lazy T testData) @trusted if(isInputRange!T && !isArray!T && !isAssociativeArray!T) {
  return evaluate(testData.array);
}

///
auto evaluate(T)(lazy T testData) @trusted if(!isInputRange!T || isArray!T || isAssociativeArray!T) {
  auto begin = Clock.currTime;
  alias Result = Tuple!(T, "value", ValueEvaluation, "evaluation");

  try {
    auto value = testData;
    alias TT = typeof(value);

    static if(isCallable!T) {
      if(value !is null) {
        begin = Clock.currTime;
        value();
      }
    }

    auto duration = Clock.currTime - begin;
    auto serializedValue = SerializerRegistry.instance.serialize(value);
    auto niceValue = SerializerRegistry.instance.niceValue(value);
    return Result(value, ValueEvaluation(null, duration, serializedValue, niceValue, extractTypes!TT ));
  } catch(Throwable t) {
    T result;

    static if(isCallable!T) {
      result = testData;
    }

    return Result(result, ValueEvaluation(t, Clock.currTime - begin, result.to!string, result.to!string, extractTypes!T ));
  }
}

/// evaluate a lazy value should capture an exception
unittest {
  int value() {
    throw new Exception("message");
  }

  auto result = evaluate(value);

  assert(result.evaluation.throwable !is null);
  assert(result.evaluation.throwable.msg == "message");
}

/// evaluate should capture an exception thrown by a callable
unittest {
  void value() {
    throw new Exception("message");
  }

  auto result = evaluate(&value);

  assert(result.evaluation.throwable !is null);
  assert(result.evaluation.throwable.msg == "message");
}

string[] extractTypes(T)() if((!isArray!T && !isAssociativeArray!T) || isSomeString!T) {
  string[] types;

  types ~= unqualString!T;

  static if(is(T == class)) {
    static foreach(Type; BaseClassesTuple!T) {
      types ~= unqualString!Type;
    }
  }

  static if(is(T == interface) || is(T == class)) {
    static foreach(Type; InterfacesTuple!T) {
      types ~= unqualString!Type;
    }
  }

  return types;
}

string[] extractTypes(T: U[], U)() if(isArray!T && !isSomeString!T) {
  return extractTypes!(U).map!(a => a ~ "[]").array;
}

string[] extractTypes(T: U[K], U, K)() {
  string k = unqualString!(K);
  return extractTypes!(U).map!(a => a ~ "[" ~ k ~ "]").array;
}

/// It can get the type of a string
unittest {
  auto result = extractTypes!string;
  assert(result == ["string"]);
}

/// It can get the type of a string list
unittest {
  auto result = extractTypes!(string[]);
  assert(result == ["string[]"]);
}

/// It can get the type of a string assoc array
unittest {
  auto result = extractTypes!(string[string]);
  assert(result == ["string[string]"]);
}

/// It can get all types of a class
unittest {
  interface I {}
  class T : I {}

  auto result = extractTypes!(T[]);

  assert(result[0] == "fluentasserts.core.evaluation.__unittest_L185_C1.T[]");
  assert(result[1] == "object.Object[]");
  assert(result[2] ==  "fluentasserts.core.evaluation.__unittest_L185_C1.I[]");
}