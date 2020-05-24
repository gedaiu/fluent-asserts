module fluentasserts.core.evaluation;

import core.time;
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