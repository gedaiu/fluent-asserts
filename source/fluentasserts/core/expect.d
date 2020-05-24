module fluentasserts.core.expect;

import fluentasserts.core.lifecycle;
import fluentasserts.core.evaluation;

///
struct Expect {

  ///
  bool isNegated;

  this(ValueEvaluation value, const string file, const size_t line) {
    Lifecycle.instance.beginEvaluation(value)
      .atSourceLocation(file, line)
      .usingNegation(isNegated);
  }

  this(ref return scope Expect another) {
    this.isNegated = isNegated;
    Lifecycle.instance.incAssertIndex;
  }

  ~this() {
    Lifecycle.instance.endEvaluation;
  }

  ///
  Expect to() {
    return this;
  }

  ///
  Expect not() {
    isNegated = !isNegated;
    Lifecycle.instance.usingNegation(isNegated);

    return this;
  }

  ///
  alias throwAnyException = opDispatch!"throwAnyException";

  ///
  Expect opDispatch(string methodName, Params...)(Params params) {
    Lifecycle.instance.usingOperation(methodName);

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