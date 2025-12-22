module fluentasserts.operations.comparison.approximately;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.core.memory.heapequable : HeapEquableValue;
import fluentasserts.core.listcomparison;
import fluentasserts.results.serializers.string_registry;
import fluentasserts.results.serializers.helpers : parseList, cleanString;
import fluentasserts.operations.string.contain;
import fluentasserts.core.toNumeric;
import fluentasserts.core.memory.heapstring : HeapString, toHeapString;

import fluentasserts.core.lifecycle;

import std.algorithm;
import std.array;
import std.conv;
import std.math;
import std.meta : AliasSeq;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.meta;
  import std.string;
}

static immutable approximatelyDescription = "Asserts that the target is a number that's within a given +/- `delta` range of the given number expected. However, it's often best to assert that the target is equal to its expected value.";

/// Asserts that a numeric value is within a given delta range of the expected value.
void approximately(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addValue("±");
  evaluation.result.addValue(evaluation.expectedValue.meta["1"]);

  auto currentParsed = toNumeric!real(evaluation.currentValue.strValue);
  auto expectedParsed = toNumeric!real(evaluation.expectedValue.strValue);
  auto deltaParsed = toNumeric!real(toHeapString(evaluation.expectedValue.meta["1"]));

  if (!currentParsed.success || !expectedParsed.success || !deltaParsed.success) {
    evaluation.conversionError("numeric");
    return;
  }

  real current = currentParsed.value;
  real expected = expectedParsed.value;
  real delta = deltaParsed.value;

  string strExpected = evaluation.expectedValue.strValue[].idup ~ "±" ~ evaluation.expectedValue.meta["1"].idup;
  string strCurrent = evaluation.currentValue.strValue[].idup;

  auto result = isClose(current, expected, 0, delta);

  if(evaluation.isNegated) {
    result = !result;
  }

  if(result) {
    return;
  }

  if(evaluation.currentValue.typeName != "bool") {
    evaluation.result.addText(" ");
    evaluation.result.addValue(strCurrent);

    if(evaluation.isNegated) {
      evaluation.result.addText(" is approximately ");
    } else {
      evaluation.result.addText(" is not approximately ");
    }

    evaluation.result.addValue(strExpected);
  }

  evaluation.result.expected = strExpected;
  evaluation.result.actual = strCurrent;
  evaluation.result.negated = evaluation.isNegated;
}

/// Asserts that each element in a numeric list is within a given delta range of its expected value.
void approximatelyList(ref Evaluation evaluation) @trusted nothrow {
  evaluation.result.addValue("±" ~ evaluation.expectedValue.meta["1"].idup);

  double maxRelDiff;
  real[] testData;
  real[] expectedPieces;

  try {
    auto currentParsed = evaluation.currentValue.strValue[].parseList;
    cleanString(currentParsed);
    auto expectedParsed = evaluation.expectedValue.strValue[].parseList;
    cleanString(expectedParsed);

    testData = new real[currentParsed.length];
    foreach (i; 0 .. currentParsed.length) {
      testData[i] = currentParsed[i][].to!real;
    }

    expectedPieces = new real[expectedParsed.length];
    foreach (i; 0 .. expectedParsed.length) {
      expectedPieces[i] = expectedParsed[i][].to!real;
    }

    maxRelDiff = evaluation.expectedValue.meta["1"].idup.to!double;
  } catch (Exception e) {
    evaluation.conversionError("numeric list");
    return;
  }

  auto comparison = ListComparison!real(testData, expectedPieces, maxRelDiff);

  auto missing = comparison.missing;
  auto extra = comparison.extra;
  auto common = comparison.common;

  bool allEqual = testData.length == expectedPieces.length;

  if(allEqual) {
    foreach(i; 0..testData.length) {
      allEqual = allEqual && isClose(testData[i], expectedPieces[i], 0, maxRelDiff) && true;
    }
  }

  import std.exception : assumeWontThrow;

  string strExpected;
  string strMissing;

  if(maxRelDiff == 0) {
    strExpected = evaluation.expectedValue.strValue[].idup;
    strMissing = missing.length == 0 ? "" : assumeWontThrow(missing.to!string);
  } else {
    strMissing = "[" ~ assumeWontThrow(missing.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ")) ~ "]";
    strExpected = "[" ~ assumeWontThrow(expectedPieces.map!(a => a.to!string ~ "±" ~ maxRelDiff.to!string).join(", ")) ~ "]";
  }

  if(!evaluation.isNegated) {
    if(!allEqual) {
      evaluation.result.expected = strExpected;
      evaluation.result.actual = evaluation.currentValue.strValue[];

      foreach(e; extra) {
        evaluation.result.extra ~= assumeWontThrow(e.to!string ~ "±" ~ maxRelDiff.to!string);
      }

      foreach(m; missing) {
        evaluation.result.missing ~= assumeWontThrow(m.to!string ~ "±" ~ maxRelDiff.to!string);
      }
    }
  } else {
    if(allEqual) {
      evaluation.result.expected = strExpected;
      evaluation.result.actual = evaluation.currentValue.strValue[];
      evaluation.result.negated = true;
    }
  }
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias FPTypes = AliasSeq!(float, double, real);

static foreach (Type; FPTypes) {
  @("floats casted to " ~ Type.stringof ~ " checks valid values")
  unittest {
    Type testValue = cast(Type) 10f / 3f;
    testValue.should.be.approximately(3, 0.34);
    [testValue].should.be.approximately([3], 0.34);
  }

  @("floats casted to " ~ Type.stringof ~ " checks invalid values")
  unittest {
    Type testValue = cast(Type) 10f / 3f;
    testValue.should.not.be.approximately(3, 0.24);
    [testValue].should.not.be.approximately([3], 0.24);
  }

  @("floats casted to " ~ Type.stringof ~ " empty string approximately 3 reports error with expected and actual")
  unittest {
    auto evaluation = ({
      "".should.be.approximately(3, 0.34);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("valid numeric values");
    expect(evaluation.result.actual[]).to.equal("conversion error");
  }

  @(Type.stringof ~ " values approximately compares two numbers")
  unittest {
    Type testValue = cast(Type) 0.351;
    expect(testValue).to.be.approximately(0.35, 0.01);
  }

  @(Type.stringof ~ " values checks approximately with delta 0.00001")
  unittest {
    Type testValue = cast(Type) 0.351;
    expect(testValue).to.not.be.approximately(0.35, 0.00001);
  }

  @(Type.stringof ~ " values checks approximately with delta 0.0005")
  unittest {
    Type testValue = cast(Type) 0.351;
    expect(testValue).to.not.be.approximately(0.35, 0.0005);
  }

  @(Type.stringof ~ " 0.351 approximately 0.35 with delta 0.0001 reports error with expected and actual")
  unittest {
    Type testValue = cast(Type) 0.351;

    auto evaluation = ({
      expect(testValue).to.be.approximately(0.35, 0.0001);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("0.35±0.0001");
    expect(evaluation.result.actual[]).to.equal("0.351");
  }

  @(Type.stringof ~ " 0.351 not approximately 0.351 with delta 0.0001 reports error with expected and actual")
  unittest {
    Type testValue = cast(Type) 0.351;

    auto evaluation = ({
      expect(testValue).to.not.be.approximately(testValue, 0.0001);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(testValue.to!string ~ "±0.0001");
    expect(evaluation.result.negated).to.equal(true);
  }

  @(Type.stringof ~ " lists approximately compares two lists")
  unittest {
    Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
    expect(testValues).to.be.approximately([0.35, 0.50, 0.34], 0.01);
  }

  @(Type.stringof ~ " lists with range 0.00001 compares two lists that are not equal")
  unittest {
    Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
    expect(testValues).to.not.be.approximately([0.35, 0.50, 0.34], 0.00001);
  }

  @(Type.stringof ~ " lists with range 0.0001 compares two lists that are not equal")
  unittest {
    Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
    expect(testValues).to.not.be.approximately([0.35, 0.50, 0.34], 0.0001);
  }

  @(Type.stringof ~ " lists with range 0.001 compares two lists with different lengths")
  unittest {
    Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
    expect(testValues).to.not.be.approximately([0.35, 0.50], 0.001);
  }

  @(Type.stringof ~ " list approximately with delta 0.0001 reports error with expected and missing")
  unittest {
    Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];

    auto evaluation = ({
      expect(testValues).to.be.approximately([0.35, 0.50, 0.34], 0.0001);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
    expect(evaluation.result.missing.length).to.equal(2);
  }

  @(Type.stringof ~ " list not approximately with delta 0.0001 reports error with expected and negated")
  unittest {
    Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];

    auto evaluation = ({
      expect(testValues).to.not.be.approximately(testValues, 0.0001);
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal("[0.35±0.0001, 0.501±0.0001, 0.341±0.0001]");
    expect(evaluation.result.negated).to.equal(true);
  }
}

@("lazy array throwing in approximately propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[] someLazyArray() {
    throw new Exception("This is it.");
  }

  ({
    someLazyArray.should.approximately([], 3);
  }).should.throwAnyException.withMessage("This is it.");
}

@("float array approximately equal within tolerance succeeds")
unittest {
  [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.01);
}

@("float array not approximately equal outside tolerance succeeds")
unittest {
  [0.350, 0.501, 0.341].should.not.be.approximately([0.35, 0.50, 0.34], 0.00001);
}

@("float array not approximately equal reordered succeeds")
unittest {
  [0.350, 0.501, 0.341].should.not.be.approximately([0.501, 0.350, 0.341], 0.001);
}

@("float array not approximately equal shorter expected succeeds")
unittest {
  [0.350, 0.501, 0.341].should.not.be.approximately([0.350, 0.501], 0.001);
}

@("float array not approximately equal longer expected succeeds")
unittest {
  [0.350, 0.501].should.not.be.approximately([0.350, 0.501, 0.341], 0.001);
}

@("float array approximately equal outside tolerance reports expected with tolerance")
unittest {
  auto evaluation = ({
    [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.0001);
  }).recordEvaluation;

  evaluation.result.expected[].should.equal("[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
  evaluation.result.missing.length.should.equal(2);
}

@("Assert.approximately array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Assert.approximately([0.350, 0.501, 0.341], [0.35, 0.50, 0.34], 0.01);
}

@("Assert.notApproximately array succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Assert.notApproximately([0.350, 0.501, 0.341], [0.350, 0.501], 0.0001);
}
