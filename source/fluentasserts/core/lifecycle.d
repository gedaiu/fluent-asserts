/// Lifecycle management for fluent-asserts.
/// Handles initialization of the assertion framework and manages
/// the assertion evaluation lifecycle.
module fluentasserts.core.lifecycle;

import fluentasserts.core.base;
import fluentasserts.core.evaluation;
import fluentasserts.core.operations.approximately;
import fluentasserts.core.operations.arrayEqual;
import fluentasserts.core.operations.beNull;
import fluentasserts.core.operations.between;
import fluentasserts.core.operations.contain;
import fluentasserts.core.operations.endWith;
import fluentasserts.core.operations.equal;
import fluentasserts.core.operations.greaterThan;
import fluentasserts.core.operations.greaterOrEqualTo;
import fluentasserts.core.operations.instanceOf;
import fluentasserts.core.operations.lessThan;
import fluentasserts.core.operations.lessOrEqualTo;
import fluentasserts.core.operations.registry;
import fluentasserts.core.operations.startWith;
import fluentasserts.core.operations.throwable;
import fluentasserts.core.results;
import fluentasserts.core.serializers;

import core.memory : GC;
import std.meta;
import std.conv;
import std.datetime;

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
  Registry.instance.register!(Duration, Duration)("above", &greaterThanDuration);
  Registry.instance.register!(SysTime, SysTime)("greaterThan", &greaterThanSysTime);
  Registry.instance.register!(SysTime, SysTime)("greaterOrEqualTo", &greaterOrEqualToSysTime);
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

/// Manages the assertion evaluation lifecycle.
/// Tracks assertion counts and handles the finalization of evaluations.
@safe class Lifecycle {
  /// Global singleton instance.
  static Lifecycle instance;

  private {
    /// Counter for total assertions executed.
    int totalAsserts;
  }

  /// Called when a new value evaluation begins.
  /// Increments the assertion counter and returns the current count.
  /// Params:
  ///   value = The value evaluation being started
  /// Returns: The current assertion number.
  int beginEvaluation(ValueEvaluation value) @safe nothrow {
    totalAsserts++;

    return totalAsserts;
  }

  /// Finalizes an evaluation and throws TestException on failure.
  /// Delegates to the Registry to handle the evaluation and throws
  /// if the result contains failure content.
  /// Does not throw if called from a GC finalizer.
  void endEvaluation(ref Evaluation evaluation) @trusted {
    if(evaluation.isEvaluated) return;

    evaluation.isEvaluated = true;
    Registry.instance.handle(evaluation);

    if(GC.inFinalizer) {
      return;
    }

    if(evaluation.currentValue.throwable !is null) {
      throw evaluation.currentValue.throwable;
    }

    if(evaluation.expectedValue.throwable !is null) {
      throw evaluation.currentValue.throwable;
    }

    if(!evaluation.result.hasContent()) {
      return;
    }

    string msg = evaluation.result.toString();
    msg ~= "\n" ~ evaluation.sourceFile ~ ":" ~ evaluation.sourceLine.to!string ~ "\n";

    throw new TestException(msg, evaluation.sourceFile, evaluation.sourceLine);
  }
}
