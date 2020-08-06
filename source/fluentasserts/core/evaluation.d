module fluentasserts.core.evaluation;

import std.datetime;
import std.typecons;
import std.traits;
import std.conv;
import std.range;
import std.array;
import fluentasserts.core.results;

///
struct ValueEvaluation {
  /// The exception thrown during evaluation
  Throwable throwable;

  /// Time needed to evaluate the value
  Duration duration;

  /// Serialized value as string
  string strValue;

  /// The name of the type before it was converted to string
  string typeName;

  /// Other info about the value
  string[string] meta;
}

///
struct Evaluation {
  /// The value that will be validated
  ValueEvaluation currentValue;

  /// The expected value that we will use to perform the comparison
  ValueEvaluation expectedValue;

  /// The operation name
  string operationName;

  /// True if the operation result needs to be negated to have a successful result
  bool isNegated;

  /// The name of the file where the assert was defined
  string fileName;

  /// The file line where the assert was defined
  size_t line;
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

    static if(isCallable!T) {
      if(value !is null) {
        begin = Clock.currTime;
        value();
      }
    }

    auto duration = Clock.currTime - begin;

    static if(isSomeString!(typeof(value))) {
      return Result(value, ValueEvaluation(null, duration, `"` ~ value.to!string ~ `"`, (Unqual!T).stringof));
    } else static if(isSomeChar!(typeof(value))) {
      return Result(value, ValueEvaluation(null, duration, `'` ~ value.to!string ~ `'`, (Unqual!T).stringof));
    } else {
      return Result(value, ValueEvaluation(null, duration, value.to!string, (Unqual!T).stringof));
    }
  } catch(Throwable t) {
    T result;

    static if(isCallable!T) {
      result = testData;
    }

    return Result(result, ValueEvaluation(t, Clock.currTime - begin, result.to!string, (Unqual!T).stringof));
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
