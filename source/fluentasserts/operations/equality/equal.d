module fluentasserts.operations.equality.equal;

import fluentasserts.results.printer;
import fluentasserts.core.evaluation.eval : Evaluation;

import fluentasserts.core.lifecycle;
import fluentasserts.core.diff.diff : computeDiff;
import fluentasserts.core.diff.types : EditOp;
import fluentasserts.core.memory.heapstring : HeapString, toHeapString;
import fluentasserts.core.config : config = FluentAssertsConfig;
import fluentasserts.results.message : Message;
import fluentasserts.results.serializers.heap_registry : HeapSerializerRegistry;
import std.meta : AliasSeq;

version (unittest) {
  import fluent.asserts;
  import fluentasserts.core.base;
  import fluentasserts.core.expect;
  import fluentasserts.core.lifecycle;
  import std.conv;
  import std.datetime;
  import std.meta;
  import std.string;
}

static immutable equalDescription = "Asserts that the target is strictly == equal to the given val.";

/// Formats a line number with right-aligned padding.
/// Returns a HeapString containing the padded number followed by ": ".
HeapString formatLineNumber(size_t lineNum, size_t width = config.display.defaultLineNumberWidth) @trusted nothrow {
  import fluentasserts.core.conversion.toheapstring : toHeapString;

  auto numStr = toHeapString(lineNum);
  auto result = HeapString.create(width + 2); // width + ": "

  // Add leading spaces for right-alignment
  size_t numLen = numStr.value.length;
  if (numLen < width) {
    foreach (_; 0 .. width - numLen) {
      result.put(' ');
    }
  }

  result.put(numStr.value[]);
  result.put(": ");
  return result;
}

static immutable isEqualTo = Message(Message.Type.info, " is equal to ");
static immutable isNotEqualTo = Message(Message.Type.info, " is not equal to ");
static immutable endSentence = Message(Message.Type.info, ".");

/// Asserts that the current value is strictly equal to the expected value.
/// Note: This function is not @nogc because it may use opEquals for object comparison.
void equal(ref Evaluation evaluation) @safe nothrow {
  auto hasCurrentProxy = !evaluation.currentValue.proxyValue.isNull();
  auto hasExpectedProxy = !evaluation.expectedValue.proxyValue.isNull();

  bool isEqual;
  if (hasCurrentProxy && hasExpectedProxy) {
    isEqual = evaluation.currentValue.proxyValue.isEqualTo(evaluation.expectedValue.proxyValue);
  } else {
    isEqual = evaluation.currentValue.strValue == evaluation.expectedValue.strValue;
  }

  bool passed = evaluation.isNegated ? !isEqual : isEqual;
  if (passed) {
    return;
  }

  evaluation.result.negated = evaluation.isNegated;

  bool isMultilineComparison = isMultilineString(evaluation.currentValue.strValue) ||
                               isMultilineString(evaluation.expectedValue.strValue);

  if (isMultilineComparison) {
    setMultilineResult(evaluation);
  } else {
    if (evaluation.isNegated) {
      evaluation.result.expected.put("not ");
    }
    evaluation.result.expected.put(evaluation.expectedValue.strValue[]);
    evaluation.result.actual.put(evaluation.currentValue.strValue[]);
  }
}

/// Sets the result for multiline string comparisons.
/// Shows the actual multiline values formatted with line prefixes for readability.
void setMultilineResult(ref Evaluation evaluation) @trusted nothrow {
  auto actualUnescaped = unescapeString(evaluation.currentValue.strValue);
  auto expectedUnescaped = unescapeString(evaluation.expectedValue.strValue);

  if (evaluation.isNegated) {
    evaluation.result.expected.put("not\n");
    formatMultilineValue(evaluation.result.expected, expectedUnescaped);
  } else {
    formatMultilineValue(evaluation.result.expected, expectedUnescaped);
  }

  formatMultilineValue(evaluation.result.actual, actualUnescaped);

  if (!evaluation.isNegated) {
    setMultilineDiff(evaluation);
  }
}

/// Formats a multiline string value with line prefixes for display.
/// Uses right-aligned line numbers to align with source code display format.
void formatMultilineValue(T)(ref T output, ref const HeapString str) @trusted nothrow {
  auto slice = str[];
  size_t lineStart = 0;
  size_t lineNum = 1;

  foreach (i; 0 .. str.length) {
    if (str[i] == '\n') {
      auto numStr = formatLineNumber(lineNum);
      output.put(numStr[]);
      output.put(slice[lineStart .. i]);
      output.put("\n");
      lineStart = i + 1;
      lineNum++;
    }
  }

  if (lineStart < str.length) {
    auto numStr = formatLineNumber(lineNum);
    output.put(numStr[]);
    output.put(slice[lineStart .. str.length]);
  }
}

/// Checks if a HeapString contains multiple lines.
/// Detects both raw newlines and escaped newlines (\n as two characters).
bool isMultilineString(ref const HeapString str) @safe @nogc nothrow {
  if (str.length < 2) {
    return false;
  }

  foreach (i; 0 .. str.length) {
    // Check for raw newline
    if (str[i] == '\n') {
      return true;
    }

    // Check for escaped newline (\n as two chars)
    if (str[i] == '\\' && i + 1 < str.length && str[i + 1] == 'n') {
      return true;
    }
  }

  return false;
}

/// Unescapes a HeapString by converting escaped sequences back to actual characters.
/// Handles \n, \t, \r, \0.
HeapString unescapeString(ref const HeapString str) @safe @nogc nothrow {
  auto result = HeapString.create(str.length);
  size_t i = 0;

  while (i < str.length) {
    if (str[i] == '\\' && i + 1 < str.length) {
      char next = str[i + 1];

      switch (next) {
        case 'n':
          result.put('\n');
          i += 2;
          continue;

        case 't':
          result.put('\t');
          i += 2;
          continue;

        case 'r':
          result.put('\r');
          i += 2;
          continue;

        case '0':
          result.put('\0');
          i += 2;
          continue;

        case '\\':
          result.put('\\');
          i += 2;
          continue;

        default:
          break;
      }
    }

    result.put(str[i]);
    i++;
  }

  return result;
}

/// Tracks state while rendering diff output.
struct DiffRenderState {
  size_t currentLine = size_t.max;
  size_t lastShownLine = size_t.max;
  bool[size_t] visibleLines;
}

/// Represents a line-level diff operation.
struct LineDiffOp {
  EditOp op;
  size_t lineNum;  // Line number in original (for remove/equal) or new (for insert)
}

/// Computes line-based diff using LCS (Longest Common Subsequence) approach.
/// Returns an array of operations indicating which lines to keep, remove, or insert.
LineDiffOp[] computeLineDiff(ref HeapString[] expectedLines, ref HeapString[] actualLines) @trusted nothrow {
  LineDiffOp[] result;
  size_t expLen = expectedLines.length;
  size_t actLen = actualLines.length;

  if (expLen == 0 && actLen == 0) {
    return result;
  }

  if (expLen == 0) {
    foreach (i; 0 .. actLen) {
      result ~= LineDiffOp(EditOp.insert, i);
    }
    return result;
  }

  if (actLen == 0) {
    foreach (i; 0 .. expLen) {
      result ~= LineDiffOp(EditOp.remove, i);
    }
    return result;
  }

  // Build LCS table
  size_t[][] lcs;
  lcs.length = expLen + 1;
  foreach (i; 0 .. expLen + 1) {
    lcs[i].length = actLen + 1;
  }

  foreach (i; 1 .. expLen + 1) {
    foreach (j; 1 .. actLen + 1) {
      if (linesEqual(expectedLines[i - 1], actualLines[j - 1])) {
        lcs[i][j] = lcs[i - 1][j - 1] + 1;
      } else if (lcs[i - 1][j] >= lcs[i][j - 1]) {
        lcs[i][j] = lcs[i - 1][j];
      } else {
        lcs[i][j] = lcs[i][j - 1];
      }
    }
  }

  // Backtrack to build the diff
  LineDiffOp[] reversed;
  size_t i = expLen;
  size_t j = actLen;

  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && linesEqual(expectedLines[i - 1], actualLines[j - 1])) {
      reversed ~= LineDiffOp(EditOp.equal, i - 1);
      i--;
      j--;
    } else if (j > 0 && (i == 0 || lcs[i][j - 1] >= lcs[i - 1][j])) {
      reversed ~= LineDiffOp(EditOp.insert, j - 1);
      j--;
    } else {
      reversed ~= LineDiffOp(EditOp.remove, i - 1);
      i--;
    }
  }

  // Reverse to get correct order
  foreach_reverse (idx; 0 .. reversed.length) {
    result ~= reversed[idx];
  }

  return result;
}

/// A block of consecutive diff operations of the same type.
struct DiffBlock {
  EditOp op;
  size_t[] lineIndices;
}

/// Groups consecutive diff operations into blocks.
DiffBlock[] groupIntoBlocks(ref LineDiffOp[] ops) @trusted nothrow {
  DiffBlock[] blocks;

  if (ops.length == 0) {
    return blocks;
  }

  DiffBlock current;
  current.op = ops[0].op;
  current.lineIndices ~= ops[0].lineNum;

  foreach (i; 1 .. ops.length) {
    if (ops[i].op == current.op) {
      current.lineIndices ~= ops[i].lineNum;
    } else {
      if (current.op != EditOp.equal) {
        blocks ~= current;
      }
      current.op = ops[i].op;
      current.lineIndices = [ops[i].lineNum];
    }
  }

  if (current.op != EditOp.equal) {
    blocks ~= current;
  }

  return blocks;
}

/// Holds information about a change block with its context.
struct ChangeBlockWithContext {
  size_t firstChangeLine;  // First changed line index in expected (for remove) or actual (for insert)
  size_t lastChangeLine;   // Last changed line index
  EditOp op;
  size_t[] lineIndices;
}

/// Builds change blocks with position information for context lookup.
ChangeBlockWithContext[] buildChangeBlocksWithContext(ref LineDiffOp[] ops) @trusted nothrow {
  ChangeBlockWithContext[] result;

  if (ops.length == 0) {
    return result;
  }

  ChangeBlockWithContext current;
  current.op = ops[0].op;
  current.lineIndices ~= ops[0].lineNum;
  current.firstChangeLine = ops[0].lineNum;
  current.lastChangeLine = ops[0].lineNum;

  foreach (i; 1 .. ops.length) {
    if (ops[i].op == current.op) {
      current.lineIndices ~= ops[i].lineNum;
      current.lastChangeLine = ops[i].lineNum;
    } else {
      if (current.op != EditOp.equal) {
        result ~= current;
      }
      current.op = ops[i].op;
      current.lineIndices = [ops[i].lineNum];
      current.firstChangeLine = ops[i].lineNum;
      current.lastChangeLine = ops[i].lineNum;
    }
  }

  if (current.op != EditOp.equal) {
    result ~= current;
  }

  return result;
}

/// Sets a user-friendly line-by-line diff on the evaluation result.
/// Uses line-based diff algorithm and groups changes into readable blocks with context.
void setMultilineDiff(ref Evaluation evaluation) @trusted nothrow {
  enum CONTEXT_LINES = 2;

  auto expectedUnescaped = unescapeString(evaluation.expectedValue.strValue);
  auto actualUnescaped = unescapeString(evaluation.currentValue.strValue);

  auto expectedLines = splitLines(expectedUnescaped);
  auto actualLines = splitLines(actualUnescaped);

  if (expectedLines.length == 0 && actualLines.length == 0) {
    return;
  }

  auto lineDiff = computeLineDiff(expectedLines, actualLines);
  auto blocks = buildChangeBlocksWithContext(lineDiff);

  if (blocks.length == 0) {
    return;
  }

  auto diffBuffer = HeapString.create(4096);
  diffBuffer.put("\n\nDiff:\n");

  foreach (blockIdx; 0 .. blocks.length) {
    auto block = blocks[blockIdx];

    // Add separator and title at the start of each block
    if (blockIdx > 0) {
      diffBuffer.put("\n    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
    }

    if (block.op == EditOp.remove) {
      diffBuffer.put("    --- Expected (missing in actual) ---\n");
    } else if (block.op == EditOp.insert) {
      diffBuffer.put("    +++ Actual (not in expected) +++\n");
    }
    diffBuffer.put("\n");

    // Determine context lines source based on operation type
    HeapString[]* contextSource;
    size_t firstIdx = block.firstChangeLine;

    if (block.op == EditOp.remove) {
      contextSource = &expectedLines;
    } else {
      contextSource = &actualLines;
    }

    // Show context lines before the change
    size_t contextStart = firstIdx > CONTEXT_LINES ? firstIdx - CONTEXT_LINES : 0;
    foreach (ctxIdx; contextStart .. firstIdx) {
      auto lineNum = formatLineNumber(ctxIdx + 1);
      diffBuffer.put(lineNum[]);
      diffBuffer.put("   ");
      diffBuffer.put((*contextSource)[ctxIdx][]);
      diffBuffer.put("\n");
    }

    // Show the changed lines
    if (block.op == EditOp.remove) {
      foreach (idx; 0 .. block.lineIndices.length) {
        size_t lineIdx = block.lineIndices[idx];
        auto lineNum = formatLineNumber(lineIdx + 1);
        diffBuffer.put(lineNum[]);
        diffBuffer.put("[-");
        diffBuffer.put(expectedLines[lineIdx][]);
        diffBuffer.put("-]\n");
      }
    } else if (block.op == EditOp.insert) {
      foreach (idx; 0 .. block.lineIndices.length) {
        size_t lineIdx = block.lineIndices[idx];
        auto lineNum = formatLineNumber(lineIdx + 1);
        diffBuffer.put(lineNum[]);
        diffBuffer.put("[+");
        diffBuffer.put(actualLines[lineIdx][]);
        diffBuffer.put("+]\n");
      }
    }

    // Show context lines after the change
    size_t lastIdx = block.lastChangeLine;
    size_t contextEnd = lastIdx + 1 + CONTEXT_LINES;
    if (contextEnd > (*contextSource).length) {
      contextEnd = (*contextSource).length;
    }
    foreach (ctxIdx; lastIdx + 1 .. contextEnd) {
      auto lineNum = formatLineNumber(ctxIdx + 1);
      diffBuffer.put(lineNum[]);
      diffBuffer.put("   ");
      diffBuffer.put((*contextSource)[ctxIdx][]);
      diffBuffer.put("\n");
    }
  }

  diffBuffer.put("\n");
  evaluation.result.addText(diffBuffer[]);
}

/// Splits a HeapString into lines.
HeapString[] splitLines(ref const HeapString str) @trusted nothrow {
  HeapString[] lines;
  size_t lineStart = 0;

  foreach (i; 0 .. str.length) {
    if (str[i] == '\n') {
      auto line = HeapString.create(i - lineStart);
      foreach (j; lineStart .. i) {
        line.put(str[j]);
      }
      lines ~= line;
      lineStart = i + 1;
    }
  }

  // Add last line if there's remaining content
  if (lineStart < str.length) {
    auto line = HeapString.create(str.length - lineStart);
    foreach (j; lineStart .. str.length) {
      line.put(str[j]);
    }
    lines ~= line;
  }

  return lines;
}

/// Compares two HeapStrings for equality.
bool linesEqual(ref const HeapString a, ref const HeapString b) @trusted nothrow {
  if (a.length != b.length) {
    return false;
  }

  foreach (i; 0 .. a.length) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

/// Renders a single diff segment to a buffer, handling line transitions.
void renderSegmentToBuffer(T, B)(ref B buffer, ref T seg, ref DiffRenderState state) @trusted nothrow {
  if ((seg.line in state.visibleLines) is null) {
    return;
  }

  if (seg.line != state.currentLine) {
    handleLineTransitionToBuffer(buffer, seg.line, state);
  }

  addSegmentTextToBuffer(buffer, seg);
}

/// Handles the transition to a new line in diff output (buffer version).
void handleLineTransitionToBuffer(B)(ref B buffer, size_t newLine, ref DiffRenderState state) @trusted nothrow {
  bool isFirstLine = state.currentLine == size_t.max;
  bool hasGap = !isFirstLine && newLine > state.lastShownLine + 1;

  if (!isFirstLine) {
    buffer.put("\n");
  }

  if (hasGap) {
    buffer.put("    ...\n");
  }

  state.currentLine = newLine;
  state.lastShownLine = newLine;

  // Add line number with proper padding
  auto lineNum = formatLineNumber(newLine + 1);
  buffer.put(lineNum[]);
}

/// Adds segment text with diff markers to a buffer.
void addSegmentTextToBuffer(T, B)(ref B buffer, ref T seg) @trusted nothrow {
  auto text = formatDiffText(seg.text);

  final switch (seg.op) {
    case EditOp.equal:
      buffer.put(text);
      break;

    case EditOp.remove:
      buffer.put("[-");
      buffer.put(text);
      buffer.put("-]");
      break;

    case EditOp.insert:
      buffer.put("[+");
      buffer.put(text);
      buffer.put("+]");
      break;
  }
}

/// Finds all line numbers that contain changes (insert or remove).
size_t[] findChangedLines(T)(ref T diffResult) @trusted nothrow {
  size_t[] changedLines;
  size_t lastLine = size_t.max;

  foreach (i; 0 .. diffResult.length) {
    if (diffResult[i].op != EditOp.equal && diffResult[i].line != lastLine) {
      changedLines ~= diffResult[i].line;
      lastLine = diffResult[i].line;
    }
  }

  return changedLines;
}

/// Expands changed lines with context lines before and after.
bool[size_t] expandWithContext(size_t[] changedLines, size_t context) @trusted nothrow {
  bool[size_t] visibleLines;

  foreach (i; 0 .. changedLines.length) {
    addLineRange(visibleLines, changedLines[i], context);
  }

  return visibleLines;
}

/// Adds a range of lines centered on the given line to the visible set.
void addLineRange(ref bool[size_t] visibleLines, size_t centerLine, size_t context) @trusted nothrow {
  size_t start = centerLine > context ? centerLine - context : 0;
  size_t end = centerLine + context + 1;

  foreach (line; start .. end) {
    visibleLines[line] = true;
  }
}

/// Adds a formatted line number prefix to the result.
void addLineNumber(ref Evaluation evaluation, size_t line) @trusted nothrow {
  auto lineNum = formatLineNumber(line + 1);
  evaluation.result.addText(lineNum[]);
}

/// Adds segment text with diff markers.
/// Uses [-text-] for removals and [+text+] for insertions.
void addSegmentText(T)(ref Evaluation evaluation, ref T seg) @trusted nothrow {
  auto text = formatDiffText(seg.text);

  final switch (seg.op) {
    case EditOp.equal:
      evaluation.result.addText(text);
      break;

    case EditOp.remove:
      evaluation.result.addText("[-");
      evaluation.result.add(Message(Message.Type.delete_, text));
      evaluation.result.addText("-]");
      break;

    case EditOp.insert:
      evaluation.result.addText("[+");
      evaluation.result.add(Message(Message.Type.insert, text));
      evaluation.result.addText("+]");
      break;
  }
}

/// Formats diff text by replacing special characters with visible representations.
string formatDiffText(ref const HeapString text) @trusted nothrow {
  HeapString result;

  foreach (i; 0 .. text.length) {
    char c = text[i];

    if (c == '\n') {
      result.put('\\');
      result.put('n');
    } else if (c == '\t') {
      result.put('\\');
      result.put('t');
    } else if (c == '\r') {
      result.put('\\');
      result.put('r');
    } else {
      result.put(c);
    }
  }

  return result[].idup;
}

// ---------------------------------------------------------------------------
// Unit tests
// ---------------------------------------------------------------------------

alias StringTypes = AliasSeq!(string, wstring, dstring);

static foreach (Type; StringTypes) {
  @(Type.stringof ~ " compares two exact strings")
  unittest {
    auto evaluation = ({
      expect("test string").to.equal("test string");
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "equal operation should pass for identical strings");
  }

  @(Type.stringof ~ " checks if two strings are not equal")
  unittest {
    auto evaluation = ({
      expect("test string").to.not.equal("test");
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "not equal operation should pass for different strings");
  }

  @(Type.stringof ~ " test string equal test reports error with expected and actual")
  unittest {
    auto evaluation = ({
      expect("test string").to.equal("test");
    }).recordEvaluation;

    assert(evaluation.result.expected[] == `test`, "expected 'test' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == `test string`, "expected 'test string' but got: " ~ evaluation.result.actual[]);
  }

  @(Type.stringof ~ " test string not equal test string reports error with expected and negated")
  unittest {
    auto evaluation = ({
      expect("test string").to.not.equal("test string");
    }).recordEvaluation;

    assert(evaluation.result.expected[] == `not test string`, "expected 'not test string' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == `test string`, "expected 'test string' but got: " ~ evaluation.result.actual[]);
    assert(evaluation.result.negated == true, "expected negated to be true");
  }

  @(Type.stringof ~ " string with null chars equal string without null chars reports error with actual containing null chars")
  unittest {
    ubyte[] data = [115, 111, 109, 101, 32, 100, 97, 116, 97, 0, 0];

    auto evaluation = ({
      expect(data.assumeUTF.to!Type).to.equal("some data");
    }).recordEvaluation;

    assert(evaluation.result.expected[] == `some data`, "expected 'some data' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == `some data\0\0`, "expected 'some data\\0\\0' but got: " ~ evaluation.result.actual[]);
  }
}

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
  @(Type.stringof ~ " compares two exact values")
  unittest {
    Type testValue = cast(Type) 40;

    auto evaluation = ({
      expect(testValue).to.equal(testValue);
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "equal operation should pass for identical values");
  }

  @(Type.stringof ~ " checks if two values are not equal")
  unittest {
    Type testValue = cast(Type) 40;
    Type otherTestValue = cast(Type) 50;

    auto evaluation = ({
      expect(testValue).to.not.equal(otherTestValue);
    }).recordEvaluation;

    assert(evaluation.result.expected.length == 0, "not equal operation should pass for different values");
  }

  @(Type.stringof ~ " 40 equal 50 reports error with expected and actual")
  unittest {
    Type testValue = cast(Type) 40;
    Type otherTestValue = cast(Type) 50;

    auto evaluation = ({
      expect(testValue).to.equal(otherTestValue);
    }).recordEvaluation;

    assert(evaluation.result.expected[] == otherTestValue.to!string, "expected '" ~ otherTestValue.to!string ~ "' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == testValue.to!string, "expected '" ~ testValue.to!string ~ "' but got: " ~ evaluation.result.actual[]);
  }

  @(Type.stringof ~ " 40 not equal 40 reports error with expected and negated")
  unittest {
    Type testValue = cast(Type) 40;

    auto evaluation = ({
      expect(testValue).to.not.equal(testValue);
    }).recordEvaluation;

    assert(evaluation.result.expected[] == "not " ~ testValue.to!string, "expected 'not " ~ testValue.to!string ~ "' but got: " ~ evaluation.result.expected[]);
    assert(evaluation.result.actual[] == testValue.to!string, "expected '" ~ testValue.to!string ~ "' but got: " ~ evaluation.result.actual[]);
    assert(evaluation.result.negated == true, "expected negated to be true");
  }
}

@("booleans compares two true values")
unittest {
  auto evaluation = ({
    expect(true).to.equal(true);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for true == true");
}

@("booleans compares two false values")
unittest {
  auto evaluation = ({
    expect(false).to.equal(false);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for false == false");
}

@("booleans true not equal false passes")
unittest {
  auto evaluation = ({
    expect(true).to.not.equal(false);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for true != false");
}

@("booleans false not equal true passes")
unittest {
  auto evaluation = ({
    expect(false).to.not.equal(true);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for false != true");
}

@("true equal false reports error with expected false and actual true")
unittest {
  auto evaluation = ({
    expect(true).to.equal(false);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "false", "expected 'false' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == "true", "expected 'true' but got: " ~ evaluation.result.actual[]);
}

@("durations compares two equal values")
unittest {
  auto evaluation = ({
    expect(2.seconds).to.equal(2.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for identical durations");
}

@("durations 2 seconds not equal 3 seconds passes")
unittest {
  auto evaluation = ({
    expect(2.seconds).to.not.equal(3.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for 2s != 3s");
}

@("durations 3 seconds not equal 2 seconds passes")
unittest {
  auto evaluation = ({
    expect(3.seconds).to.not.equal(2.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for 3s != 2s");
}

@("3 seconds equal 2 seconds reports error with expected and actual")
unittest {
  auto evaluation = ({
    expect(3.seconds).to.equal(2.seconds);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "2000000000", "expected '2000000000' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == "3000000000", "expected '3000000000' but got: " ~ evaluation.result.actual[]);
}

@("objects without custom opEquals compares two exact values")
unittest {
  Object testValue = new Object();

  auto evaluation = ({
    expect(testValue).to.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for same object reference");
}

@("objects without custom opEquals checks if two values are not equal")
unittest {
  Object testValue = new Object();
  Object otherTestValue = new Object();

  auto evaluation = ({
    expect(testValue).to.not.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for different objects");
}

@("object equal different object reports error with expected and actual")
unittest {
  Object testValue = new Object();
  Object otherTestValue = new Object();
  string niceTestValue = HeapSerializerRegistry.instance.niceValue(testValue)[].idup;
  string niceOtherTestValue = HeapSerializerRegistry.instance.niceValue(otherTestValue)[].idup;

  auto evaluation = ({
    expect(testValue).to.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == niceOtherTestValue, "expected '" ~ niceOtherTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
}

@("object not equal itself reports error with expected and negated")
unittest {
  Object testValue = new Object();
  string niceTestValue = HeapSerializerRegistry.instance.niceValue(testValue)[].idup;

  auto evaluation = ({
    expect(testValue).to.not.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "not " ~ niceTestValue, "expected 'not " ~ niceTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
  assert(evaluation.result.negated == true, "expected negated to be true");
}

// Issue #98: opEquals should be honored when asserting equality
@("objects with custom opEquals compares two exact values")
unittest {
  auto testValue = new EqualThing(1);

  auto evaluation = ({
    expect(testValue).to.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for same object reference");
}

// Issue #98: opEquals should be honored when asserting equality
@("objects with custom opEquals compares two objects with same fields")
unittest {
  auto testValue = new EqualThing(1);
  auto sameTestValue = new EqualThing(1);

  auto evaluation = ({
    expect(testValue).to.equal(sameTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for objects with same fields");
}

// Issue #98: opEquals should be honored when asserting equality
@("objects with custom opEquals compares object cast to Object with same fields")
unittest {
  auto testValue = new EqualThing(1);
  auto sameTestValue = new EqualThing(1);

  auto evaluation = ({
    expect(testValue).to.equal(cast(Object) sameTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for objects with same fields cast to Object");
}

// Issue #98: opEquals should be honored when asserting equality
@("objects with custom opEquals checks if two values are not equal")
unittest {
  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);

  auto evaluation = ({
    expect(testValue).to.not.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for objects with different fields");
}

@("EqualThing(1) equal EqualThing(2) reports error with expected and actual")
unittest {
  auto testValue = new EqualThing(1);
  auto otherTestValue = new EqualThing(2);
  string niceTestValue = HeapSerializerRegistry.instance.niceValue(testValue)[].idup;
  string niceOtherTestValue = HeapSerializerRegistry.instance.niceValue(otherTestValue)[].idup;

  auto evaluation = ({
    expect(testValue).to.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == niceOtherTestValue, "expected '" ~ niceOtherTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
}

@("EqualThing(1) not equal itself reports error with expected and negated")
unittest {
  auto testValue = new EqualThing(1);
  string niceTestValue = HeapSerializerRegistry.instance.niceValue(testValue)[].idup[].idup;

  auto evaluation = ({
    expect(testValue).to.not.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "not " ~ niceTestValue, "expected 'not " ~ niceTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
  assert(evaluation.result.negated == true, "expected negated to be true");
}

@("assoc arrays compares two exact values")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];

  auto evaluation = ({
    expect(testValue).to.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for same assoc array reference");
}

@("assoc arrays compares two objects with same fields")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] sameTestValue = ["a": "1", "b": "2", "c": "3"];

  auto evaluation = ({
    expect(testValue).to.equal(sameTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "equal operation should pass for assoc arrays with same content");
}

@("assoc arrays checks if two values are not equal")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];

  auto evaluation = ({
    expect(testValue).to.not.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "not equal operation should pass for assoc arrays with different content");
}

@("assoc array equal different assoc array reports error with expected and actual")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string[string] otherTestValue = ["a": "3", "b": "2", "c": "1"];
  string niceTestValue = HeapSerializerRegistry.instance.niceValue(testValue)[].idup;
  string niceOtherTestValue = HeapSerializerRegistry.instance.niceValue(otherTestValue)[].idup;

  auto evaluation = ({
    expect(testValue).to.equal(otherTestValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == niceOtherTestValue, "expected '" ~ niceOtherTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
}

@("assoc array not equal itself reports error with expected and negated")
unittest {
  string[string] testValue = ["b": "2", "a": "1", "c": "3"];
  string niceTestValue = HeapSerializerRegistry.instance.niceValue(testValue)[].idup;

  auto evaluation = ({
    expect(testValue).to.not.equal(testValue);
  }).recordEvaluation;

  assert(evaluation.result.expected[] == "not " ~ niceTestValue, "expected 'not " ~ niceTestValue ~ "' but got: " ~ evaluation.result.expected[]);
  assert(evaluation.result.actual[] == niceTestValue, "expected '" ~ niceTestValue ~ "' but got: " ~ evaluation.result.actual[]);
  assert(evaluation.result.negated == true, "expected negated to be true");
}

@("lazy number throwing in equal propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int someLazyInt() {
    throw new Exception("This is it.");
  }

  ({
    someLazyInt.should.equal(3);
  }).should.throwAnyException.withMessage("This is it.");
}

@("const int equal int succeeds")
unittest {
  const actual = 42;
  actual.should.equal(42);
}

@("lazy string throwing in equal propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string someLazyString() {
    throw new Exception("This is it.");
  }

  ({
    someLazyString.should.equal("");
  }).should.throwAnyException.withMessage("This is it.");
}

@("const string equal string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const string constValue = "test string";
  constValue.should.equal("test string");
}

@("immutable string equal string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable string immutableValue = "test string";
  immutableValue.should.equal("test string");
}

@("string equal const string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  const string constValue = "test string";
  "test string".should.equal(constValue);
}

@("string equal immutable string succeeds")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  immutable string immutableValue = "test string";
  "test string".should.equal(immutableValue);
}

@("lazy object throwing in equal propagates the exception")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  Object someLazyObject() {
    throw new Exception("This is it.");
  }

  ({
    someLazyObject.should.equal(new Object);
  }).should.throwAnyException.withMessage("This is it.");
}

@("null object equals new object reports message starts with equal")
unittest {
  Object nullObject;

  auto evaluation = ({
    nullObject.should.equal(new Object);
  }).recordEvaluation;

  evaluation.result.messageString.should.startWith("null should equal Object(");
}

@("new object equals null reports message starts with equal null")
unittest {
  auto evaluation = ({
    (new Object).should.equal(null);
  }).recordEvaluation;

  evaluation.result.messageString.should.contain("should equal null.");
}

// Issue #100: double serialized as scientific notation should equal integer
@("double equals int with same value passes")
unittest {
  // 1003200.0 serializes as "1.0032e+06" and 1003200 as "1003200"
  // Numeric comparison should still work
  (1003200.0).should.equal(1003200);
  (1003200).should.equal(1003200.0);
}

// Issue #100: double serialized as scientific notation should equal integer
@("double equals int with different value fails")
unittest {
  auto evaluation = ({
    (1003200.0).should.equal(1003201);
  }).recordEvaluation;

  evaluation.result.hasContent().should.equal(true);
}

version (unittest):
class EqualThing {
  int x;
  this(int x) {
    this.x = x;
  }

  override bool opEquals(Object o) @trusted nothrow @nogc {
    auto b = cast(typeof(this)) o;
    if (b is null) return false;
    return this.x == b.x;
  }
}

class Thing {
  int x;
  this(int x) {
    this.x = x;
  }

  override bool opEquals(Object o) {
    if (typeid(this) != typeid(o)) {
      return false;
    }
    auto b = cast(typeof(this)) o;
    return this.x == b.x;
  }
}

// Issue #98: opEquals should be honored when asserting equality
@("opEquals honored for class objects with same field value")
unittest {
  auto a1 = new Thing(1);
  auto b1 = new Thing(1);

  assert(a1 == b1, "D's == operator should use opEquals");

  auto evaluation = ({
    a1.should.equal(b1);
  }).recordEvaluation;

  assert(evaluation.result.expected.length == 0, "opEquals should return true for objects with same x value, but got expected: " ~ evaluation.result.expected[]);
}

// Issue #98: opEquals should be honored when asserting equality
@("opEquals honored for class objects with different field values")
unittest {
  auto a1 = new Thing(1);
  auto a2 = new Thing(2);

  assert(a1 != a2, "D's != operator should use opEquals");
  a1.should.not.equal(a2);
}

// Issue #96: Object[] and nested arrays should work with equal
@("Object array equal itself passes")
unittest {
  Object[] l = [new Object(), new Object()];
  l.should.equal(l);
}

@("associative array equal itself passes")
unittest {
  string[string] al = ["k1": "v1", "k2": "v2"];
  al.should.equal(al);
}

// Issue #96: Object[] and nested arrays should work with equal
@("nested int array equal passes")
unittest {
  import std.range : iota;
  import std.algorithm : map;
  import std.array : array;

  auto ll = iota(1, 4).map!iota;
  ll.map!array.array.should.equal([[0], [0, 1], [0, 1, 2]]);
}

// Issue #85: range of ranges should work with equal without memory exhaustion
@("issue #85: range of ranges equal passes")
unittest {
  import std.range : iota;
  import std.algorithm : map;

  auto ror = iota(1, 4).map!iota;
  ror.should.equal([[0], [0, 1], [0, 1, 2]]);
}
