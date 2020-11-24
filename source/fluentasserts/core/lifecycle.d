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
    ///
    int totalAsserts;
  }

  /// Method called when a new value is evaluated
  int beginEvaluation(ValueEvaluation value) @safe nothrow {
    totalAsserts++;

    return totalAsserts;
  }

  ///
  EvaluationResult endEvaluation(ref Evaluation evaluation) @trusted {
    EvaluationResult result;

    evaluation.message.addText(" ");
    evaluation.message.addText(evaluation.operationName);

    if(evaluation.expectedValue.strValue) {
      evaluation.message.addText(" ");
      evaluation.message.addValue(evaluation.expectedValue.strValue);
    }

    result.message = evaluation.message;
    result.results = Registry.instance.handle(evaluation);

    version(DisableSourceResult) {} else {
      if(result.results.length > 0) {
        result.results ~= evaluation.source;
      }
    }

    result.fileName = evaluation.source.file;
    result.line = evaluation.source.line;

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
