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

import std.meta;
import std.conv;
import std.datetime;

alias BasicNumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);
alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real, ifloat, idouble, ireal, cfloat, cdouble, creal, char, wchar, dchar);
alias StringTypes = AliasSeq!(string, wstring, dstring, const(char)[]);

static this() {
  SerializerRegistry.instance = new SerializerRegistry;
  Lifecycle.instance = new Lifecycle;

  ResultGlyphs.resetDefaults;

  Registry.instance = new Registry();

  Registry.instance.register!(Duration, Duration)("lessThan", &lessThanDuration);
  Registry.instance.register!(Duration, Duration)("below", &lessThanDuration);

  Registry.instance.register!(SysTime, SysTime)("lessThan", &lessThanSysTime);
  Registry.instance.register!(SysTime, SysTime)("below", &lessThanSysTime);

  Registry.instance.register!(Duration, Duration)("greaterThan", &greaterThanDuration);
  Registry.instance.register!(Duration, Duration)("above", &greaterThanDuration);

  Registry.instance.register!(SysTime, SysTime)("greaterThan", &greaterThanSysTime);
  Registry.instance.register!(SysTime, SysTime)("above", &greaterThanSysTime);

  Registry.instance.register!(Duration, Duration)("between", &betweenDuration);
  Registry.instance.register!(Duration, Duration)("within", &betweenDuration);

  Registry.instance.register!(SysTime, SysTime)("between", &betweenSysTime);
  Registry.instance.register!(SysTime, SysTime)("within", &betweenSysTime);

  Registry.instance.register("string", "string", "equal", &equal);
  Registry.instance.register("bool", "bool", "equal", &equal);

  static foreach(Type; NumericTypes) {
    Registry.instance.register(Type.stringof, Type.stringof, "equal", &equal);
    Registry.instance.register(Type.stringof ~ "[]", Type.stringof ~ "[]", "equal", &arrayEqual);
    Registry.instance.register(Type.stringof ~ "[]", "void[]", "equal", &arrayEqual);
  }

  static foreach(Type; BasicNumericTypes) {
    Registry.instance.register(Type.stringof, Type.stringof, "greaterOrEqualTo", &greaterOrEqualTo!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "greaterThan", &greaterThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "above", &greaterThan!Type);

    Registry.instance.register(Type.stringof, Type.stringof, "lessOrEqualTo", &lessOrEqualTo!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "lessThan", &lessThan!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "below", &lessThan!Type);

    Registry.instance.register(Type.stringof, Type.stringof, "between", &between!Type);
    Registry.instance.register(Type.stringof, Type.stringof, "within", &between!Type);
  }

  static foreach(Type1; NumericTypes) {
    Registry.instance.register(Type1.stringof ~ "[]", "void[]", "approximately", &approximatelyList);

    static foreach(Type2; NumericTypes) {
      Registry.instance.register(Type1.stringof, Type2.stringof, "equal", &equal);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "equal", &arrayEqual);
      Registry.instance.register(Type1.stringof ~ "[]", "void[]", "equal", &arrayEqual);

      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "contain", &arrayContain);
      Registry.instance.register(Type1.stringof ~ "[]", "void[]", "contain", &arrayContain);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof, "contain", &arrayContain);

      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "containOnly", &arrayContainOnly);
      Registry.instance.register(Type1.stringof ~ "[]", "void[]", "containOnly", &arrayContainOnly);
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof ~ "[]", "approximately", &approximatelyList);

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
      Registry.instance.register(Type1.stringof ~ "[]", Type2.stringof, "contain", &arrayContain);
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

  Registry.instance.register("*", "*", "instanceOf", &instanceOf);

  Registry.instance.register("callable", "", "throwAnyException", &throwAnyException);
  Registry.instance.register("callable", "", "throwException", &throwException);

  Registry.instance.register("*", "*", "throwAnyException", &throwAnyException);
  Registry.instance.register("*", "*", "throwAnyException.withMessage.equal", &throwAnyExceptionWithMessage);
  Registry.instance.register("*", "*", "throwException", &throwException);
  Registry.instance.register("*", "*", "throwException.withMessage.equal", &throwExceptionWithMessage);
  Registry.instance.register("*", "*", "throwSomething", &throwAnyException);
  Registry.instance.register("*", "*", "throwSomething.withMessage.equal", &throwAnyExceptionWithMessage);
  Registry.instance.register("*", "*", "beNull", &beNull);
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
  void endEvaluation(ref Evaluation evaluation) @trusted {
    if(evaluation.isEvaluated) return;

    evaluation.isEvaluated = true;
    auto results = Registry.instance.handle(evaluation);

    if(evaluation.currentValue.throwable !is null) {
      throw evaluation.currentValue.throwable;
    }

    if(evaluation.expectedValue.throwable !is null) {
      throw evaluation.currentValue.throwable;
    }

    if(results.length == 0) {
      return;
    }

    version(DisableSourceResult) {} else {
      results ~= evaluation.source;
    }

    if(evaluation.message !is null) {
      results = evaluation.message ~ results;
    }

    throw new TestException(results, evaluation.source.file, evaluation.source.line);
  }
}
