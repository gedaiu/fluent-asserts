module fluentasserts.core.expect;

import fluentasserts.core.lifecycle;
import fluentasserts.core.evaluation;
import fluentasserts.core.results;

import std.traits;
import std.conv;

///
@safe struct Expect {

  private {
    Evaluation evaluation;
    int refCount;
  }

  this(ValueEvaluation value, const string fileName, const size_t line) {
    this.evaluation = new Evaluation();

    evaluation.id = Lifecycle.instance.beginEvaluation(value);
    evaluation.currentValue = value;
    evaluation.message = new MessageResult();
    evaluation.source = new SourceResult(fileName, line);

    try {
      auto sourceValue = evaluation.source.getValue;

      if(sourceValue == "") {
        evaluation.message.startWith(evaluation.currentValue.strValue);
      } else {
        evaluation.message.startWith(sourceValue);
      }
    } catch(Exception) {
      evaluation.message.startWith(evaluation.currentValue.strValue);
    }

    evaluation.message.addText(" should");
  }

  this(ref return scope Expect another) {
    this.evaluation = another.evaluation;
    this.refCount = another.refCount + 1;
  }

  ~this() {
    refCount--;

    if(refCount < 0) {
      Lifecycle.instance.endEvaluation(evaluation);
    }
  }

  ///
  Expect to() {
    return this;
  }

  ///
  Expect be () {
    evaluation.message.addText(" be");
    return this;
  }

  ///
  Expect not() {
    evaluation.isNegated = !evaluation.isNegated;
    evaluation.message.addText(" not");

    return this;
  }

  ///
  auto throwAnyException() {
    return opDispatch!"throwAnyException";
  }

  ///
  Expect throwException(Type)() {
    return opDispatch!"throwException"(fullyQualifiedName!Type);
  }

  auto because(string reason) {
    evaluation.message.prependText("Because " ~ reason ~ ", ");
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
    if(this.evaluation.operationName) {
      this.evaluation.operationName ~= ".";
    }

    this.evaluation.operationName ~= value;
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
      evaluation.expectedValue = expectedValue;
    }

    static if(Params.length > 1) {
      auto expectedValue = params[0].evaluate.evaluation;

      static foreach (i, Param; Params) {
        () @trusted { expectedValue.meta[i.to!string] = params[i].to!string; } ();
      }

      evaluation.expectedValue = expectedValue;
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