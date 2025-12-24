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
/// This allows comparing snapshots even when source code moves or objects have different addresses.
string normalizeSnapshot(string input) {
  // Replace source file line numbers: snapshot.d:123 -> snapshot.d:XXX
  auto lineNormalized = replaceAll(input, regex(r"\.d:\d+"), ".d:XXX");

  // Replace object addresses: Object(1234567890) -> Object(XXX)
  auto addressNormalized = replaceAll(lineNormalized, regex(r"\(\d{7,}\)"), "(XXX)");

  return addressNormalized;
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
  assert(posEval.toString().canFind("Diff:"), "Diff section should be present");
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
  assert(posEval.toString().canFind("Diff:"), "Diff section should be present");
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

/// Generates snapshot content for all operations.
/// Returns the content as a string rather than writing to a file.
version (unittest) string generateSnapshotContent() {
  auto output = appender!string();

  output.put("# Operation Snapshots\n\n");
  output.put("This file contains snapshots of all assertion operations with both positive and negated failure variants.\n\n");

  void writeSection(string name, string posCode, ref Evaluation posEval, string negCode, ref Evaluation negEval) {
    output.put("## " ~ name ~ "\n\n");

    output.put("### Positive fail\n\n");
    output.put("```d\n" ~ posCode ~ ";\n```\n\n");
    output.put("```\n");
    output.put(posEval.toString());
    output.put("```\n\n");

    output.put("### Negated fail\n\n");
    output.put("```d\n" ~ negCode ~ ";\n```\n\n");
    output.put("```\n");
    output.put(negEval.toString());
    output.put("```\n\n");
  }

  void writeEqualScalar() {
    auto posEval = recordEvaluation({ expect(5).to.equal(3); });
    auto negEval = recordEvaluation({ expect(5).to.not.equal(5); });
    writeSection("equal (scalar)",
      "expect(5).to.equal(3)", posEval,
      "expect(5).to.not.equal(5)", negEval);
  }
  writeEqualScalar();

  void writeEqualString() {
    auto posEval = recordEvaluation({ expect("hello").to.equal("world"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.equal("hello"); });
    writeSection("equal (string)",
      `expect("hello").to.equal("world")`, posEval,
      `expect("hello").to.not.equal("hello")`, negEval);
  }
  writeEqualString();

  void writeMultilineLineChange() {
    string actualMultiline = "line1\nline2\nline3\nline4";
    string expectedMultiline = "line1\nchanged\nline3\nline4";
    string sameMultiline = "line1\nline2\nline3\nline4";

    output.put("## equal (multiline string - line change)\n\n");
    output.put("### Positive fail\n\n");
    output.put("```d\n");
    output.put("string actual = \"line1\\nline2\\nline3\\nline4\";\n");
    output.put("string expected = \"line1\\nchanged\\nline3\\nline4\";\n");
    output.put("expect(actual).to.equal(expected);\n");
    output.put("```\n\n");
    output.put("```\n");
    output.put(recordEvaluation({ expect(actualMultiline).to.equal(expectedMultiline); }).toString());
    output.put("```\n\n");

    output.put("### Negated fail\n\n");
    output.put("```d\n");
    output.put("string value = \"line1\\nline2\\nline3\\nline4\";\n");
    output.put("expect(value).to.not.equal(value);\n");
    output.put("```\n\n");
    output.put("```\n");
    output.put(recordEvaluation({ expect(sameMultiline).to.not.equal(sameMultiline); }).toString());
    output.put("```\n\n");
  }
  writeMultilineLineChange();

  void writeMultilineCharChange() {
    string actualCharDiff = "function test() {\n  return value;\n}";
    string expectedCharDiff = "function test() {\n  return values;\n}";

    output.put("## equal (multiline string - char change)\n\n");
    output.put("### Positive fail\n\n");
    output.put("```d\n");
    output.put("string actual = \"function test() {\\n  return value;\\n}\";\n");
    output.put("string expected = \"function test() {\\n  return values;\\n}\";\n");
    output.put("expect(actual).to.equal(expected);\n");
    output.put("```\n\n");
    output.put("```\n");
    output.put(recordEvaluation({ expect(actualCharDiff).to.equal(expectedCharDiff); }).toString());
    output.put("```\n\n");
  }
  writeMultilineCharChange();

  void writeEqualArray() {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.equal([1,2,4]); });
    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.equal([1,2,3]); });
    writeSection("equal (array)",
      "expect([1,2,3]).to.equal([1,2,4])", posEval,
      "expect([1,2,3]).to.not.equal([1,2,3])", negEval);
  }
  writeEqualArray();

  void writeContainString() {
    auto posEval = recordEvaluation({ expect("hello").to.contain("xyz"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.contain("ell"); });
    writeSection("contain (string)",
      `expect("hello").to.contain("xyz")`, posEval,
      `expect("hello").to.not.contain("ell")`, negEval);
  }
  writeContainString();

  void writeContainArray() {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.contain(5); });
    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.contain(2); });
    writeSection("contain (array)",
      "expect([1,2,3]).to.contain(5)", posEval,
      "expect([1,2,3]).to.not.contain(2)", negEval);
  }
  writeContainArray();

  void writeContainOnly() {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.containOnly([1,2]); });
    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.containOnly([1,2,3]); });
    writeSection("containOnly",
      "expect([1,2,3]).to.containOnly([1,2])", posEval,
      "expect([1,2,3]).to.not.containOnly([1,2,3])", negEval);
  }
  writeContainOnly();

  void writeStartWith() {
    auto posEval = recordEvaluation({ expect("hello").to.startWith("xyz"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.startWith("hel"); });
    writeSection("startWith",
      `expect("hello").to.startWith("xyz")`, posEval,
      `expect("hello").to.not.startWith("hel")`, negEval);
  }
  writeStartWith();

  void writeEndWith() {
    auto posEval = recordEvaluation({ expect("hello").to.endWith("xyz"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.endWith("llo"); });
    writeSection("endWith",
      `expect("hello").to.endWith("xyz")`, posEval,
      `expect("hello").to.not.endWith("llo")`, negEval);
  }
  writeEndWith();

  void writeApproximatelyScalar() {
    auto posEval = recordEvaluation({ expect(0.5).to.be.approximately(0.3, 0.1); });
    auto negEval = recordEvaluation({ expect(0.351).to.not.be.approximately(0.35, 0.01); });
    writeSection("approximately (scalar)",
      "expect(0.5).to.be.approximately(0.3, 0.1)", posEval,
      "expect(0.351).to.not.be.approximately(0.35, 0.01)", negEval);
  }
  writeApproximatelyScalar();

  void writeApproximatelyArray() {
    auto posEval = recordEvaluation({ expect([0.5]).to.be.approximately([0.3], 0.1); });
    auto negEval = recordEvaluation({ expect([0.35]).to.not.be.approximately([0.35], 0.01); });
    writeSection("approximately (array)",
      "expect([0.5]).to.be.approximately([0.3], 0.1)", posEval,
      "expect([0.35]).to.not.be.approximately([0.35], 0.01)", negEval);
  }
  writeApproximatelyArray();

  void writeGreaterThan() {
    auto posEval = recordEvaluation({ expect(3).to.be.greaterThan(5); });
    auto negEval = recordEvaluation({ expect(5).to.not.be.greaterThan(3); });
    writeSection("greaterThan",
      "expect(3).to.be.greaterThan(5)", posEval,
      "expect(5).to.not.be.greaterThan(3)", negEval);
  }
  writeGreaterThan();

  void writeLessThan() {
    auto posEval = recordEvaluation({ expect(5).to.be.lessThan(3); });
    auto negEval = recordEvaluation({ expect(3).to.not.be.lessThan(5); });
    writeSection("lessThan",
      "expect(5).to.be.lessThan(3)", posEval,
      "expect(3).to.not.be.lessThan(5)", negEval);
  }
  writeLessThan();

  void writeBetween() {
    auto posEval = recordEvaluation({ expect(10).to.be.between(1, 5); });
    auto negEval = recordEvaluation({ expect(3).to.not.be.between(1, 5); });
    writeSection("between",
      "expect(10).to.be.between(1, 5)", posEval,
      "expect(3).to.not.be.between(1, 5)", negEval);
  }
  writeBetween();

  void writeGreaterOrEqualTo() {
    auto posEval = recordEvaluation({ expect(3).to.be.greaterOrEqualTo(5); });
    auto negEval = recordEvaluation({ expect(5).to.not.be.greaterOrEqualTo(3); });
    writeSection("greaterOrEqualTo",
      "expect(3).to.be.greaterOrEqualTo(5)", posEval,
      "expect(5).to.not.be.greaterOrEqualTo(3)", negEval);
  }
  writeGreaterOrEqualTo();

  void writeLessOrEqualTo() {
    auto posEval = recordEvaluation({ expect(5).to.be.lessOrEqualTo(3); });
    auto negEval = recordEvaluation({ expect(3).to.not.be.lessOrEqualTo(5); });
    writeSection("lessOrEqualTo",
      "expect(5).to.be.lessOrEqualTo(3)", posEval,
      "expect(3).to.not.be.lessOrEqualTo(5)", negEval);
  }
  writeLessOrEqualTo();

  void writeInstanceOf() {
    auto posEval = recordEvaluation({ expect(new Object()).to.be.instanceOf!Exception; });
    auto negEval = recordEvaluation({ expect(new Exception("test")).to.not.be.instanceOf!Object; });
    writeSection("instanceOf",
      "expect(new Object()).to.be.instanceOf!Exception", posEval,
      `expect(new Exception("test")).to.not.be.instanceOf!Object`, negEval);
  }
  writeInstanceOf();

  void writeBeNull() {
    Object obj = new Object();
    auto posEval = recordEvaluation({ expect(obj).to.beNull; });

    Object nullObj = null;
    auto negEval = recordEvaluation({ expect(nullObj).to.not.beNull; });

    writeSection("beNull",
      "expect(new Object()).to.beNull", posEval,
      "expect(null).to.not.beNull", negEval);
  }
  writeBeNull();

  return output.data;
}

@("snapshot: verify operation-snapshots.md matches current output")
unittest {
  string expectedFile = "operation-snapshots.md";
  string actualContent = generateSnapshotContent();

  if (!exists(expectedFile)) {
    std.file.write(expectedFile, actualContent);
    return;
  }

  string expected = normalizeSnapshot(readText(expectedFile));
  string actual = normalizeSnapshot(actualContent);

  expect(actual).to.equal(expected);
  std.file.write(expectedFile, actualContent);
}

// This function generates operation-snapshots.md documentation.
// It's not a unittest because the Evaluation struct is very large (~30KB per instance)
// and having 30+ evaluations in one function exceeds the worker thread stack size.
// Run manually with: dub run --config=updateDocs
version(UpdateDocs) void generateOperationSnapshots() {
  import fluentasserts.core.evaluation.eval : Evaluation;

  auto output = appender!string();

  output.put("# Operation Snapshots\n\n");
  output.put("This file contains snapshots of all assertion operations with both positive and negated failure variants.\n\n");

  void writeSection(string name, string posCode, ref Evaluation posEval, string negCode, ref Evaluation negEval) {
    output.put("## " ~ name ~ "\n\n");

    output.put("### Positive fail\n\n");
    output.put("```d\n" ~ posCode ~ ";\n```\n\n");
    output.put("```\n");
    output.put(posEval.toString());
    output.put("```\n\n");

    output.put("### Negated fail\n\n");
    output.put("```d\n" ~ negCode ~ ";\n```\n\n");
    output.put("```\n");
    output.put(negEval.toString());
    output.put("```\n\n");
  }

  void writeEqualScalar() {
    auto posEval = recordEvaluation({ expect(5).to.equal(3); });
    auto negEval = recordEvaluation({ expect(5).to.not.equal(5); });
    writeSection("equal (scalar)",
      "expect(5).to.equal(3)", posEval,
      "expect(5).to.not.equal(5)", negEval);
  }
  writeEqualScalar();

  void writeEqualString() {
    auto posEval = recordEvaluation({ expect("hello").to.equal("world"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.equal("hello"); });
    writeSection("equal (string)",
      `expect("hello").to.equal("world")`, posEval,
      `expect("hello").to.not.equal("hello")`, negEval);
  }
  writeEqualString();

  // Multiline string comparison with diff - whole line change
  void writeMultilineLineChange() {
    string actualMultiline = "line1\nline2\nline3\nline4";
    string expectedMultiline = "line1\nchanged\nline3\nline4";
    string sameMultiline = "line1\nline2\nline3\nline4";

    output.put("## equal (multiline string - line change)\n\n");
    output.put("### Positive fail\n\n");
    output.put("```d\n");
    output.put("string actual = \"line1\\nline2\\nline3\\nline4\";\n");
    output.put("string expected = \"line1\\nchanged\\nline3\\nline4\";\n");
    output.put("expect(actual).to.equal(expected);\n");
    output.put("```\n\n");
    output.put("```\n");
    output.put(recordEvaluation({ expect(actualMultiline).to.equal(expectedMultiline); }).toString());
    output.put("```\n\n");

    output.put("### Negated fail\n\n");
    output.put("```d\n");
    output.put("string value = \"line1\\nline2\\nline3\\nline4\";\n");
    output.put("expect(value).to.not.equal(value);\n");
    output.put("```\n\n");
    output.put("```\n");
    output.put(recordEvaluation({ expect(sameMultiline).to.not.equal(sameMultiline); }).toString());
    output.put("```\n\n");
  }
  writeMultilineLineChange();

  // Multiline string comparison with diff - small char change
  void writeMultilineCharChange() {
    string actualCharDiff = "function test() {\n  return value;\n}";
    string expectedCharDiff = "function test() {\n  return values;\n}";

    output.put("## equal (multiline string - char change)\n\n");
    output.put("### Positive fail\n\n");
    output.put("```d\n");
    output.put("string actual = \"function test() {\\n  return value;\\n}\";\n");
    output.put("string expected = \"function test() {\\n  return values;\\n}\";\n");
    output.put("expect(actual).to.equal(expected);\n");
    output.put("```\n\n");
    output.put("```\n");
    output.put(recordEvaluation({ expect(actualCharDiff).to.equal(expectedCharDiff); }).toString());
    output.put("```\n\n");
  }
  writeMultilineCharChange();

  void writeEqualArray() {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.equal([1,2,4]); });
    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.equal([1,2,3]); });
    writeSection("equal (array)",
      "expect([1,2,3]).to.equal([1,2,4])", posEval,
      "expect([1,2,3]).to.not.equal([1,2,3])", negEval);
  }
  writeEqualArray();

  void writeContainString() {
    auto posEval = recordEvaluation({ expect("hello").to.contain("xyz"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.contain("ell"); });
    writeSection("contain (string)",
      `expect("hello").to.contain("xyz")`, posEval,
      `expect("hello").to.not.contain("ell")`, negEval);
  }
  writeContainString();

  void writeContainArray() {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.contain(5); });
    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.contain(2); });
    writeSection("contain (array)",
      "expect([1,2,3]).to.contain(5)", posEval,
      "expect([1,2,3]).to.not.contain(2)", negEval);
  }
  writeContainArray();

  void writeContainOnly() {
    auto posEval = recordEvaluation({ expect([1,2,3]).to.containOnly([1,2]); });
    auto negEval = recordEvaluation({ expect([1,2,3]).to.not.containOnly([1,2,3]); });
    writeSection("containOnly",
      "expect([1,2,3]).to.containOnly([1,2])", posEval,
      "expect([1,2,3]).to.not.containOnly([1,2,3])", negEval);
  }
  writeContainOnly();

  void writeStartWith() {
    auto posEval = recordEvaluation({ expect("hello").to.startWith("xyz"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.startWith("hel"); });
    writeSection("startWith",
      `expect("hello").to.startWith("xyz")`, posEval,
      `expect("hello").to.not.startWith("hel")`, negEval);
  }
  writeStartWith();

  void writeEndWith() {
    auto posEval = recordEvaluation({ expect("hello").to.endWith("xyz"); });
    auto negEval = recordEvaluation({ expect("hello").to.not.endWith("llo"); });
    writeSection("endWith",
      `expect("hello").to.endWith("xyz")`, posEval,
      `expect("hello").to.not.endWith("llo")`, negEval);
  }
  writeEndWith();

  void writeApproximatelyScalar() {
    auto posEval = recordEvaluation({ expect(0.5).to.be.approximately(0.3, 0.1); });
    auto negEval = recordEvaluation({ expect(0.351).to.not.be.approximately(0.35, 0.01); });
    writeSection("approximately (scalar)",
      "expect(0.5).to.be.approximately(0.3, 0.1)", posEval,
      "expect(0.351).to.not.be.approximately(0.35, 0.01)", negEval);
  }
  writeApproximatelyScalar();

  void writeApproximatelyArray() {
    auto posEval = recordEvaluation({ expect([0.5]).to.be.approximately([0.3], 0.1); });
    auto negEval = recordEvaluation({ expect([0.35]).to.not.be.approximately([0.35], 0.01); });
    writeSection("approximately (array)",
      "expect([0.5]).to.be.approximately([0.3], 0.1)", posEval,
      "expect([0.35]).to.not.be.approximately([0.35], 0.01)", negEval);
  }
  writeApproximatelyArray();

  void writeGreaterThan() {
    auto posEval = recordEvaluation({ expect(3).to.be.greaterThan(5); });
    auto negEval = recordEvaluation({ expect(5).to.not.be.greaterThan(3); });
    writeSection("greaterThan",
      "expect(3).to.be.greaterThan(5)", posEval,
      "expect(5).to.not.be.greaterThan(3)", negEval);
  }
  writeGreaterThan();

  void writeLessThan() {
    auto posEval = recordEvaluation({ expect(5).to.be.lessThan(3); });
    auto negEval = recordEvaluation({ expect(3).to.not.be.lessThan(5); });
    writeSection("lessThan",
      "expect(5).to.be.lessThan(3)", posEval,
      "expect(3).to.not.be.lessThan(5)", negEval);
  }
  writeLessThan();

  void writeBetween() {
    auto posEval = recordEvaluation({ expect(10).to.be.between(1, 5); });
    auto negEval = recordEvaluation({ expect(3).to.not.be.between(1, 5); });
    writeSection("between",
      "expect(10).to.be.between(1, 5)", posEval,
      "expect(3).to.not.be.between(1, 5)", negEval);
  }
  writeBetween();

  void writeGreaterOrEqualTo() {
    auto posEval = recordEvaluation({ expect(3).to.be.greaterOrEqualTo(5); });
    auto negEval = recordEvaluation({ expect(5).to.not.be.greaterOrEqualTo(3); });
    writeSection("greaterOrEqualTo",
      "expect(3).to.be.greaterOrEqualTo(5)", posEval,
      "expect(5).to.not.be.greaterOrEqualTo(3)", negEval);
  }
  writeGreaterOrEqualTo();

  void writeLessOrEqualTo() {
    auto posEval = recordEvaluation({ expect(5).to.be.lessOrEqualTo(3); });
    auto negEval = recordEvaluation({ expect(3).to.not.be.lessOrEqualTo(5); });
    writeSection("lessOrEqualTo",
      "expect(5).to.be.lessOrEqualTo(3)", posEval,
      "expect(3).to.not.be.lessOrEqualTo(5)", negEval);
  }
  writeLessOrEqualTo();

  void writeInstanceOf() {
    auto posEval = recordEvaluation({ expect(new Object()).to.be.instanceOf!Exception; });
    auto negEval = recordEvaluation({ expect(new Exception("test")).to.not.be.instanceOf!Object; });
    writeSection("instanceOf",
      "expect(new Object()).to.be.instanceOf!Exception", posEval,
      `expect(new Exception("test")).to.not.be.instanceOf!Object`, negEval);
  }
  writeInstanceOf();

  std.file.write("operation-snapshots.md", output.data);
  writeln("Snapshots written to operation-snapshots.md");
}

