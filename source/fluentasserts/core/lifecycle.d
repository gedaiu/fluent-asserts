module fluentasserts.core.lifecycle;

import fluentasserts.core.base;
import fluentasserts.core.evaluation;
import fluentasserts.core.operations.approximately;
import fluentasserts.core.operations.arrayEqual;
import fluentasserts.core.operations.between;
import fluentasserts.core.operations.contain;
import fluentasserts.core.operations.endWith;
import fluentasserts.core.operations.equal;
import fluentasserts.core.operations.greaterThan;
import fluentasserts.core.operations.lessThan;
import fluentasserts.core.operations.registry;
import fluentasserts.core.operations.startWith;
import fluentasserts.core.operations.throwable;
import fluentasserts.core.results;
import fluentasserts.core.serializers;

import std.meta;
import std.conv;

alias BasicNumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);
alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real, ifloat, idouble, ireal, cfloat, cdouble, creal, char, wchar, dchar);
alias StringTypes = AliasSeq!(string, wstring, dstring);

static this() {
  SerializerRegistry.instance = new SerializerRegistry;
  Lifecycle.instance = new Lifecycle;

  ResultGlyphs.resetDefaults;

  Registry.instance = new Registry();
  Registry.instance.register("string", "string", "equal", &equal);
  Registry.instance.register("bool", "bool", "equal", &equal);

  static foreach(Type; NumericTypes) {
    Registry.instance.register(Type.stringof, Type.stringof, "equal", &equal);
    Registry.instance.register(Type.stringof ~ "[]", Type.stringof ~ "[]", "equal", &arrayEqual);
    Registry.instance.register(Type.stringof ~ "[]", "void[]", "equal", &arrayEqual);
  }

  static foreach(Type; BasicNumericTypes) {
    Registry.instance.register(Type.stringof, Type.stringof, "greaterThan", &greaterThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "above", &greaterThan!Type);

    Registry.instance.register(Type.stringof, Type.stringof, "lessThan", &lessThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "below", &lessThan!Type);

    Registry.instance.register(Type.stringof, Type.stringof, "between", &between!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "within", &between!Type);
  }

  static foreach(Type1; NumericTypes) {
    Registry.instance.register(Type1.stringof ~ "[]", "void[]", "approximately", &approximately);

    static foreach(Type2; NumericTypes) {
      Registry.instance.register(Type1.stringof, Type2.stringof, "equal", &equal);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "equal", &arrayEqual);
      Registry.instance.register(Type1.stringof ~ "[]", "void[]", "equal", &arrayEqual);

      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "contain", &arrayContain);
      Registry.instance.register(Type1.stringof ~ "[]", "void[]", "contain", &arrayContain);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof, "contain", &arrayContain);

      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "containOnly", &arrayContainOnly);
      Registry.instance.register(Type1.stringof ~ "[]", "void[]", "containOnly", &arrayContainOnly);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "approximately", &approximately);

      Registry.instance.register(Type1.stringof, Type2.stringof, "approximately", &approximately);
    }
  }

  static foreach(Type1; StringTypes) {
    Registry.instance.register(Type1.stringof ~ "[]", "void[]", "equal", &arrayEqual);

    static foreach(Type2; StringTypes) {
      Registry.instance.register(Type1.stringof, Type2.stringof, "equal", &equal);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "equal", &arrayEqual);

      Registry.instance.register(Type1.stringof, Type2.stringof ~ "[]", "contain", &contain);
      Registry.instance.register(Type1.stringof, Type2.stringof, "contain", &contain);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "contain", &arrayContain);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "containOnly", &arrayContainOnly);

      Registry.instance.register(Type1.stringof, Type2.stringof, "startWith", &startWith);
      Registry.instance.register(Type1.stringof, Type2.stringof, "endWith", &endWith);
    }
  }

  Registry.instance.register("*[]", "*[]", "equal", &arrayEqual);
  Registry.instance.register("*", "*", "equal", &equal);

  static foreach(Type; StringTypes) {
    Registry.instance.register(Type.stringof, "char", "contain", &contain);
    Registry.instance.register(Type.stringof, "char", "startWith", &startWith);
    Registry.instance.register(Type.stringof, "char", "endWith", &endWith);
  }

  Registry.instance.register("callable", "", "throwAnyException", &throwAnyException);
  Registry.instance.register("callable", "", "throwException", &throwException);

  Registry.instance.register("*", "*", "throwAnyException", &throwAnyException);
  Registry.instance.register("*", "*", "throwException", &throwException);
  Registry.instance.register("*", "*", "throwAnyException.withMessage.equal", &throwAnyExceptionWithMessage);


}

/// The assert lifecycle
@safe class Lifecycle {

  /// Global instance for the assert lifecicle
  static Lifecycle instance;

  private {
    Evaluation evaluation;

    /// The nice message printed to the user
    MessageResult message;

    /// The source code where the assert is located
    SourceResult sourceResult;

    ///
    int assertIndex;

    ///
    int totalAsserts;
  }

  void incAssertIndex() {
    assertIndex++;
  }

  /// Checks if an assert operation was set
  bool hasOperation() {
    return evaluation.operationName != "";
  }

  /// Method called when a new value is evaluated
  Lifecycle beginEvaluation(ValueEvaluation value) @safe nothrow {
    assert(assertIndex >= 0, "assert index is `" ~ assertIndex.to!string ~ "`. It must be >= 0.");

    totalAsserts++;
    assertIndex++;

    evaluation = Evaluation();

    if(assertIndex == 1) {
      evaluation.currentValue = value;
      message = new MessageResult();
    }

    return this;
  }

  /// Method called when the oracle value is known
  Lifecycle compareWith(ValueEvaluation value) @safe nothrow {
    evaluation.expectedValue = value;
    return this;
  }

  /// Method called when the comparison operation is known
  Lifecycle usingOperation(string operationName) @safe nothrow {
    assert(evaluation.operationName == "", "Operation name is already set to `" ~ evaluation.operationName ~ "`");
    evaluation.operationName = operationName;
    return this;
  }

  /// Method called when the operation result needs to be negated to be true
  Lifecycle usingNegation(bool value) {
    evaluation.isNegated = value;

    if(value) {
      addText(" not");
    }

    return this;
  }

  /// Method called when the assert location is known
  Lifecycle atSourceLocation(const string fileName, const size_t line) @safe nothrow {
    evaluation.fileName = fileName;
    evaluation.line = line;
    sourceResult = new SourceResult(fileName, line);

    try {
      auto value = sourceResult.getValue;

      if(value == "") {
        message.startWith(evaluation.currentValue.strValue);
      } else {
        message.startWith(value);
      }
    } catch(Exception) {
      message.startWith(evaluation.currentValue.strValue);
    }

    addText(" should");

    return this;
  }

  ///
  Lifecycle prependText(string text) @safe nothrow {
    message.prependText(text);

    return this;
  }

  ///
  Lifecycle addText(string text) @safe nothrow {
    if(text == "throwAnyException") {
      text = "throw any exception";
    }

    message.addText(text);
    return this;
  }

  ///
  Lifecycle addValue(string value) @safe nothrow {
    message.addValue(value);
    return this;
  }

  ///
  EvaluationResult endEvaluation() @trusted {
    EvaluationResult result;

    assertIndex--;
    assert(assertIndex >= 0, "assert index is `" ~ assertIndex.to!string ~ "`. It must be >= 0.");

    if(assertIndex > 0) return result;

    addText(" ");
    addText(evaluation.operationName);

    if(evaluation.expectedValue.strValue) {
      addText(" ");
      addValue(evaluation.expectedValue.strValue);
    }

    result.message = message;
    result.results = Registry.instance.handle(evaluation);

    version(DisableSourceResult) {} else {
      if(result.results.length > 0) {
        result.results ~= sourceResult;
      }
    }

    result.fileName = evaluation.fileName;
    result.line = evaluation.line;

    if(evaluation.currentValue.throwable !is null) {
      result.throwable = evaluation.currentValue.throwable;
    }

    if(evaluation.expectedValue.throwable !is null) {
      result.throwable = evaluation.currentValue.throwable;
    }

    return result;
  }
}

///
@safe struct EvaluationResult {
  MessageResult message;
  IResult[] results;
  string fileName;
  size_t line;
  Throwable throwable;

  void perform() {
    if(throwable !is null) {
      throw throwable;
    }

    if(results.length == 0) {
      return;
    }

    IResult[] all;

    if(message !is null) {
      all ~= message;
    }

    all ~= results;

    throw new TestException(all, fileName, line);
  }

  ~this() {
    this.perform;
  }
}
