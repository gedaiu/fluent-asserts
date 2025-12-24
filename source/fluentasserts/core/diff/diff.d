/// Public API for computing diffs between HeapStrings.
module fluentasserts.core.diff.diff;

import fluentasserts.core.diff.types : EditOp, DiffSegment, DiffResult;
import fluentasserts.core.diff.myers : computeEditScript, Edit, EditScript;
import fluentasserts.core.memory.heapstring : HeapString, toHeapString;

@safe:

/// Computes the diff between two HeapStrings.
/// Returns a list of DiffSegments with coalesced operations and line numbers.
DiffResult computeDiff(ref const HeapString a, ref const HeapString b) @nogc nothrow {
  auto script = computeEditScript(a, b);

  return coalesce(script, a, b);
}

/// Coalesces consecutive same-operation edits into segments with line tracking.
DiffResult coalesce(
  ref EditScript script,
  ref const HeapString a,
  ref const HeapString b
) @nogc nothrow {
  auto result = DiffResult.create();

  if (script.length == 0) {
    return result;
  }

  size_t lineA = 0;
  size_t lineB = 0;

  EditOp currentOp = script[0].op;
  size_t currentLine = getLine(script[0], lineA, lineB);
  HeapString currentText;

  foreach (i; 0 .. script.length) {
    auto edit = script[i];
    size_t editLine = getLine(edit, lineA, lineB);

    if (edit.op != currentOp || editLine != currentLine) {
      if (currentText.length > 0) {
        result.put(DiffSegment(currentOp, currentText, currentLine));
      }

      currentOp = edit.op;
      currentLine = editLine;
      currentText = HeapString.create();
    }

    char c = getChar(edit, a, b);
    currentText.put(c);

    if (c == '\n') {
      if (edit.op == EditOp.equal || edit.op == EditOp.remove) {
        lineA++;
      }

      if (edit.op == EditOp.equal || edit.op == EditOp.insert) {
        lineB++;
      }
    }
  }

  if (currentText.length > 0) {
    result.put(DiffSegment(currentOp, currentText, currentLine));
  }

  return result;
}

/// Gets the line number for an edit operation.
size_t getLine(Edit edit, size_t lineA, size_t lineB) @nogc nothrow {
  if (edit.op == EditOp.insert) {
    return lineB;
  }

  return lineA;
}

/// Gets the character for an edit operation.
char getChar(Edit edit, ref const HeapString a, ref const HeapString b) @nogc nothrow {
  if (edit.op == EditOp.insert) {
    return b[edit.posB];
  }

  return a[edit.posA];
}

version (unittest) {
  @("computes diff for identical strings")
  unittest {
    auto a = toHeapString("hello");
    auto b = toHeapString("hello");
    auto diff = computeDiff(a, b);

    assert(diff.length == 1);
    assert(diff[0].op == EditOp.equal);
    assert(diff[0].text == "hello");
    assert(diff[0].line == 0);
  }

  @("computes diff for single character change")
  unittest {
    auto a = toHeapString("hello");
    auto b = toHeapString("hallo");
    auto diff = computeDiff(a, b);

    assert(diff.length == 4);
    assert(diff[0].op == EditOp.equal);
    assert(diff[0].text == "h");
    assert(diff[1].op == EditOp.remove);
    assert(diff[1].text == "e");
    assert(diff[2].op == EditOp.insert);
    assert(diff[2].text == "a");
    assert(diff[3].op == EditOp.equal);
    assert(diff[3].text == "llo");
  }

  @("computes diff for empty strings")
  unittest {
    auto a = toHeapString("");
    auto b = toHeapString("");
    auto diff = computeDiff(a, b);

    assert(diff.length == 0);
  }

  @("computes diff when first string is empty")
  unittest {
    auto a = toHeapString("");
    auto b = toHeapString("hello");
    auto diff = computeDiff(a, b);

    assert(diff.length == 1);
    assert(diff[0].op == EditOp.insert);
    assert(diff[0].text == "hello");
  }

  @("computes diff when second string is empty")
  unittest {
    auto a = toHeapString("hello");
    auto b = toHeapString("");
    auto diff = computeDiff(a, b);

    assert(diff.length == 1);
    assert(diff[0].op == EditOp.remove);
    assert(diff[0].text == "hello");
  }

  @("tracks line numbers for multiline diff")
  unittest {
    auto a = toHeapString("line1\nline2");
    auto b = toHeapString("line1\nchanged");
    auto diff = computeDiff(a, b);

    bool foundLine1Equal = false;
    bool foundLine2Remove = false;
    bool foundLine2Insert = false;

    foreach (i; 0 .. diff.length) {
      auto seg = diff[i];

      if (seg.op == EditOp.equal && seg.text == "line1\n") {
        foundLine1Equal = true;
        assert(seg.line == 0);
      }

      if (seg.op == EditOp.remove && seg.line == 1) {
        foundLine2Remove = true;
      }

      if (seg.op == EditOp.insert && seg.line == 1) {
        foundLine2Insert = true;
      }
    }

    assert(foundLine1Equal);
    assert(foundLine2Remove);
    assert(foundLine2Insert);
  }

  @("handles prefix addition")
  unittest {
    auto a = toHeapString("world");
    auto b = toHeapString("hello world");
    auto diff = computeDiff(a, b);

    assert(diff.length == 2);
    assert(diff[0].op == EditOp.insert);
    assert(diff[0].text == "hello ");
    assert(diff[1].op == EditOp.equal);
    assert(diff[1].text == "world");
  }

  @("handles suffix addition")
  unittest {
    auto a = toHeapString("hello");
    auto b = toHeapString("hello world");
    auto diff = computeDiff(a, b);

    assert(diff.length == 2);
    assert(diff[0].op == EditOp.equal);
    assert(diff[0].text == "hello");
    assert(diff[1].op == EditOp.insert);
    assert(diff[1].text == " world");
  }

  @("handles complete replacement")
  unittest {
    auto a = toHeapString("abc");
    auto b = toHeapString("xyz");
    auto diff = computeDiff(a, b);

    size_t removeCount = 0;
    size_t insertCount = 0;

    foreach (i; 0 .. diff.length) {
      if (diff[i].op == EditOp.remove) {
        removeCount += diff[i].text.length;
      }

      if (diff[i].op == EditOp.insert) {
        insertCount += diff[i].text.length;
      }
    }

    assert(removeCount == 3);
    assert(insertCount == 3);
  }
}
