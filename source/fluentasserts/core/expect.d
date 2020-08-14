module fluentasserts.core.expect;

import fluentasserts.core.lifecycle;
import fluentasserts.core.evaluation;

import std.traits;
import std.conv;

///
@safe struct Expect {

  ///
  bool isNegated;

  ///
  string operationName;

  this(ValueEvaluation value, const string file, const size_t line) {
    Lifecycle.instance.beginEvaluation(value)
      .atSourceLocation(file, line)
      .usingNegation(isNegated);
  }

  this(ref return scope Expect another) {
    this.isNegated = another.isNegated;
    this.operationName = another.operationName;
    Lifecycle.instance.incAssertIndex;
  }

  ~this() {
    if(!Lifecycle.instance.hasOperation) {
      Lifecycle.instance.usingOperation(operationName);
    }

    Lifecycle.instance.endEvaluation;
  }

  ///
  Expect to() {
    return this;
  }

  ///
  Expect be () {
    Lifecycle.instance.addText(" be");
    return this;
  }

  ///
  Expect not() {
    isNegated = !isNegated;
    Lifecycle.instance.usingNegation(isNegated);

    return this;
  }

  ///
  auto throwAnyException() {
    return opDispatch!"throwAnyException";
  }

  ///
  Expect throwException(Type)() {
    Lifecycle.instance.usingOperation("throwException");

    return opDispatch!"throwException"(fullyQualifiedName!Type);
  }

  auto because(string reason) {
    Lifecycle.instance.prependText("Because " ~ reason ~ ", ");
    return this;
  }

  ///
  auto equal(T)(T value) {
    return opDispatch!"equal"(value);
  }

  ///
  auto contain(T)(T value) {
    return opDispatch!"contain"(value);
  }

  ///
  auto greaterThan(T)(T value) {
    return opDispatch!"greaterThan"(value);
  }

  ///
  auto above(T)(T value) {
    return opDispatch!"above"(value);
  }
  ///
  auto lessThan(T)(T value) {
    return opDispatch!"lessThan"(value);
  }

  ///
  auto below(T)(T value) {
    return opDispatch!"below"(value);
  }

  ///
  auto startWith(T)(T value) {
    return opDispatch!"startWith"(value);
  }

  ///
  auto endWith(T)(T value) {
    return opDispatch!"endWith"(value);
  }

  auto containOnly(T)(T value) {
    return opDispatch!"containOnly"(value);
  }

  auto approximately(T, U)(T value, U range) {
    return opDispatch!"approximately"(value, range);
  }

  auto between(T, U)(T value, U range) {
    return opDispatch!"between"(value, range);
  }

  auto within(T, U)(T value, U range) {
    return opDispatch!"within"(value, range);
  }

  void addOperationName(string value) {
    if(this.operationName) {
      this.operationName ~= ".";
    }

    this.operationName ~= value;
  }

  ///
  Expect opDispatch(string methodName)() {
    addOperationName(methodName);

    return this;
  }

  ///
  Expect opDispatch(string methodName, Params...)(Params params) if(Params.length > 0) {
    addOperationName(methodName);

    static if(Params.length == 1) {
      auto expectedValue = params[0].evaluate.evaluation;
      Lifecycle.instance.compareWith(expectedValue);
    }

    static if(Params.length > 1) {
      auto expectedValue = params[0].evaluate.evaluation;

      static foreach (i, Param; Params) {
        () @trusted { expectedValue.meta[i.to!string] = params[i].to!string; } ();
      }

      Lifecycle.instance.compareWith(expectedValue);
    }

    return this;
  }
}

///
Expect expect(void delegate() callable, const string file = __FILE__, const size_t line = __LINE__) @trusted {
  ValueEvaluation value;
  value.typeName = "callable";

  try {
    callable();
  } catch(Exception e) {
    value.throwable = e;
    value.meta["Exception"] = "yes";
  } catch(Throwable t) {
    value.throwable = t;
    value.meta["Throwable"] = "yes";
  }

  return Expect(value, file, line);
}

///
Expect expect(T)(lazy T testedValue, const string file = __FILE__, const size_t line = __LINE__) @trusted {
  return Expect(testedValue.evaluate.evaluation, file, line);
}