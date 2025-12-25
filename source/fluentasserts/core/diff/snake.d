/// Snake-following logic for Myers diff algorithm.
module fluentasserts.core.diff.snake;

import fluentasserts.core.memory.heapstring : HeapString;

@safe:

/// Follows a snake (diagonal) from the given position.
/// Returns the ending x coordinate after following all equal characters.
size_t followSnake(
  ref const HeapString a,
  ref const HeapString b,
  size_t x,
  size_t y
) @nogc nothrow {
  while (x < a.length && y < b.length && a[x] == b[y]) {
    x++;
    y++;
  }

  return x;
}

version (unittest) {
  import fluentasserts.core.memory.heapstring : toHeapString;

  @("followSnake advances through equal characters")
  unittest {
    auto a = toHeapString("abcdef");
    auto b = toHeapString("abcxyz");

    auto result = followSnake(a, b, 0, 0);

    assert(result == 3);
  }

  @("followSnake returns start position when first chars differ")
  unittest {
    auto a = toHeapString("abc");
    auto b = toHeapString("xyz");

    auto result = followSnake(a, b, 0, 0);

    assert(result == 0);
  }

  @("followSnake handles empty strings")
  unittest {
    auto a = toHeapString("");
    auto b = toHeapString("abc");

    auto result = followSnake(a, b, 0, 0);

    assert(result == 0);
  }

  @("followSnake advances from middle position")
  unittest {
    auto a = toHeapString("xxabcdef");
    auto b = toHeapString("yyabcxyz");

    auto result = followSnake(a, b, 2, 2);

    assert(result == 5);
  }
}
