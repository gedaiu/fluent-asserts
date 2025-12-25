module fluentasserts.operations.string.containmessages;

import std.algorithm;
import std.array;
import std.exception : assumeWontThrow;
import std.conv;

import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.core.evaluation.value : ValueEvaluation;
import fluentasserts.core.memory.heapequable : HeapEquableValue;
import fluentasserts.results.serializers.stringprocessing : cleanString;

@safe:

/// Adds a failure message to evaluation.result describing missing string values.
void addLifecycleMessage(ref Evaluation evaluation, string[] missingValues) nothrow {
  evaluation.result.addText(". ");

  if(missingValues.length == 1) {
    evaluation.result.addValue(missingValues[0]);
    evaluation.result.addText(" is missing from ");
  } else {
    evaluation.result.addValue(missingValues.niceJoin(evaluation.currentValue.typeName.idup));
    evaluation.result.addText(" are missing from ");
  }

  evaluation.result.addValue(evaluation.currentValue.strValue[]);
}

/// Adds a failure message to evaluation.result describing missing HeapEquableValue elements.
void addLifecycleMessage(ref Evaluation evaluation, HeapEquableValue[] missingValues) nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup.cleanString;
    }
  } catch (Exception) {
    return;
  }

  addLifecycleMessage(evaluation, missing);
}

/// Adds a negated failure message to evaluation.result describing unexpectedly present string values.
void addNegatedLifecycleMessage(ref Evaluation evaluation, string[] presentValues) nothrow {
  evaluation.result.addText(". ");

  if(presentValues.length == 1) {
    evaluation.result.addValue(presentValues[0]);
    evaluation.result.addText(" is present in ");
  } else {
    evaluation.result.addValue(presentValues.niceJoin(evaluation.currentValue.typeName.idup));
    evaluation.result.addText(" are present in ");
  }

  evaluation.result.addValue(evaluation.currentValue.strValue[]);
}

/// Adds a negated failure message to evaluation.result describing unexpectedly present HeapEquableValue elements.
void addNegatedLifecycleMessage(ref Evaluation evaluation, HeapEquableValue[] missingValues) nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup;
    }
  } catch (Exception) {
    return;
  }

  addNegatedLifecycleMessage(evaluation, missing);
}

string createResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) nothrow {
  string message = "to contain ";

  if(expectedPieces.length > 1) {
    message ~= "all ";
  }

  message ~= expectedValue.strValue[].idup;

  return message;
}

/// Creates an expected result message from HeapEquableValue array.
string createResultMessage(ValueEvaluation expectedValue, HeapEquableValue[] missingValues) nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup;
    }
  } catch (Exception) {
    return "";
  }

  return createResultMessage(expectedValue, missing);
}

string createNegatedResultMessage(ValueEvaluation expectedValue, string[] expectedPieces) nothrow {
  string message = "not to contain ";

  if(expectedPieces.length > 1) {
    message ~= "any ";
  }

  message ~= expectedValue.strValue[].idup;

  return message;
}

/// Creates a negated expected result message from HeapEquableValue array.
string createNegatedResultMessage(ValueEvaluation expectedValue, HeapEquableValue[] missingValues) nothrow {
  string[] missing;
  try {
    missing = new string[missingValues.length];
    foreach (i, ref val; missingValues) {
      missing[i] = val.getSerialized.idup;
    }
  } catch (Exception) {
    return "";
  }

  return createNegatedResultMessage(expectedValue, missing);
}

string niceJoin(string[] values, string typeName = "") @trusted nothrow {
  string result = values.to!string.assumeWontThrow;

  if(!typeName.canFind("string")) {
    result = result.replace(`"`, "");
  }

  return result;
}

string niceJoin(HeapEquableValue[] values, string typeName = "") @trusted nothrow {
  string[] strValues;
  try {
    strValues = new string[values.length];
    foreach (i, ref val; values) {
      strValues[i] = val.getSerialized.idup.cleanString;
    }
  } catch (Exception) {
    return "";
  }
  return strValues.niceJoin(typeName);
}
