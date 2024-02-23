module fluentasserts.core.expect;

import fluentasserts.core.lifecycle;
import fluentasserts.core.evaluation;
import fluentasserts.core.results;

import fluentasserts.core.serializers;

import std.traits;
import std.string;
import std.uni;
import std.conv;

///
@safe struct Expect {

  private {
    Evaluation evaluation;
    int refCount;
  }

  this(ValueEvaluation value) @trusted {
    this.evaluation = new Evaluation();

    evaluation.id = Lifecycle.instance.beginEvaluation(value);
    evaluation.currentValue = value;
    evaluation.message = new MessageResult();
    evaluation.source = new SourceResult(value.fileName, value.line);

    try {
      auto sourceValue = evaluation.source.getValue;

      if(sourceValue == "") {
        evaluation.message.startWith(evaluation.currentValue.niceValue);
      } else {
        evaluation.message.startWith(sourceValue);
      }
    } catch(Exception) {
      evaluation.message.startWith(evaluation.currentValue.strValue);
    }

    evaluation.message.addText(" should");

    if(value.prependText) {
      evaluation.message.addText(value.prependText);
    }
  }

  this(ref return scope Expect another) {
    this.evaluation = another.evaluation;
    this.refCount = another.refCount + 1;
  }

  ~this() {
    refCount--;

    if(refCount < 0) {
      evaluation.message.addText(" ");
      evaluation.message.addText(evaluation.operationName.toNiceOperation);

      if(evaluation.expectedValue.niceValue) {
        evaluation.message.addText(" ");
        evaluation.message.addValue(evaluation.expectedValue.niceValue);
      } else if(evaluation.expectedValue.strValue) {
        evaluation.message.addText(" ");
        evaluation.message.addValue(evaluation.expectedValue.strValue);
      }

      Lifecycle.instance.endEvaluation(evaluation);
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
    addOperationName("withMessage");
    return this.equal(message);
  }

  Throwable thrown() {
    Lifecycle.instance.endEvaluation(evaluation);
    return evaluation.throwable;
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
    this.evaluation.expectedValue.meta["exceptionType"] = fullyQualifiedName!Type;
    this.evaluation.expectedValue.meta["throwableType"] = fullyQualifiedName!Type;

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
  auto greaterOrEqualTo(T)(T value) {
    return opDispatch!"greaterOrEqualTo"(value);
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
  auto lessOrEqualTo(T)(T value) {
    return opDispatch!"lessOrEqualTo"(value);
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

  auto beNull() {
    return opDispatch!"beNull";
  }

  auto instanceOf(Type)() {
    return opDispatch!"instanceOf"(fullyQualifiedName!Type);
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

  void inhibit() {
    this.refCount = int.max;
  }

  auto haveExecutionTime() {
    this.inhibit;

    auto result = expect(evaluation.currentValue.duration, evaluation.source.file, evaluation.source.line, " have execution time");

    return result;
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

    static if(Params.length > 0) {
      auto expectedValue = params[0].evaluate.evaluation;

      foreach(key, value; evaluation.expectedValue.meta) {
        expectedValue.meta[key] = value;
      }

      evaluation.expectedValue = expectedValue;
    }

    static if(Params.length >= 1) {
      static foreach (i, Param; Params) {
        () @trusted { evaluation.expectedValue.meta[i.to!string] = SerializerRegistry.instance.serialize(params[i]); } ();
      }
    }

    return this;
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
