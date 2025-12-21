module fluentasserts.operations.snapshot;

version (unittest) {
    import fluent.asserts;
    import fluentasserts.core.base;
    import fluentasserts.core.expect;
    import fluentasserts.core.lifecycle;
    import fluentasserts.core.evaluation.eval : Evaluation;
    import std.stdio;
    import std.file;
    import std.array;
}

// Split into individual tests to avoid stack overflow from static foreach expansion.
// Each test is small and has its own stack frame.

@("snapshot: equal scalar")
unittest {
    auto posEval = recordEvaluation({ expect(5).to.equal(3); });
    assert(posEval.result.expected[] == "3");
    assert(posEval.result.actual[] == "5");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(5).to.not.equal(5); });
    assert(negEval.result.expected[] == "not 5");
    assert(negEval.result.actual[] == "5");
    assert(negEval.result.negated == true);
}

@("snapshot: equal string")
unittest {
    auto posEval = recordEvaluation({ expect("hello").to.equal("world"); });
    assert(posEval.result.expected[] == "world");
    assert(posEval.result.actual[] == "hello");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect("hello").to.not.equal("hello"); });
    assert(negEval.result.expected[] == "not hello");
    assert(negEval.result.actual[] == "hello");
    assert(negEval.result.negated == true);
}

@("snapshot: equal array")
unittest {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.equal([1,2,4]); });
    assert(posEval.result.expected[] == "[1, 2, 4]");
    assert(posEval.result.actual[] == "[1, 2, 3]");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.equal([1,2,3]); });
    assert(negEval.result.expected[] == "not [1, 2, 3]");
    assert(negEval.result.actual[] == "[1, 2, 3]");
    assert(negEval.result.negated == true);
}

@("snapshot: contain string")
unittest {
    auto posEval = recordEvaluation({ expect("hello").to.contain("xyz"); });
    assert(posEval.result.expected[] == "to contain xyz");
    assert(posEval.result.actual[] == "hello");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect("hello").to.not.contain("ell"); });
    assert(negEval.result.expected[] == "not to contain ell");
    assert(negEval.result.actual[] == "hello");
    assert(negEval.result.negated == true);
}

@("snapshot: contain array")
unittest {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.contain(5); });
    assert(posEval.result.expected[] == "to contain 5");
    assert(posEval.result.actual[] == "[1, 2, 3]");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.contain(2); });
    assert(negEval.result.expected[] == "not to contain 2");
    assert(negEval.result.actual[] == "[1, 2, 3]");
    assert(negEval.result.negated == true);
}

@("snapshot: containOnly")
unittest {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.containOnly([1,2]); });
    assert(posEval.result.expected[] == "to contain only [1, 2]");
    assert(posEval.result.actual[] == "[1, 2, 3]");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.containOnly([1,2,3]); });
    assert(negEval.result.expected[] == "not to contain only [1, 2, 3]");
    assert(negEval.result.actual[] == "[1, 2, 3]");
    assert(negEval.result.negated == true);
}

@("snapshot: startWith")
unittest {
    auto posEval = recordEvaluation({ expect("hello").to.startWith("xyz"); });
    assert(posEval.result.expected[] == "to start with xyz");
    assert(posEval.result.actual[] == "hello");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect("hello").to.not.startWith("hel"); });
    assert(negEval.result.expected[] == "not to start with hel");
    assert(negEval.result.actual[] == "hello");
    assert(negEval.result.negated == true);
}

@("snapshot: endWith")
unittest {
    auto posEval = recordEvaluation({ expect("hello").to.endWith("xyz"); });
    assert(posEval.result.expected[] == "to end with xyz");
    assert(posEval.result.actual[] == "hello");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect("hello").to.not.endWith("llo"); });
    assert(negEval.result.expected[] == "not to end with llo");
    assert(negEval.result.actual[] == "hello");
    assert(negEval.result.negated == true);
}

@("snapshot: beNull")
unittest {
    Object obj1 = new Object();
    auto posEval = recordEvaluation({ expect(obj1).to.beNull; });
    assert(posEval.result.expected[] == "null");
    assert(posEval.result.actual[] == "object.Object");
    assert(posEval.result.negated == false);

    Object obj2 = null;
    auto negEval = recordEvaluation({ expect(obj2).to.not.beNull; });
    assert(negEval.result.expected[] == "not null");
    assert(negEval.result.actual[] == "object.Object");
    assert(negEval.result.negated == true);
}

@("snapshot: approximately scalar")
unittest {
    auto posEval = recordEvaluation({ expect(0.5).to.be.approximately(0.3, 0.1); });
    assert(posEval.result.expected[] == "0.3±0.1");
    assert(posEval.result.actual[] == "0.5");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(0.351).to.not.be.approximately(0.35, 0.01); });
    assert(negEval.result.expected[] == "0.35±0.01");
    assert(negEval.result.actual[] == "0.351");
    assert(negEval.result.negated == true);
}

@("snapshot: approximately array")
unittest {
    auto posEval = recordEvaluation({ expect([0.5]).to.be.approximately([0.3], 0.1); });
    assert(posEval.result.expected[] == "[0.3±0.1]");
    assert(posEval.result.actual[] == "[0.5]");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect([0.35]).to.not.be.approximately([0.35], 0.01); });
    assert(negEval.result.expected[] == "[0.35±0.01]");
    assert(negEval.result.actual[] == "[0.35]");
    assert(negEval.result.negated == true);
}

@("snapshot: greaterThan")
unittest {
    auto posEval = recordEvaluation({ expect(3).to.be.greaterThan(5); });
    assert(posEval.result.expected[] == "greater than 5");
    assert(posEval.result.actual[] == "3");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(5).to.not.be.greaterThan(3); });
    assert(negEval.result.expected[] == "less than or equal to 3");
    assert(negEval.result.actual[] == "5");
    assert(negEval.result.negated == true);
}

@("snapshot: lessThan")
unittest {
    auto posEval = recordEvaluation({ expect(5).to.be.lessThan(3); });
    assert(posEval.result.expected[] == "less than 3");
    assert(posEval.result.actual[] == "5");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(3).to.not.be.lessThan(5); });
    assert(negEval.result.expected[] == "greater than or equal to 5");
    assert(negEval.result.actual[] == "3");
    assert(negEval.result.negated == true);
}

@("snapshot: between")
unittest {
    auto posEval = recordEvaluation({ expect(10).to.be.between(1, 5); });
    assert(posEval.result.expected[] == "a value inside (1, 5) interval");
    assert(posEval.result.actual[] == "10");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(3).to.not.be.between(1, 5); });
    assert(negEval.result.expected[] == "a value outside (1, 5) interval");
    assert(negEval.result.actual[] == "3");
    assert(negEval.result.negated == true);
}

@("snapshot: greaterOrEqualTo")
unittest {
    auto posEval = recordEvaluation({ expect(3).to.be.greaterOrEqualTo(5); });
    assert(posEval.result.expected[] == "greater or equal than 5");
    assert(posEval.result.actual[] == "3");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(5).to.not.be.greaterOrEqualTo(3); });
    assert(negEval.result.expected[] == "less than 3");
    assert(negEval.result.actual[] == "5");
    assert(negEval.result.negated == true);
}

@("snapshot: lessOrEqualTo")
unittest {
    auto posEval = recordEvaluation({ expect(5).to.be.lessOrEqualTo(3); });
    assert(posEval.result.expected[] == "less or equal to 3");
    assert(posEval.result.actual[] == "5");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(3).to.not.be.lessOrEqualTo(5); });
    assert(negEval.result.expected[] == "greater than 5");
    assert(negEval.result.actual[] == "3");
    assert(negEval.result.negated == true);
}

@("snapshot: instanceOf")
unittest {
    auto posEval = recordEvaluation({ expect(new Object()).to.be.instanceOf!Exception; });
    assert(posEval.result.expected[] == "typeof object.Exception");
    assert(posEval.result.actual[] == "typeof object.Object");
    assert(posEval.result.negated == false);

    auto negEval = recordEvaluation({ expect(new Exception("test")).to.not.be.instanceOf!Object; });
    assert(negEval.result.expected[] == "not typeof object.Object");
    assert(negEval.result.actual[] == "typeof object.Exception");
    assert(negEval.result.negated == true);
}
