/// Lifecycle management for fluent-asserts.
/// Handles initialization of the assertion framework and manages
/// the assertion evaluation lifecycle.
module fluentasserts.core.lifecycle;

import core.memory : GC;

import std.conv;
import std.datetime;
import std.meta;

import fluentasserts.core.base;
import fluentasserts.core.evaluation;

import fluentasserts.results.message;
import fluentasserts.results.serializers;

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
  SerializerRegistry.instance = new SerializerRegistry;
  Lifecycle.instance = new Lifecycle;

  ResultGlyphs.resetDefaults;

  Registry.instance = new Registry();

  Registry.instance.describe("approximately", approximatelyDescription);
  Registry.instance.describe("equal", equalDescription);
  Registry.instance.describe("beNull", beNullDescription);
  Registry.instance.describe("between", betweenDescription);
  Registry.instance.describe("within", betweenDescription);
  Registry.instance.describe("contain", containDescription);
  Registry.instance.describe("greaterThan", greaterThanDescription);
  Registry.instance.describe("above", greaterThanDescription);
  Registry.instance.describe("greaterOrEqualTo", greaterOrEqualToDescription);
  Registry.instance.describe("lessThan", lessThanDescription);

  // equal is now handled directly by Expect.equal, not through Registry
  Registry.instance.register("*[]", "*[]", "equal", &arrayEqual);
  Registry.instance.register("*[*]", "*[*]", "equal", &arrayEqual);
  Registry.instance.register("*[][]", "*[][]", "equal", &arrayEqual);

  Registry.instance.register("*", "*", "beNull", &beNull);
  Registry.instance.register("*", "*", "instanceOf", &instanceOf);

  Registry.instance.register("*", "*", "lessThan", &lessThanGeneric);
  Registry.instance.register("*", "*", "below", &lessThanGeneric);

  static foreach(Type; BasicNumericTypes) {
    Registry.instance.register(Type.stringof, Type.stringof, "greaterOrEqualTo", &greaterOrEqualTo!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "greaterThan", &greaterThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "above", &greaterThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "lessOrEqualTo", &lessOrEqualTo!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "lessThan", &lessThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "below", &lessThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "between", &between!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "within", &between!Type);
    Registry.instance.register(Type.stringof, "int", "lessOrEqualTo", &lessOrEqualTo!Type);
    Registry.instance.register(Type.stringof, "int", "lessThan", &lessThan!Type);
    Registry.instance.register(Type.stringof, "int", "greaterOrEqualTo", &greaterOrEqualTo!Type);
    Registry.instance.register(Type.stringof, "int", "greaterThan", &greaterThan!Type);
  }

  static foreach(Type1; NumericTypes) {
    Registry.instance.register(Type1.stringof ~ "[]", "void[]", "approximately", &approximatelyList);
    static foreach(Type2; NumericTypes) {
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "approximately", &approximatelyList);
      Registry.instance.register(Type1.stringof, Type2.stringof, "approximately", &approximately);
    }
  }

  Registry.instance.register("*[]", "*", "contain", &arrayContain);
  Registry.instance.register("*[]", "*[]", "contain", &arrayContain);
  Registry.instance.register("*[]", "*[]", "containOnly", &arrayContainOnly);
  Registry.instance.register("*[][]", "*[][]", "containOnly", &arrayContainOnly);

  static foreach(Type1; StringTypes) {
    static foreach(Type2; StringTypes) {
      Registry.instance.register(Type1.stringof, Type2.stringof ~ "[]", "contain", &contain);
      Registry.instance.register(Type1.stringof, Type2.stringof, "contain", &contain);
      Registry.instance.register(Type1.stringof, Type2.stringof, "startWith", &startWith);
      Registry.instance.register(Type1.stringof, Type2.stringof, "endWith", &endWith);
    }
    Registry.instance.register(Type1.stringof, "char", "contain", &contain);
    Registry.instance.register(Type1.stringof, "char", "startWith", &startWith);
    Registry.instance.register(Type1.stringof, "char", "endWith", &endWith);
  }

  Registry.instance.register!(Duration, Duration)("lessThan", &lessThanDuration);
  Registry.instance.register!(Duration, Duration)("below", &lessThanDuration);
  Registry.instance.register!(SysTime, SysTime)("lessThan", &lessThanSysTime);
  Registry.instance.register!(SysTime, SysTime)("below", &lessThanSysTime);
  Registry.instance.register!(Duration, Duration)("greaterThan", &greaterThanDuration);
  Registry.instance.register!(Duration, Duration)("greaterOrEqualTo", &greaterOrEqualToDuration);
  Registry.instance.register!(Duration, Duration)("lessOrEqualTo", &lessOrEqualToDuration);
  Registry.instance.register!(Duration, Duration)("above", &greaterThanDuration);
  Registry.instance.register!(SysTime, SysTime)("greaterThan", &greaterThanSysTime);
  Registry.instance.register!(SysTime, SysTime)("greaterOrEqualTo", &greaterOrEqualToSysTime);
  Registry.instance.register!(SysTime, SysTime)("lessOrEqualTo", &lessOrEqualToSysTime);
  Registry.instance.register!(SysTime, SysTime)("above", &greaterThanSysTime);
  Registry.instance.register!(Duration, Duration)("between", &betweenDuration);
  Registry.instance.register!(Duration, Duration)("within", &betweenDuration);
  Registry.instance.register!(SysTime, SysTime)("between", &betweenSysTime);
  Registry.instance.register!(SysTime, SysTime)("within", &betweenSysTime);

  Registry.instance.register("callable", "", "throwAnyException", &throwAnyException);
  Registry.instance.register("callable", "", "throwException", &throwException);
  Registry.instance.register("*", "*", "throwAnyException", &throwAnyException);
  Registry.instance.register("*", "*", "throwAnyException.withMessage", &throwAnyExceptionWithMessage);
  Registry.instance.register("*", "*", "throwAnyException.withMessage.equal", &throwAnyExceptionWithMessage);
  Registry.instance.register("*", "*", "throwException", &throwException);
  Registry.instance.register("*", "*", "throwException.withMessage", &throwExceptionWithMessage);
  Registry.instance.register("*", "*", "throwException.withMessage.equal", &throwExceptionWithMessage);
  Registry.instance.register("*", "*", "throwSomething", &throwAnyException);
  Registry.instance.register("*", "*", "throwSomething.withMessage", &throwAnyExceptionWithMessage);
  Registry.instance.register("*", "*", "throwSomething.withMessage.equal", &throwAnyExceptionWithMessage);
}

/// Delegate type for custom failure handlers.
/// Receives the evaluation that failed and can handle it as needed.
alias FailureHandlerDelegate = void delegate(ref Evaluation evaluation) @safe;

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
Evaluation recordEvaluation(void delegate() assertion) {
  Lifecycle.instance.keepLastEvaluation = true;
  Lifecycle.instance.disableFailureHandling = true;
  scope(exit) {
    Lifecycle.instance.keepLastEvaluation = false;
    Lifecycle.instance.disableFailureHandling = false;
  }

  assertion();

  return Lifecycle.instance.lastEvaluation;
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


  private {
    /// Counter for total assertions executed.
    int totalAsserts;
  }

  /// Called when a new value evaluation begins.
  /// Increments the assertion counter and returns the current count.
  /// Params:
  ///   value = The value evaluation being started
  /// Returns: The current assertion number.
  int beginEvaluation(ValueEvaluation value) nothrow {
    totalAsserts++;

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

    string msg = evaluation.result.toString();
    msg ~= "\n" ~ evaluation.sourceFile ~ ":" ~ evaluation.sourceLine.to!string ~ "\n";

    throw new TestException(msg, evaluation.sourceFile, evaluation.sourceLine);
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

    if(keepLastEvaluation) {
      lastEvaluation = evaluation;
    }

    evaluation.isEvaluated = true;

    if(GC.inFinalizer) {
      return;
    }

    Registry.instance.handle(evaluation);

    if(evaluation.currentValue.throwable !is null || evaluation.expectedValue.throwable !is null) {
      this.handleFailure(evaluation);
      return;
    }

    if(!evaluation.result.hasContent()) {
      return;
    }

    this.handleFailure(evaluation);
  }
}
