module fluentasserts.core.expect;

import fluentasserts.core.lifecycle;
import fluentasserts.core.evaluation;
import fluentasserts.core.evaluator;
import fluentasserts.core.results;

import fluentasserts.core.serializers;

import fluentasserts.core.operations.equal : equalOp = equal;
import fluentasserts.core.operations.arrayEqual : arrayEqualOp = arrayEqual;
import fluentasserts.core.operations.contain : containOp = contain, arrayContainOp = arrayContain, arrayContainOnlyOp = arrayContainOnly;
import fluentasserts.core.operations.startWith : startWithOp = startWith;
import fluentasserts.core.operations.endWith : endWithOp = endWith;
import fluentasserts.core.operations.beNull : beNullOp = beNull;
import fluentasserts.core.operations.instanceOf : instanceOfOp = instanceOf;
import fluentasserts.core.operations.greaterThan : greaterThanOp = greaterThan, greaterThanDurationOp = greaterThanDuration, greaterThanSysTimeOp = greaterThanSysTime;
import fluentasserts.core.operations.greaterOrEqualTo : greaterOrEqualToOp = greaterOrEqualTo, greaterOrEqualToDurationOp = greaterOrEqualToDuration, greaterOrEqualToSysTimeOp = greaterOrEqualToSysTime;
import fluentasserts.core.operations.lessThan : lessThanOp = lessThan, lessThanDurationOp = lessThanDuration, lessThanSysTimeOp = lessThanSysTime;
import fluentasserts.core.operations.lessOrEqualTo : lessOrEqualToOp = lessOrEqualTo;
import fluentasserts.core.operations.between : betweenOp = between, betweenDurationOp = betweenDuration, betweenSysTimeOp = betweenSysTime;
import fluentasserts.core.operations.approximately : approximatelyOp = approximately, approximatelyListOp = approximatelyList;
import fluentasserts.core.operations.throwable : throwAnyExceptionOp = throwAnyException, throwExceptionOp = throwException, throwAnyExceptionWithMessageOp = throwAnyExceptionWithMessage, throwExceptionWithMessageOp = throwExceptionWithMessage, throwSomethingOp = throwSomething, throwSomethingWithMessageOp = throwSomethingWithMessage;

import std.datetime : Duration, SysTime;

import std.traits;
import std.string;
import std.uni;
import std.conv;

///
@safe struct Expect {

  private {
    Evaluation _evaluation;
    int refCount;
  }

  /// Getter for evaluation - allows external extensions via UFCS
  Evaluation evaluation() {
    return _evaluation;
  }

  this(ValueEvaluation value) @trusted {
    this._evaluation = new Evaluation();

    _evaluation.id = Lifecycle.instance.beginEvaluation(value);
    _evaluation.currentValue = value;
    _evaluation.message = new MessageResult();
    _evaluation.source = new SourceResult(value.fileName, value.line);

    try {
      auto sourceValue = _evaluation.source.getValue;

      if(sourceValue == "") {
        _evaluation.message.startWith(_evaluation.currentValue.niceValue);
      } else {
        _evaluation.message.startWith(sourceValue);
      }
    } catch(Exception) {
      _evaluation.message.startWith(_evaluation.currentValue.strValue);
    }

    _evaluation.message.addText(" should");

    if(value.prependText) {
      _evaluation.message.addText(value.prependText);
    }
  }

  this(ref return scope Expect another) {
    this._evaluation = another._evaluation;
    this.refCount = another.refCount + 1;
  }

  ~this() {
    refCount--;

    if(refCount < 0) {
      _evaluation.message.addText(" ");
      _evaluation.message.addText(_evaluation.operationName.toNiceOperation);

      if(_evaluation.expectedValue.niceValue) {
        _evaluation.message.addText(" ");
        _evaluation.message.addValue(_evaluation.expectedValue.niceValue);
      } else if(_evaluation.expectedValue.strValue) {
        _evaluation.message.addText(" ");
        _evaluation.message.addValue(_evaluation.expectedValue.strValue);
      }

      Lifecycle.instance.endEvaluation(_evaluation);
    }
  }

  /// Finalize the message before creating an Evaluator - for external extensions
  void finalizeMessage() {
    _evaluation.message.addText(" ");
    _evaluation.message.addText(_evaluation.operationName.toNiceOperation);

    if(_evaluation.expectedValue.niceValue) {
      _evaluation.message.addText(" ");
      _evaluation.message.addValue(_evaluation.expectedValue.niceValue);
    } else if(_evaluation.expectedValue.strValue) {
      _evaluation.message.addText(" ");
      _evaluation.message.addValue(_evaluation.expectedValue.strValue);
    }
  }

  string msg(const size_t line = __LINE__, const string file = __FILE__) @trusted {
    if(this.thrown is null) {
      throw new Exception("There were no thrown exceptions", file, line);
    }

    return this.thrown.message.to!string;
  }

  Expect withMessage(const size_t line = __LINE__, const string file = __FILE__) {
    addOperationName("withMessage");
    return this;
  }

  Expect withMessage(string message, const size_t line = __LINE__, const string file = __FILE__) {
    return opDispatch!"withMessage"(message);
  }

  Throwable thrown() {
    Lifecycle.instance.endEvaluation(_evaluation);
    return _evaluation.throwable;
  }

  ///
  Expect to() {
    return this;
  }

  ///
  Expect be () {
    _evaluation.message.addText(" be");
    return this;
  }

  ///
  Expect not() {
    _evaluation.isNegated = !_evaluation.isNegated;
    _evaluation.message.addText(" not");

    return this;
  }

  ///
  ThrowableEvaluator throwAnyException() {
    addOperationName("throwAnyException");
    finalizeMessage();
    inhibit();
    return ThrowableEvaluator(_evaluation, &throwAnyExceptionOp, &throwAnyExceptionWithMessageOp);
  }

  ///
  ThrowableEvaluator throwSomething() {
    addOperationName("throwSomething");
    finalizeMessage();
    inhibit();
    return ThrowableEvaluator(_evaluation, &throwSomethingOp, &throwSomethingWithMessageOp);
  }

  ///
  ThrowableEvaluator throwException(Type)() {
    this._evaluation.expectedValue.meta["exceptionType"] = fullyQualifiedName!Type;
    this._evaluation.expectedValue.meta["throwableType"] = fullyQualifiedName!Type;
    this._evaluation.expectedValue.strValue = "\"" ~ fullyQualifiedName!Type ~ "\"";

    addOperationName("throwException");
    _evaluation.message.addText(" throw exception ");
    _evaluation.message.addValue(_evaluation.expectedValue.strValue);
    inhibit();
    return ThrowableEvaluator(_evaluation, &throwExceptionOp, &throwExceptionWithMessageOp);
  }

  auto because(string reason) {
    _evaluation.message.prependText("Because " ~ reason ~ ", ");
    return this;
  }

  ///
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

  ///
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

  ///
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

  ///
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

  ///
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

  ///
  Evaluator lessThan(T)(T value) {
    addOperationName("lessThan");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &lessThanDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &lessThanSysTimeOp);
    } else {
      return Evaluator(_evaluation, &lessThanOp!T);
    }
  }

  ///
  Evaluator lessOrEqualTo(T)(T value) {
    addOperationName("lessOrEqualTo");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &lessOrEqualToOp!T);
  }

  ///
  Evaluator below(T)(T value) {
    addOperationName("below");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();

    static if (is(T == Duration)) {
      return Evaluator(_evaluation, &lessThanDurationOp);
    } else static if (is(T == SysTime)) {
      return Evaluator(_evaluation, &lessThanSysTimeOp);
    } else {
      return Evaluator(_evaluation, &lessThanOp!T);
    }
  }

  ///
  Evaluator startWith(T)(T value) {
    addOperationName("startWith");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &startWithOp);
  }

  ///
  Evaluator endWith(T)(T value) {
    addOperationName("endWith");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &endWithOp);
  }

  Evaluator containOnly(T)(T value) {
    addOperationName("containOnly");
    setExpectedValue(value);
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &arrayContainOnlyOp);
  }

  Evaluator beNull() {
    addOperationName("beNull");
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &beNullOp);
  }

  Evaluator instanceOf(Type)() {
    addOperationName("instanceOf");
    this._evaluation.expectedValue.strValue = "\"" ~ fullyQualifiedName!Type ~ "\"";
    finalizeMessage();
    inhibit();
    return Evaluator(_evaluation, &instanceOfOp);
  }

  Evaluator approximately(T, U)(T value, U range) {
    import std.traits : isArray;

    addOperationName("approximately");
    setExpectedValue(value);
    () @trusted { _evaluation.expectedValue.meta["1"] = SerializerRegistry.instance.serialize(range); } ();
    finalizeMessage();
    inhibit();

    static if (isArray!T) {
      return Evaluator(_evaluation, &approximatelyListOp);
    } else {
      return Evaluator(_evaluation, &approximatelyOp);
    }
  }

  Evaluator between(T, U)(T value, U range) {
    addOperationName("between");
    setExpectedValue(value);
    () @trusted { _evaluation.expectedValue.meta["1"] = SerializerRegistry.instance.serialize(range); } ();
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

  Evaluator within(T, U)(T value, U range) {
    addOperationName("within");
    setExpectedValue(value);
    () @trusted { _evaluation.expectedValue.meta["1"] = SerializerRegistry.instance.serialize(range); } ();
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

  void inhibit() {
    this.refCount = int.max;
  }

  auto haveExecutionTime() {
    this.inhibit;

    auto result = expect(_evaluation.currentValue.duration, _evaluation.source.file, _evaluation.source.line, " have execution time");

    return result;
  }

  void addOperationName(string value) {

    if(this._evaluation.operationName) {
      this._evaluation.operationName ~= ".";
    }

    this._evaluation.operationName ~= value;
  }

  ///
  Expect opDispatch(string methodName)() {
    addOperationName(methodName);

    return this;
  }

  ///
  Expect opDispatch(string methodName, Params...)(Params params) if(Params.length > 0) {
    addOperationName(methodName);

    static if(Params.length > 0) {
      auto expectedValue = params[0].evaluate.evaluation;

      foreach(key, value; _evaluation.expectedValue.meta) {
        expectedValue.meta[key] = value;
      }

      _evaluation.expectedValue = expectedValue;
    }

    static if(Params.length >= 1) {
      static foreach (i, Param; Params) {
        () @trusted { _evaluation.expectedValue.meta[i.to!string] = SerializerRegistry.instance.serialize(params[i]); } ();
      }
    }

    return this;
  }

  /// Set expected value - helper for terminal operations
  void setExpectedValue(T)(T value) @trusted {
    auto expectedValue = value.evaluate.evaluation;

    foreach(key, v; _evaluation.expectedValue.meta) {
      expectedValue.meta[key] = v;
    }

    _evaluation.expectedValue = expectedValue;
    _evaluation.expectedValue.meta["0"] = SerializerRegistry.instance.serialize(value);
  }
}

///
Expect expect(void delegate() callable, const string file = __FILE__, const size_t line = __LINE__, string prependText = null) @trusted {
  ValueEvaluation value;
  value.typeNames = [ "callable" ];

  try {
    if(callable !is null) {
      callable();
    } else {
      value.typeNames = ["null"];
    }
  } catch(Exception e) {
    value.throwable = e;
    value.meta["Exception"] = "yes";
  } catch(Throwable t) {
    value.throwable = t;
    value.meta["Throwable"] = "yes";
  }

  value.fileName = file;
  value.line = line;
  value.prependText = prependText;

  return Expect(value);
}

///
Expect expect(T)(lazy T testedValue, const string file = __FILE__, const size_t line = __LINE__, string prependText = null) @trusted {
  return Expect(testedValue.evaluate(file, line, prependText).evaluation);
}

///
string toNiceOperation(string value) @safe nothrow {
  string newValue;

  foreach(index, ch; value) {
    if(index == 0) {
      newValue ~= ch.toLower;
      continue;
    }

    if(ch == '.') {
      newValue ~= ' ';
      continue;
    }

    if(ch.isUpper && value[index - 1].isLower) {
      newValue ~= ' ';
      newValue ~= ch.toLower;
      continue;
    }

    newValue ~= ch;
  }

  return newValue;
}

/// toNiceOperation converts to a nice and readable string
unittest {
  expect("".toNiceOperation).to.equal("");
  expect("a.b".toNiceOperation).to.equal("a b");
  expect("aB".toNiceOperation).to.equal("a b");
}
