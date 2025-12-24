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
  import std.algorithm : canFind;
  import std.regex;
}

/// Normalizes snapshot output by removing unstable elements like line numbers and object addresses.
string normalizeSnapshot(string input) {
  auto lineNormalized = replaceAll(input, regex(r"\.d:\d+"), ".d:XXX");
  auto addressNormalized = replaceAll(lineNormalized, regex(r"\(\d{7,}\)"), "(XXX)");
  return addressNormalized;
}

/// Snapshot test case definition.
struct SnapshotTest {
  string name;
  string posCode;
  string negCode;
  string expectedPos;
  string expectedNeg;
  string actualPos;
  string actualNeg;
}

/// All snapshot test definitions.
immutable snapshotTests = [
  SnapshotTest("equal scalar",
    "expect(5).to.equal(3)", "expect(5).to.not.equal(5)",
    "3", "not 5", "5", "5"),
  SnapshotTest("equal string",
    `expect("hello").to.equal("world")`, `expect("hello").to.not.equal("hello")`,
    "world", "not hello", "hello", "hello"),
  SnapshotTest("equal array",
    "expect([1,2,3]).to.equal([1,2,4])", "expect([1,2,3]).to.not.equal([1,2,3])",
    "[1, 2, 4]", "not [1, 2, 3]", "[1, 2, 3]", "[1, 2, 3]"),
  SnapshotTest("contain string",
    `expect("hello").to.contain("xyz")`, `expect("hello").to.not.contain("ell")`,
    "to contain xyz", "not to contain ell", "hello", "hello"),
  SnapshotTest("contain array",
    "expect([1,2,3]).to.contain(5)", "expect([1,2,3]).to.not.contain(2)",
    "to contain 5", "not to contain 2", "[1, 2, 3]", "[1, 2, 3]"),
  SnapshotTest("containOnly",
    "expect([1,2,3]).to.containOnly([1,2])", "expect([1,2,3]).to.not.containOnly([1,2,3])",
    "to contain only [1, 2]", "not to contain only [1, 2, 3]", "[1, 2, 3]", "[1, 2, 3]"),
  SnapshotTest("startWith",
    `expect("hello").to.startWith("xyz")`, `expect("hello").to.not.startWith("hel")`,
    "to start with xyz", "not to start with hel", "hello", "hello"),
  SnapshotTest("endWith",
    `expect("hello").to.endWith("xyz")`, `expect("hello").to.not.endWith("llo")`,
    "to end with xyz", "not to end with llo", "hello", "hello"),
  SnapshotTest("approximately scalar",
    "expect(0.5).to.be.approximately(0.3, 0.1)", "expect(0.351).to.not.be.approximately(0.35, 0.01)",
    "0.3±0.1", "0.35±0.01", "0.5", "0.351"),
  SnapshotTest("approximately array",
    "expect([0.5]).to.be.approximately([0.3], 0.1)", "expect([0.35]).to.not.be.approximately([0.35], 0.01)",
    "[0.3±0.1]", "[0.35±0.01]", "[0.5]", "[0.35]"),
  SnapshotTest("greaterThan",
    "expect(3).to.be.greaterThan(5)", "expect(5).to.not.be.greaterThan(3)",
    "greater than 5", "less than or equal to 3", "3", "5"),
  SnapshotTest("lessThan",
    "expect(5).to.be.lessThan(3)", "expect(3).to.not.be.lessThan(5)",
    "less than 3", "greater than or equal to 5", "5", "3"),
  SnapshotTest("between",
    "expect(10).to.be.between(1, 5)", "expect(3).to.not.be.between(1, 5)",
    "a value inside (1, 5) interval", "a value outside (1, 5) interval", "10", "3"),
  SnapshotTest("greaterOrEqualTo",
    "expect(3).to.be.greaterOrEqualTo(5)", "expect(5).to.not.be.greaterOrEqualTo(3)",
    "greater or equal than 5", "less than 3", "3", "5"),
  SnapshotTest("lessOrEqualTo",
    "expect(5).to.be.lessOrEqualTo(3)", "expect(3).to.not.be.lessOrEqualTo(5)",
    "less or equal to 3", "greater than 5", "5", "3"),
  SnapshotTest("instanceOf",
    "expect(new Object()).to.be.instanceOf!Exception",
    `expect(new Exception("test")).to.not.be.instanceOf!Object`,
    "typeof object.Exception", "not typeof object.Object",
    "typeof object.Object", "typeof object.Exception"),
  SnapshotTest("beNull",
    "expect(new Object()).to.beNull", "expect(null).to.not.beNull",
    "null", "not null", "object.Object", "null"),
];

/// Runs a positive snapshot test in its own stack frame.
void runPositiveTest(string code, string expectedPos, string actualPos)() {
  import std.conv : to;

  mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
  assert(eval.result.expected[] == expectedPos,
    "Expected '" ~ expectedPos ~ "' but got '" ~ eval.result.expected[].to!string ~ "'");
  assert(eval.result.actual[] == actualPos,
    "Actual expected '" ~ actualPos ~ "' but got '" ~ eval.result.actual[].to!string ~ "'");
  assert(eval.result.negated == false);
}

/// Runs a negated snapshot test in its own stack frame.
void runNegatedTest(string code, string expectedNeg, string actualNeg)() {
  import std.conv : to;

  mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
  assert(eval.result.expected[] == expectedNeg,
    "Neg expected '" ~ expectedNeg ~ "' but got '" ~ eval.result.expected[].to!string ~ "'");
  assert(eval.result.actual[] == actualNeg,
    "Neg actual expected '" ~ actualNeg ~ "' but got '" ~ eval.result.actual[].to!string ~ "'");
  assert(eval.result.negated == true);
}

/// Generates a snapshot test for a given test case.
mixin template GenerateSnapshotTest(size_t idx) {
  enum test = snapshotTests[idx];

  @("snapshot: " ~ test.name)
  unittest {
    runPositiveTest!(test.posCode, test.expectedPos, test.actualPos)();
    runNegatedTest!(test.negCode, test.expectedNeg, test.actualNeg)();
  }
}

// Generate all snapshot tests
static foreach (i; 0 .. snapshotTests.length) {
  mixin GenerateSnapshotTest!i;
}

// Special tests for multiline strings (require custom assertions)
@("snapshot: equal multiline string with line change")
unittest {
  string actual = "line1\nline2\nline3\nline4";
  string expected = "line1\nchanged\nline3\nline4";

  auto posEval = recordEvaluation({ expect(actual).to.equal(expected); });
  assert(posEval.result.expected[].canFind("1: line1"));
  assert(posEval.result.expected[].canFind("2: changed"));
  assert(posEval.result.actual[].canFind("1: line1"));
  assert(posEval.result.actual[].canFind("2: line2"));
  assert(posEval.result.negated == false);
  assert(posEval.toString().canFind("Diff:"));
}

@("snapshot: equal multiline string with char change")
unittest {
  string actual = "function test() {\n  return value;\n}";
  string expected = "function test() {\n  return values;\n}";

  auto posEval = recordEvaluation({ expect(actual).to.equal(expected); });
  assert(posEval.result.expected[].canFind("1: function test()"));
  assert(posEval.result.expected[].canFind("3: }"));
  assert(posEval.result.actual[].canFind("1: function test()"));
  assert(posEval.result.negated == false);
  assert(posEval.toString().canFind("Diff:"));
}

