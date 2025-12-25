/// Lifecycle management for fluent-asserts.
/// Handles initialization of the assertion framework and manages
/// the assertion evaluation lifecycle.
module fluentasserts.core.lifecycle;

import core.memory : GC;

import std.conv;
import std.datetime;
import std.meta;

import fluentasserts.core.base;
import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.core.evaluation.value : ValueEvaluation;

import fluentasserts.results.message;
import fluentasserts.results.serializers.heap_registry : HeapSerializerRegistry;

import fluentasserts.operations.registry;
import fluentasserts.operations.comparison.approximately;
import fluentasserts.operations.comparison.between;
import fluentasserts.operations.comparison.greaterOrEqualTo;
import fluentasserts.operations.comparison.greaterThan;
import fluentasserts.operations.comparison.lessOrEqualTo;
import fluentasserts.operations.comparison.lessThan;
import fluentasserts.operations.equality.arrayEqual;
import fluentasserts.operations.equality.equal;
import fluentasserts.operations.exception.throwable;
import fluentasserts.operations.string.contain;
import fluentasserts.operations.string.endWith;
import fluentasserts.operations.string.startWith;
import fluentasserts.operations.type.beNull;
import fluentasserts.operations.type.instanceOf;

/// Tuple of basic numeric types supported by fluent-asserts.
alias BasicNumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

/// Tuple of all numeric types for operation registration.
alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

/// Tuple of string types supported by fluent-asserts.
alias StringTypes = AliasSeq!(string, wstring, dstring, const(char)[]);

/// Module constructor that initializes all fluent-asserts components.
/// Registers all built-in operations, serializers, and sets up the lifecycle.
static this() {
  HeapSerializerRegistry.instance = new HeapSerializerRegistry;
  Lifecycle.instance = new Lifecycle;

  ResultGlyphs.resetDefaults;

  Registry.instance = new Registry();
}

/// Delegate type for custom failure handlers.
/// Receives the evaluation that failed and can handle it as needed.
alias FailureHandlerDelegate = void delegate(ref Evaluation evaluation) @safe;

/// Issue #92: Statistics for assertion execution.
/// Tracks counts of assertions executed, passed, and failed.
/// Useful for monitoring assertion behavior in long-running or multi-threaded programs.
struct AssertionStatistics {
  /// Total number of assertions executed.
  int totalAssertions;

  /// Number of assertions that passed.
  int passedAssertions;

  /// Number of assertions that failed.
  int failedAssertions;

  /// Resets all statistics to zero.
  void reset() @safe @nogc nothrow {
    totalAssertions = 0;
    passedAssertions = 0;
    failedAssertions = 0;
  }
}

/// String mixin for unit tests that need to capture evaluation results.
/// Enables keepLastEvaluation and disableFailureHandling, then restores
/// them in scope(exit).
enum enableEvaluationRecording = q{
  Lifecycle.instance.keepLastEvaluation = true;
  Lifecycle.instance.disableFailureHandling = true;
  scope(exit) {
    Lifecycle.instance.keepLastEvaluation = false;
    Lifecycle.instance.disableFailureHandling = false;
  }
};

/// Executes an assertion and captures its evaluation result.
/// Use this to test assertion behavior without throwing on failure.
/// Thread-safe: saves and restores state on the existing Lifecycle instance.
Evaluation recordEvaluation(void delegate() assertion) @trusted {
  if (Lifecycle.instance is null) {
    Lifecycle.instance = new Lifecycle();
  }

  auto instance = Lifecycle.instance;
  auto previousKeepLastEvaluation = instance.keepLastEvaluation;
  auto previousDisableFailureHandling = instance.disableFailureHandling;

  instance.keepLastEvaluation = true;
  instance.disableFailureHandling = true;

  scope(exit) {
    instance.keepLastEvaluation = previousKeepLastEvaluation;
    instance.disableFailureHandling = previousDisableFailureHandling;
  }

  assertion();

  import std.algorithm : move;
  return move(instance.lastEvaluation);
}

/// Manages the assertion evaluation lifecycle.
/// Tracks assertion counts and handles the finalization of evaluations.
@safe class Lifecycle {
  /// Global singleton instance.
  static Lifecycle instance;

  /// Custom failure handler delegate. When set, this is called instead of
  /// defaultFailureHandler when an assertion fails.
  FailureHandlerDelegate failureHandler;

  /// When true, stores the most recent evaluation in lastEvaluation.
  /// Used by recordEvaluation to capture assertion results.
  bool keepLastEvaluation;

  /// Stores the most recent evaluation when keepLastEvaluation is true.
  /// Access this after running an assertion to inspect its result.
  Evaluation lastEvaluation;

  /// When true, assertion failures are silently ignored instead of throwing.
  /// Used by recordEvaluation to prevent test abortion during evaluation capture.
  bool disableFailureHandling;

  /// Issue #92: Statistics for assertion execution.
  /// Access via Lifecycle.instance.statistics.
  AssertionStatistics statistics;

  private {
    /// Counter for total assertions executed (kept for backward compatibility).
    int totalAsserts;
  }

  /// Called when a new value evaluation begins.
  /// Increments the assertion counter and returns the current count.
  /// Params:
  ///   value = The value evaluation being started
  /// Returns: The current assertion number.
  int beginEvaluation(ValueEvaluation value) nothrow @nogc {
    totalAsserts++;
    statistics.totalAssertions++;

    return totalAsserts;
  }

  /// Default handler for assertion failures.
  /// Throws any captured throwable from value evaluation, or constructs
  /// a TestException with the formatted failure message.
  /// Params:
  ///   evaluation = The evaluation containing the failure details
  /// Throws: TestException or the original throwable from evaluation
  void defaultFailureHandler(ref Evaluation evaluation) {
    if(evaluation.currentValue.throwable !is null) {
      throw evaluation.currentValue.throwable;
    }

    if(evaluation.expectedValue.throwable !is null) {
      throw evaluation.expectedValue.throwable;
    }

    throw new TestException(evaluation);
  }

  /// Processes an assertion failure by delegating to the appropriate handler.
  /// If disableFailureHandling is true, does nothing.
  /// If a custom failureHandler is set, calls it.
  /// Otherwise, calls defaultFailureHandler.
  /// Params:
  ///   evaluation = The evaluation containing the failure details
  void handleFailure(ref Evaluation evaluation) {
    if(this.disableFailureHandling) {
      return;
    }

    if(this.failureHandler !is null) {
      this.failureHandler(evaluation);
      return;
    }

    this.defaultFailureHandler(evaluation);
  }

  /// Finalizes an evaluation and throws TestException on failure.
  /// Delegates to the Registry to handle the evaluation and throws
  /// if the result contains failure content.
  /// Does not throw if called from a GC finalizer.
  void endEvaluation(ref Evaluation evaluation) {
    if(evaluation.isEvaluated) {
      return;
    }

    evaluation.isEvaluated = true;

    if(GC.inFinalizer) {
      return;
    }

    Registry.instance.handle(evaluation);

    if(keepLastEvaluation) {
      lastEvaluation = evaluation;
    }

    if(evaluation.currentValue.throwable !is null || evaluation.expectedValue.throwable !is null) {
      statistics.failedAssertions++;
      this.handleFailure(evaluation);
      return;
    }

    if(!evaluation.result.hasContent()) {
      statistics.passedAssertions++;
      return;
    }

    statistics.failedAssertions++;
    this.handleFailure(evaluation);
  }

  /// Resets all statistics to zero.
  /// Useful for starting fresh counts in a new test phase.
  void resetStatistics() @nogc nothrow {
    statistics.reset();
  }
}

// Issue #92: Tests for AssertionStatistics
version (unittest) {
  import fluent.asserts;
}

// Issue #92: AssertionStatistics tracks passed assertions
@("statistics tracks passed assertions")
unittest {
  auto savedStats = Lifecycle.instance.statistics;
  scope(exit) Lifecycle.instance.statistics = savedStats;

  Lifecycle.instance.resetStatistics();
  auto initialPassed = Lifecycle.instance.statistics.passedAssertions;
  auto initialTotal = Lifecycle.instance.statistics.totalAssertions;

  expect(1).to.equal(1);

  assert(Lifecycle.instance.statistics.totalAssertions == initialTotal + 1,
    "totalAssertions should increment");
  assert(Lifecycle.instance.statistics.passedAssertions == initialPassed + 1,
    "passedAssertions should increment for passing assertion");
}

// Issue #92: AssertionStatistics tracks failed assertions
@("statistics tracks failed assertions")
unittest {
  auto savedStats = Lifecycle.instance.statistics;
  auto savedDisable = Lifecycle.instance.disableFailureHandling;
  scope(exit) {
    Lifecycle.instance.statistics = savedStats;
    Lifecycle.instance.disableFailureHandling = savedDisable;
  }

  Lifecycle.instance.resetStatistics();
  Lifecycle.instance.disableFailureHandling = true;

  auto initialFailed = Lifecycle.instance.statistics.failedAssertions;
  auto initialTotal = Lifecycle.instance.statistics.totalAssertions;

  expect(1).to.equal(2);

  assert(Lifecycle.instance.statistics.totalAssertions == initialTotal + 1,
    "totalAssertions should increment");
  assert(Lifecycle.instance.statistics.failedAssertions == initialFailed + 1,
    "failedAssertions should increment for failing assertion");
}

// Issue #92: AssertionStatistics.reset clears all counters
@("statistics reset clears all counters")
unittest {
  auto savedStats = Lifecycle.instance.statistics;
  scope(exit) Lifecycle.instance.statistics = savedStats;

  Lifecycle.instance.statistics.totalAssertions = 10;
  Lifecycle.instance.statistics.passedAssertions = 8;
  Lifecycle.instance.statistics.failedAssertions = 2;

  Lifecycle.instance.resetStatistics();

  assert(Lifecycle.instance.statistics.totalAssertions == 0);
  assert(Lifecycle.instance.statistics.passedAssertions == 0);
  assert(Lifecycle.instance.statistics.failedAssertions == 0);
}
