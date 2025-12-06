module fluentasserts.operations.snapshot;

version (unittest) {
    import fluent.asserts;
    import fluentasserts.core.base;
    import fluentasserts.core.expect;
    import fluentasserts.core.lifecycle;
    import fluentasserts.core.evaluation;
    import std.stdio;
    import std.file;
    import std.array;

    struct SnapshotCase {
        string name;
        string code;
        string posExpected;
        string posActual;
        bool posNegated;
        string negCode;
        string negExpected;
        string negActual;
        bool negNegated;
    }
}

@("operation snapshots for all operations")
unittest {
    auto output = appender!string();

    output.put("# Operation Snapshots\n\n");
    output.put("This file contains snapshots of all assertion operations with both positive and negated failure variants.\n\n");

    static foreach (c; [
        SnapshotCase("equal (scalar)", "expect(5).to.equal(3)",
            "3", "5", false,
            "expect(5).to.not.equal(5)",
            "not 5", "5", true),
        SnapshotCase("equal (string)", `expect("hello").to.equal("world")`,
            "world", "hello", false,
            `expect("hello").to.not.equal("hello")`,
            "not hello", "hello", true),
        SnapshotCase("equal (array)", "expect([1,2,3]).to.equal([1,2,4])",
            "[1, 2, 4]", "[1, 2, 3]", false,
            "expect([1,2,3]).to.not.equal([1,2,3])",
            "not [1, 2, 3]", "[1, 2, 3]", true),
        SnapshotCase("contain (string)", `expect("hello").to.contain("xyz")`,
            "to contain xyz", "hello", false,
            `expect("hello").to.not.contain("ell")`,
            "not to contain ell", "hello", true),
        SnapshotCase("contain (array)", "expect([1,2,3]).to.contain(5)",
            "to contain 5", "[1, 2, 3]", false,
            "expect([1,2,3]).to.not.contain(2)",
            "not to contain 2", "[1, 2, 3]", true),
        SnapshotCase("containOnly", "expect([1,2,3]).to.containOnly([1,2])",
            "to contain only [1, 2]", "[1, 2, 3]", false,
            "expect([1,2,3]).to.not.containOnly([1,2,3])",
            "not to contain only [1, 2, 3]", "[1, 2, 3]", true),
        SnapshotCase("startWith", `expect("hello").to.startWith("xyz")`,
            "to start with xyz", "hello", false,
            `expect("hello").to.not.startWith("hel")`,
            "not to start with hel", "hello", true),
        SnapshotCase("endWith", `expect("hello").to.endWith("xyz")`,
            "to end with xyz", "hello", false,
            `expect("hello").to.not.endWith("llo")`,
            "not to end with llo", "hello", true),
        SnapshotCase("beNull", "Object obj = new Object(); expect(obj).to.beNull",
            "null", "object.Object", false,
            "Object obj = null; expect(obj).to.not.beNull",
            "not null", "object.Object", true),
        SnapshotCase("approximately (scalar)", "expect(0.5).to.be.approximately(0.3, 0.1)",
            "0.3±0.1", "0.5", false,
            "expect(0.351).to.not.be.approximately(0.35, 0.01)",
            "0.35±0.01", "0.351", true),
        SnapshotCase("approximately (array)", "expect([0.5]).to.be.approximately([0.3], 0.1)",
            "[0.3±0.1]", "[0.5]", false,
            "expect([0.35]).to.not.be.approximately([0.35], 0.01)",
            "[0.35±0.01]", "[0.35]", true),
        SnapshotCase("greaterThan", "expect(3).to.be.greaterThan(5)",
            "greater than 5", "3", false,
            "expect(5).to.not.be.greaterThan(3)",
            "less than or equal to 3", "5", true),
        SnapshotCase("lessThan", "expect(5).to.be.lessThan(3)",
            "less than 3", "5", false,
            "expect(3).to.not.be.lessThan(5)",
            "greater than or equal to 5", "3", true),
        SnapshotCase("between", "expect(10).to.be.between(1, 5)",
            "a value inside (1, 5) interval", "10", false,
            "expect(3).to.not.be.between(1, 5)",
            "a value outside (1, 5) interval", "3", true),
        SnapshotCase("greaterOrEqualTo", "expect(3).to.be.greaterOrEqualTo(5)",
            "greater or equal than 5", "3", false,
            "expect(5).to.not.be.greaterOrEqualTo(3)",
            "less than 3", "5", true),
        SnapshotCase("lessOrEqualTo", "expect(5).to.be.lessOrEqualTo(3)",
            "less or equal to 3", "5", false,
            "expect(3).to.not.be.lessOrEqualTo(5)",
            "greater than 5", "3", true),
        SnapshotCase("instanceOf", "expect(new Object()).to.be.instanceOf!Exception",
            "typeof object.Exception", "typeof object.Object", false,
            "expect(new Exception(\"test\")).to.not.be.instanceOf!Object",
            "not typeof object.Object", "typeof object.Exception", true),
    ]) {{
        output.put("## " ~ c.name ~ "\n\n");

        output.put("### Positive fail\n\n");
        output.put("```d\n" ~ c.code ~ ";\n```\n\n");
        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
        output.put("```\n");
        output.put(posEval.toString());
        output.put("```\n\n");

        // Verify positive case
        assert(posEval.result.expected == c.posExpected,
            c.name ~ " positive expected: got '" ~ posEval.result.expected ~ "' but expected '" ~ c.posExpected ~ "'");
        assert(posEval.result.actual == c.posActual,
            c.name ~ " positive actual: got '" ~ posEval.result.actual ~ "' but expected '" ~ c.posActual ~ "'");
        assert(posEval.result.negated == c.posNegated,
            c.name ~ " positive negated flag mismatch");

        output.put("### Negated fail\n\n");
        output.put("```d\n" ~ c.negCode ~ ";\n```\n\n");
        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
        output.put("```\n");
        output.put(negEval.toString());
        output.put("```\n\n");

        // Verify negated case
        assert(negEval.result.expected == c.negExpected,
            c.name ~ " negated expected: got '" ~ negEval.result.expected ~ "' but expected '" ~ c.negExpected ~ "'");
        assert(negEval.result.actual == c.negActual,
            c.name ~ " negated actual: got '" ~ negEval.result.actual ~ "' but expected '" ~ c.negActual ~ "'");
        assert(negEval.result.negated == c.negNegated,
            c.name ~ " negated flag mismatch");
    }}

    std.file.write("operation-snapshots.md", output.data);
    writeln("Snapshots written to operation-snapshots.md");
}
