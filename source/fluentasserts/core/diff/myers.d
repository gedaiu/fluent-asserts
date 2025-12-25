/// Core Myers diff algorithm implementation.
module fluentasserts.core.diff.myers;

import fluentasserts.core.diff.types : EditOp;
import fluentasserts.core.diff.varray : VArray;
import fluentasserts.core.diff.snake : followSnake;
import fluentasserts.core.memory.heapstring : HeapString, HeapData;

@safe:

/// A single edit operation in the edit script.
struct Edit {
  EditOp op;
  size_t posA;
  size_t posB;
}

/// Edit script is a sequence of edit operations.
alias EditScript = HeapData!Edit;

/// Computes the shortest edit script between two strings using Myers algorithm.
EditScript computeEditScript(ref const HeapString a, ref const HeapString b) @nogc nothrow {
  auto lenA = a.length;
  auto lenB = b.length;

  if (lenA == 0 && lenB == 0) {
    return EditScript.create();
  }

  if (lenA == 0) {
    return allInserts(lenB);
  }

  if (lenB == 0) {
    return allRemoves(lenA);
  }

  auto maxD = lenA + lenB;
  auto v = VArray.create(maxD);
  auto history = HeapData!VArray.create(maxD + 1);

  v[1] = 0;

  foreach (d; 0 .. maxD + 1) {
    history.put(v.dup());

    foreach (kOffset; 0 .. d + 1) {
      long k = -cast(long)d + cast(long)(kOffset * 2);

      long x;
      if (k == -cast(long)d || (k != cast(long)d && v[k - 1] < v[k + 1])) {
        x = v[k + 1];
      } else {
        x = v[k - 1] + 1;
      }

      long y = x - k;

      x = cast(long)followSnake(a, b, cast(size_t)x, cast(size_t)y);

      v[k] = x;

      if (x >= cast(long)lenA && x - k >= cast(long)lenB) {
        return backtrack(history, d, lenA, lenB);
      }
    }
  }

  return EditScript.create();
}

/// Backtracks through saved V arrays to reconstruct the edit path.
EditScript backtrack(
  ref HeapData!VArray history,
  size_t d,
  size_t lenA,
  size_t lenB
) @nogc nothrow {
  auto result = EditScript.create();
  long x = cast(long)lenA;
  long y = cast(long)lenB;

  foreach_reverse (di; 0 .. d + 1) {
    auto v = history[di];
    long k = x - y;

    long prevK;
    if (k == -cast(long)di || (k != cast(long)di && v[k - 1] < v[k + 1])) {
      prevK = k + 1;
    } else {
      prevK = k - 1;
    }

    long prevX = v[prevK];
    long prevY = prevX - prevK;

    while (x > prevX && y > prevY) {
      x--;
      y--;
      result.put(Edit(EditOp.equal, cast(size_t)x, cast(size_t)y));
    }

    if (di > 0) {
      if (x == prevX) {
        y--;
        result.put(Edit(EditOp.insert, cast(size_t)x, cast(size_t)y));
      } else {
        x--;
        result.put(Edit(EditOp.remove, cast(size_t)x, cast(size_t)y));
      }
    }
  }

  return reverse(result);
}

/// Reverses an edit script.
EditScript reverse(ref EditScript script) @nogc nothrow {
  auto result = EditScript.create(script.length);

  foreach_reverse (i; 0 .. script.length) {
    result.put(script[i]);
  }

  return result;
}

/// Creates an edit script with all inserts.
EditScript allInserts(size_t count) @nogc nothrow {
  auto script = EditScript.create(count);

  foreach (i; 0 .. count) {
    script.put(Edit(EditOp.insert, 0, i));
  }

  return script;
}

/// Creates an edit script with all removes.
EditScript allRemoves(size_t count) @nogc nothrow {
  auto script = EditScript.create(count);

  foreach (i; 0 .. count) {
    script.put(Edit(EditOp.remove, i, 0));
  }

  return script;
}

version (unittest) {
  import fluentasserts.core.memory.heapstring : toHeapString;

  @("computeEditScript returns empty for identical strings")
  unittest {
    auto a = toHeapString("abc");
    auto b = toHeapString("abc");
    auto script = computeEditScript(a, b);

    assert(script.length == 3);

    foreach (i; 0 .. script.length) {
      assert(script[i].op == EditOp.equal);
    }
  }

  @("computeEditScript returns inserts for empty first string")
  unittest {
    auto a = toHeapString("");
    auto b = toHeapString("abc");
    auto script = computeEditScript(a, b);

    assert(script.length == 3);

    foreach (i; 0 .. script.length) {
      assert(script[i].op == EditOp.insert);
    }
  }

  @("computeEditScript returns removes for empty second string")
  unittest {
    auto a = toHeapString("abc");
    auto b = toHeapString("");
    auto script = computeEditScript(a, b);

    assert(script.length == 3);

    foreach (i; 0 .. script.length) {
      assert(script[i].op == EditOp.remove);
    }
  }

  @("computeEditScript handles single character change")
  unittest {
    auto a = toHeapString("abc");
    auto b = toHeapString("adc");
    auto script = computeEditScript(a, b);

    size_t equalCount = 0;
    size_t removeCount = 0;
    size_t insertCount = 0;

    foreach (i; 0 .. script.length) {
      if (script[i].op == EditOp.equal) {
        equalCount++;
      }

      if (script[i].op == EditOp.remove) {
        removeCount++;
      }

      if (script[i].op == EditOp.insert) {
        insertCount++;
      }
    }

    assert(equalCount == 2);
    assert(removeCount == 1);
    assert(insertCount == 1);
  }

  @("allInserts creates correct script")
  unittest {
    auto script = allInserts(3);

    assert(script.length == 3);
    assert(script[0].op == EditOp.insert);
    assert(script[0].posB == 0);
    assert(script[1].posB == 1);
    assert(script[2].posB == 2);
  }

  @("allRemoves creates correct script")
  unittest {
    auto script = allRemoves(3);

    assert(script.length == 3);
    assert(script[0].op == EditOp.remove);
    assert(script[0].posA == 0);
    assert(script[1].posA == 1);
    assert(script[2].posA == 2);
  }
}
