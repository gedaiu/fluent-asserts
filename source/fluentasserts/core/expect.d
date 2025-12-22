/// Main fluent API for assertions.
/// Provides the Expect struct and expect() factory functions.
module fluentasserts.core.expect;

import fluentasserts.core.lifecycle;
import fluentasserts.core.evaluation.eval : Evaluation, evaluate, evaluateObject;
import fluentasserts.core.evaluation.value : ValueEvaluation;
import fluentasserts.core.evaluator;
import fluentasserts.core.memory.heapstring : toHeapString;

import fluentasserts.results.printer;
import fluentasserts.results.formatting : toNiceOperation;
import fluentasserts.results.serializers.string_registry;
import fluentasserts.results.serializers.heap_registry : HeapSerializerRegistry;

import fluentasserts.operations.equality.equal : equalOp = equal;
import fluentasserts.operations.equality.arrayEqual : arrayEqualOp = arrayEqual;
import fluentasserts.operations.string.contain : containOp = contain, arrayContainOp = arrayContain, arrayContainOnlyOp = arrayContainOnly;
import fluentasserts.operations.string.startWith : startWithOp = startWith;
import fluentasserts.operations.string.endWith : endWithOp = endWith;
import fluentasserts.operations.type.beNull : beNullOp = beNull;
import fluentasserts.operations.type.instanceOf : instanceOfOp = instanceOf;
import fluentasserts.operations.comparison.greaterThan : greaterThanOp = greaterThan, greaterThanDurationOp = greaterThanDuration, greaterThanSysTimeOp = greaterThanSysTime;
import fluentasserts.operations.comparison.greaterOrEqualTo : greaterOrEqualToOp = greaterOrEqualTo, greaterOrEqualToDurationOp = greaterOrEqualToDuration, greaterOrEqualToSysTimeOp = greaterOrEqualToSysTime;
import fluentasserts.operations.comparison.lessThan : lessThanOp = lessThan, lessThanDurationOp = lessThanDuration, lessThanSysTimeOp = lessThanSysTime, lessThanGenericOp = lessThanGeneric;
import fluentasserts.operations.comparison.lessOrEqualTo : lessOrEqualToOp = lessOrEqualTo, lessOrEqualToDurationOp = lessOrEqualToDuration, lessOrEqualToSysTimeOp = lessOrEqualToSysTime;
import fluentasserts.operations.comparison.between : betweenOp = between, betweenDurationOp = betweenDuration, betweenSysTimeOp = betweenSysTime;
import fluentasserts.operations.comparison.approximately : approximatelyOp = approximately, approximatelyListOp = approximatelyList;
import fluentasserts.operations.exception.throwable : throwAnyExceptionOp = throwAnyException, throwExceptionOp = throwException, throwAnyExceptionWithMessageOp = throwAnyExceptionWithMessage, throwExceptionWithMessageOp = throwExceptionWithMessage, throwSomethingOp = throwSomething, throwSomethingWithMessageOp = throwSomethingWithMessage;
import fluentasserts.operations.memory.gcMemory : allocateGCMemoryOp = allocateGCMemory;
import fluentasserts.operations.memory.nonGcMemory : allocateNonGCMemoryOp = allocateNonGCMemory;

import std.datetime : Duration, SysTime;

import std.traits;
import std.string;
import std.uni;
import std.conv;

/// The main fluent assertion struct.
/// Provides a chainable API for building assertions with modifiers like
/// `not`, `be`, and `to`, and terminal operations like `equal`, `contain`, etc.
@safe struct Expect {

  private {
    Evaluation _evaluation;
    int refCount;
  }

  /// Returns a reference to the underlying evaluation.
  /// Allows external extensions via UFCS.
  ref Evaluation evaluation() return nothrow @nogc {
    return _evaluation;
  }

  /// Constructs an Expect from a ValueEvaluation.
  /// Initializes the evaluation state and sets up the initial message.
  this(ValueEvaluation value) @trusted {
    _evaluation.id = Lifecycle.instance.beginEvaluation(value);
    _evaluation.currentValue = value;
    _evaluation.source = SourceResult.create(value.fileName[].idup, value.line);

    try {
      auto sourceValue = _evaluation.source.getValue;

      if (sourceValue == "") {
        _evaluation.result.startWith(_evaluation.currentValue.niceValue[].idup);
      } else {
        _evaluation.result.startWith(sourceValue);
      }
    } catch (Exception) {
      _evaluation.result.startWith(_evaluation.currentValue.strValue[].idup);
    }

    _evaluation.result.addText(" should");

    if (value.prependText.length > 0) {
      _evaluation.result.addText(value.prependText[].idup);
    }
  }

  /// Disable postblit to allow copy constructor to work
  @disable this(this);

  /// Copy constructor - properly handles Evaluation with HeapString fields.
  /// Increments the source's refCount so only the last copy triggers finalization.
  this(ref return scope Expect another) @trusted nothrow {
    this._evaluation = another._evaluation;
    this.refCount = 0;  // New copy starts with 0
    another.refCount++;  // Prevent source from finalizing
  }

  /// Destructor. Finalizes the evaluation when reference count reaches zero.
  ~this() {
    refCount--;

    if(refCount < 0) {
      _evaluation.result.addText(" ");
      _evaluation.result.addText(_evaluation.operationName.toNiceOperation);

      if(!_evaluation.expectedValue.niceValue.empty) {
        _evaluation.result.addText(" ");
        _evaluation.result.addValue(_evaluation.expectedValue.niceValue[]);
      } else if(!_evaluation.expectedValue.strValue.empty) {
        _evaluation.result.addText(" ");
        _evaluation.result.addValue(_evaluation.expectedValue.strValue[]);
      }

      Lifecycle.instance.endEvaluation(_evaluation);
    }
  }

  /// Finalizes the assertion message before creating an Evaluator.
  /// Used by external extensions to complete message formatting.
  void finalizeMessage() {
    _evaluation.result.addText(" ");
    _evaluation.result.addText(_evaluation.operationName.toNiceOperation);

    if(!_evaluation.expectedValue.niceValue.empty) {
      _evaluation.result.addText(" ");
      _evaluation.result.addValue(_evaluation.expectedValue.niceValue[]);
    } else if(!_evaluation.expectedValue.strValue.empty) {
      _evaluation.result.addText(" ");
      _evaluation.result.addValue(_evaluation.expectedValue.strValue[]);
    }
  }

  /// Returns the message from the thrown exception.
  /// Throws if no exception was thrown.
  string msg(const size_t line = __LINE__, const string file = __FILE__) @trusted {
    if(this.thrown is null) {
      throw new Exception("There were no thrown exceptions", file, line);
    }

    return this.thrown.message.to!string;
  }

  /// Chains with message expectation (no argument version).
  ref Expect withMessage(const size_t line = __LINE__, const string file = __FILE__) return {
    addOperationName("withMessage");
    return this;
  }

  /// Chains with message expectation for a specific message.
  ref Expect withMessage(string message, const size_t line = __LINE__, const string file = __FILE__) return {
    return opDispatch!"withMessage"(message);
  }

  /// Returns the throwable captured during evaluation.
  Throwable thrown() {
    Lifecycle.instance.endEvaluation(_evaluation);
    return _evaluation.throwable;
  }

  /// Syntactic sugar - returns self for chaining.
  ref Expect to() return nothrow @nogc {
    return this;
  }

  /// Adds "be" to the assertion message for readability.
  ref Expect be() return {
    _evaluation.result.addText(" be");
    return this;
  }

  /// Negates the assertion condition.
  ref Expect not() return {
    _evaluation.isNegated = !_evaluation.isNegated;
    _evaluation.result.addText(" not");

    return this;
  }

  /// Asserts that the callable throws any exception.
  ThrowableEvaluator throwAnyException() @trusted {
    addOperationName("throwAnyException");
    finalizeMessage();
    inhibit();
    return ThrowableEvaluator(_evaluation, &throwAnyExceptionOp, &throwAnyExceptionWithMessageOp);
  }

  /// Asserts that the callable throws something (exception or error).
  ThrowableEvaluator throwSomething() @trusted {
    addOperationName("throwSomething");
    finalizeMessage();
    inhibit();
    return ThrowableEvaluator(_evaluation, &throwSomethingOp, &throwSomethingWithMessageOp);
  }

  /// Asserts that the callable throws a specific exception type.
  ThrowableEvaluator throwException(Type)() @trusted {
    import fluentasserts.core.memory.heapstring : toHeapString;
    this._evaluation.expectedValue.meta["exceptionType"] = fullyQualifiedName!Type;
    this._evaluation.expectedValue.meta["throwableType"] = fullyQualifiedName!Type;
    this._evaluation.expectedValue.strValue = toHeapString("\"" ~ fullyQualifiedName!Type ~ "\"");

    addOperationName("throwException");
    _evaluation.result.addText(" throw exception ");
    _evaluation.result.addValue(_evaluation.expectedValue.strValue[]);
    inhibit();
    return ThrowableEvaluator(_evaluation, &throwExceptionOp, &throwExceptionWithMessageOp);
  }

  /// Adds a reason to the assertion message.
  /// The reason is prepended: "Because <reason>, ..."
  ref Expect because(string reason) return {
    _evaluation.result.prependText("Because " ~ reason ~ ", ");
    return this;
  }

  /// Asserts that the actual value equals the expected value.
  Evaluator equal(T)(T value) {
    import std.algorithm : endsWith;

    addOperationName("equal");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    if (_evaluation.currentValue.typeName.endsWith("[]") || _evaluation.currentValue.typeName.endsWith("]")) {
      return Evaluator(_evaluation, &arrayEqualOp);
    } else {
      return Evaluator(_evaluation, &equalOp);
    }
  }

  /// Asserts that the actual value contains the expected value.
  TrustedEvaluator contain(T)(T value) {
    import std.algorithm : endsWith;

    addOperationName("contain");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    if (_evaluation.currentValue.typeName.endsWith("[]")) {
      return TrustedEvaluator(_evaluation, &arrayContainOp);
    } else {
      return TrustedEvaluator(_evaluation, &containOp);
    }
  }

  /// Asserts that the actual value is greater than the expected value.
  Evaluator greaterThan(T)(T value) {
    addOperationName("greaterThan");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &greaterThanDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &greaterThanSysTimeOp);
    } else {
      return Evaluator(_evaluation, &greaterThanOp!T);
    }
  }

  /// Asserts that the actual value is greater than or equal to the expected value.
  Evaluator greaterOrEqualTo(T)(T value) {
    addOperationName("greaterOrEqualTo");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &greaterOrEqualToDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &greaterOrEqualToSysTimeOp);
    } else {
      return Evaluator(_evaluation, &greaterOrEqualToOp!T);
    }
  }

  /// Asserts that the actual value is above (greater than) the expected value.
  Evaluator above(T)(T value) {
    addOperationName("above");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &greaterThanDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &greaterThanSysTimeOp);
    } else {
      return Evaluator(_evaluation, &greaterThanOp!T);
    }
  }

  /// Asserts that the actual value is less than the expected value.
  Evaluator lessThan(T)(T value) {
    addOperationName("lessThan");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &lessThanDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &lessThanSysTimeOp);
    } else static if (isNumeric!T) {
      return Evaluator(_evaluation, &lessThanOp!T);
    } else {
      return Evaluator(_evaluation, &lessThanGenericOp);
    }
  }

  /// Asserts that the actual value is less than or equal to the expected value.
  Evaluator lessOrEqualTo(T)(T value) {
    addOperationName("lessOrEqualTo");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &lessOrEqualToDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &lessOrEqualToSysTimeOp);
    } else {
      return Evaluator(_evaluation, &lessOrEqualToOp!T);
    }
  }

  /// Asserts that the actual value is below (less than) the expected value.
  Evaluator below(T)(T value) {
    addOperationName("below");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &lessThanDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &lessThanSysTimeOp);
    } else static if (isNumeric!T) {
      return Evaluator(_evaluation, &lessThanOp!T);
    } else {
      return Evaluator(_evaluation, &lessThanGenericOp);
    }
  }

  /// Asserts that the string starts with the expected prefix.
  Evaluator startWith(T)(T value) {
    addOperationName("startWith");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &startWithOp);
  }

  /// Asserts that the string ends with the expected suffix.
  Evaluator endWith(T)(T value) {
    addOperationName("endWith");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &endWithOp);
  }

  /// Asserts that the collection contains only the expected elements.
  Evaluator containOnly(T)(T value) {
    addOperationName("containOnly");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &arrayContainOnlyOp);
  }

  /// Asserts that the value is null.
  Evaluator beNull() {
    addOperationName("beNull");
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &beNullOp);
  }

  /// Asserts that the value is an instance of the specified type.
  Evaluator instanceOf(Type)() {
    addOperationName("instanceOf");
    this._evaluation.expectedValue.typeNames.put(fullyQualifiedName!Type);
    this._evaluation.expectedValue.strValue = toHeapString("\"" ~ fullyQualifiedName!Type ~ "\"");
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &instanceOfOp);
  }

  /// Asserts that the value is approximately equal to expected within range.
  Evaluator approximately(T, U)(T value, U range) {
    import std.traits : isArray;

    addOperationName("approximately");
    setExpectedValue(value);
    () @trusted { _evaluation.expectedValue.meta["1"] = HeapSerializerRegistry.instance.serialize(range); } ();
    finalizeMessage();
    inhibit();

    static if (isArray!T) {
      return Evaluator(_evaluation, &approximatelyListOp);
    } else {
      return Evaluator(_evaluation, &approximatelyOp);
    }
  }

  /// Asserts that the value is between two bounds (exclusive).
  Evaluator between(T, U)(T value, U range) {
    addOperationName("between");
    setExpectedValue(value);
    () @trusted { _evaluation.expectedValue.meta["1"] = HeapSerializerRegistry.instance.serialize(range); } ();
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &betweenDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &betweenSysTimeOp);
    } else {
      return Evaluator(_evaluation, &betweenOp!T);
    }
  }

  /// Asserts that the value is within two bounds (alias for between).
  Evaluator within(T, U)(T value, U range) {
    addOperationName("within");
    setExpectedValue(value);
    () @trusted { _evaluation.expectedValue.meta["1"] = HeapSerializerRegistry.instance.serialize(range); } ();
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &betweenDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &betweenSysTimeOp);
    } else {
      return Evaluator(_evaluation, &betweenOp!T);
    }
  }

  /// Prevents the destructor from finalizing the evaluation.
  void inhibit() nothrow @safe @nogc {
    this.refCount = int.max;
  }

  /// Returns an Expect for the execution time of the current value.
  auto haveExecutionTime() {
    this.inhibit;

    auto result = expect(_evaluation.currentValue.duration, _evaluation.sourceFile, _evaluation.sourceLine, " have execution time");

    return result;
  }

  auto allocateGCMemory() {
    addOperationName("allocateGCMemory");
    finalizeMessage();
    inhibit();

    return Evaluator(_evaluation, &allocateGCMemoryOp);
  }

  auto allocateNonGCMemory() {
    addOperationName("allocateNonGCMemory");
    finalizeMessage();
    inhibit();

    return Evaluator(_evaluation, &allocateNonGCMemoryOp);
  }

  /// Appends an operation name to the current operation chain.
  void addOperationName(string value) nothrow @safe @nogc {
    this._evaluation.addOperationName(value);
  }

  /// Dispatches unknown method names as operations (no arguments).
  ref Expect opDispatch(string methodName)() return nothrow @nogc {
    addOperationName(methodName);

    return this;
  }

  /// Dispatches unknown method names as operations with arguments.
  ref Expect opDispatch(string methodName, Params...)(Params params) return if(Params.length > 0) {
    addOperationName(methodName);

    static if(Params.length > 0) {
      auto expectedValue = params[0].evaluate.evaluation;

      foreach(kv; _evaluation.expectedValue.meta.byKeyValue) {
        expectedValue.meta[kv.key] = kv.value;
      }

      _evaluation.expectedValue = expectedValue;
    }

    static if(Params.length >= 1) {
      static foreach (i, Param; Params) {
        () @trusted { _evaluation.expectedValue.meta[i.to!string] = HeapSerializerRegistry.instance.serialize(params[i]); } ();
      }
    }

    return this;
  }

  /// Sets the expected value for terminal operations.
  /// Serializes the value and stores it in the evaluation.
  void setExpectedValue(T)(T value) @trusted {
    auto expectedValue = value.evaluate.evaluation;

    foreach(kv; _evaluation.expectedValue.meta.byKeyValue) {
      expectedValue.meta[kv.key] = kv.value;
    }

    _evaluation.expectedValue = expectedValue;
    _evaluation.expectedValue.meta["0"] = HeapSerializerRegistry.instance.serialize(value);
  }
}

/// Creates an Expect from a callable delegate.
/// Executes the delegate and captures any thrown exception.
Expect expect(void delegate() callable, const string file = __FILE__, const size_t line = __LINE__, string prependText = null) @trusted {
  ValueEvaluation value;
  value.typeNames.put("callable");

  try {
    if(callable !is null) {
      callable();
    } else {
      value.typeNames.clear();
      value.typeNames.put("null");
    }
  } catch(Exception e) {
    value.throwable = e;
    value.meta["Exception"] = "yes";
  } catch(Throwable t) {
    value.throwable = t;
    value.meta["Throwable"] = "yes";
  }

  value.fileName = toHeapString(file);
  value.line = line;
  value.prependText = toHeapString(prependText);

  auto result = Expect(value);
  return result;
}

/// Creates an Expect struct from a lazy value.
/// Params:
///   testedValue = The value to test
///   file = Source file (auto-filled)
///   line = Source line (auto-filled)
///   prependText = Optional text to prepend to the value display
/// Returns: An Expect struct for fluent assertions
Expect expect(T)(lazy T testedValue, const string file = __FILE__, const size_t line = __LINE__, string prependText = null) @trusted {
  auto result = Expect(testedValue.evaluate(file, line, prependText).evaluation);
  return result;
}
