/// V-array with virtual negative indexing for Myers algorithm.
module fluentasserts.core.diff.varray;

import fluentasserts.core.memory.heapstring : HeapData;

@safe:

/// V-array storing x-coordinates for each k-diagonal (k = x - y).
/// Supports negative indexing via offset.
struct VArray {
private:
  HeapData!long data;
  long offset;

public:
  /// Creates a V-array for the given maximum edit distance.
  static VArray create(size_t maxD) @nogc nothrow {
    VArray v;
    v.offset = cast(long)(maxD + 1);
    auto size = 2 * maxD + 3;
    v.data = HeapData!long.create(size);

    foreach (i; 0 .. size) {
      v.data.put(-1);
    }

    return v;
  }

  /// Creates a copy of this VArray.
  VArray dup() @nogc nothrow const {
    VArray copy;
    copy.offset = offset;
    copy.data = HeapData!long.create(data.length);

    foreach (i; 0 .. data.length) {
      copy.data.put(data[i]);
    }

    return copy;
  }

  /// Access element at diagonal k (k can be negative).
  ref long opIndex(long k) @trusted @nogc nothrow {
    return data[cast(size_t)(k + offset)];
  }

  /// Const access element at diagonal k.
  long opIndex(long k) @trusted @nogc nothrow const {
    return data[cast(size_t)(k + offset)];
  }
}

version (unittest) {
  @("VArray supports negative indexing")
  unittest {
    auto v = VArray.create(5);

    v[-5] = 10;
    v[0] = 20;
    v[5] = 30;

    assert(v[-5] == 10);
    assert(v[0] == 20);
    assert(v[5] == 30);
  }

  @("VArray.dup creates independent copy")
  unittest {
    auto v1 = VArray.create(3);
    v1[0] = 42;

    auto v2 = v1.dup();
    v2[0] = 99;

    assert(v1[0] == 42);
    assert(v2[0] == 99);
  }

  @("VArray initializes with -1")
  unittest {
    auto v = VArray.create(2);

    assert(v[-2] == -1);
    assert(v[-1] == -1);
    assert(v[0] == -1);
    assert(v[1] == -1);
    assert(v[2] == -1);
  }
}
