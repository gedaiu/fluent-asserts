/// Formatting utilities for fluent-asserts.
/// Provides helper functions for converting operation names to readable strings.
module fluentasserts.results.formatting;

import std.uni : toLower, isUpper, isLower;

version (unittest) {
  import fluentasserts.core.lifecycle;
}

@safe:

/// Converts an operation name to a nice, human-readable string.
/// Replaces dots with spaces and adds spaces before uppercase letters.
/// Params:
///   value = The operation name (e.g., "throwException.withMessage")
/// Returns: A readable string (e.g., "throw exception with message")
string toNiceOperation(string value) @safe nothrow {
  string newValue;

  foreach (index, ch; value) {
    if (index == 0) {
      newValue ~= ch.toLower;
      continue;
    }

    if (ch == '.') {
      newValue ~= ' ';
      continue;
    }

    if (ch.isUpper && value[index - 1].isLower) {
      newValue ~= ' ';
      newValue ~= ch.toLower;
      continue;
    }

    newValue ~= ch;
  }

  return newValue;
}

version (unittest) {
  import fluentasserts.core.expect;
}

@("toNiceOperation converts empty string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect("".toNiceOperation).to.equal("");
}

@("toNiceOperation converts dots to spaces")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect("a.b".toNiceOperation).to.equal("a b");
}

@("toNiceOperation converts camelCase to spaced words")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect("aB".toNiceOperation).to.equal("a b");
}

@("toNiceOperation converts complex operation names")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  expect("throwException".toNiceOperation).to.equal("throw exception");
  expect("throwException.withMessage".toNiceOperation).to.equal("throw exception with message");
}
