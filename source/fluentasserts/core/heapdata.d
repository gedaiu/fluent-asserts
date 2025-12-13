/// Heap-allocated dynamic array using malloc/free for @nogc contexts.
/// This is an alternative to FixedArray when dynamic sizing is needed.
///
/// Note: FixedArray is preferred for most use cases due to its simplicity
/// and performance (no malloc/free overhead). Use HeapData when:
/// - The data size is unbounded or unpredictable
/// - You need cheap copying via ref-counting
/// - Stack space is a concern
module fluentasserts.core.heapdata;

import core.stdc.stdlib : malloc, free, realloc;
import core.stdc.string : memcpy;

@safe:

/// Heap-allocated dynamic array with ref-counting.
/// Uses malloc/free instead of GC for @nogc compatibility.
struct HeapData(T) {
  private {
    T* _data;
    size_t _length;
    size_t _capacity;
    size_t* _refCount;
  }

  /// Cache line size varies by architecture
  private enum size_t CACHE_LINE_SIZE = {
    version (X86_64) {
      return 64;  // Intel/AMD x86-64: 64 bytes
    } else version (X86) {
      return 64;  // x86 32-bit: typically 64 bytes
    } else version (AArch64) {
      return 128; // ARM64 (Apple M1/M2, newer ARM): often 128 bytes
    } else version (ARM) {
      return 32;  // Older ARM 32-bit: typically 32 bytes
    } else {
      return 64;  // Safe default
    }
  }();

  /// Minimum allocation to avoid tiny reallocs
  private enum size_t MIN_CAPACITY = CACHE_LINE_SIZE / T.sizeof > 0 ? CACHE_LINE_SIZE / T.sizeof : 1;

  /// Check if T is a HeapData instantiation (for recursive cleanup)
  private enum isHeapData = is(T == HeapData!U, U);

  /// Creates a new HeapData with the given initial capacity.
  static HeapData create(size_t initialCapacity = MIN_CAPACITY) @trusted @nogc nothrow {
    HeapData h;
    size_t cap = initialCapacity < MIN_CAPACITY ? MIN_CAPACITY : initialCapacity;
    h._data = cast(T*) malloc(cap * T.sizeof);
    h._capacity = cap;
    h._length = 0;
    h._refCount = cast(size_t*) malloc(size_t.sizeof);

    if (h._refCount) {
      *h._refCount = 1;
    }

    return h;
  }

  /// Appends a single item.
  void put(T item) @trusted @nogc nothrow {
    if (_data is null) {
      this = create();
    }
    if (_length >= _capacity) {
      grow();
    }

    _data[_length++] = item;
  }

  /// Appends multiple items (for simple types).
  static if (!isHeapData) {
    void put(const(T)[] items) @trusted @nogc nothrow {
      if (_data is null) {
        this = create(items.length);
      } else {
        reserve(items.length);
      }

      foreach (item; items) {
        _data[_length++] = item;
      }
    }
  }

  /// Returns the contents as a slice.
  inout(T)[] opSlice() @nogc nothrow @trusted inout {
    if (_data is null) {
      return null;
    }
    return _data[0 .. _length];
  }

  /// Slice operator for creating a sub-HeapData.
  HeapData!T opSlice(size_t start, size_t end) @nogc nothrow @trusted const {
    HeapData!T result;

    foreach (i; start .. end) {
      result.put(cast(T) this[i]);
    }

    return result;
  }

  /// Index operator.
  ref inout(T) opIndex(size_t i) @nogc nothrow @trusted inout {
    return _data[i];
  }

  /// Returns the current length.
  size_t length() @nogc nothrow const {
    return _length;
  }

  /// Returns true if empty.
  bool empty() @nogc nothrow const {
    return _length == 0;
  }

  /// Clears the contents (does not free memory).
  void clear() @nogc nothrow {
    _length = 0;
  }

  /// Returns the current length (for $ in slices).
  size_t opDollar() @nogc nothrow const {
    return _length;
  }

  /// Align size up to cache line boundary.
  private static size_t alignToCache(size_t bytes) @nogc nothrow pure {
    return (bytes + CACHE_LINE_SIZE - 1) & ~(CACHE_LINE_SIZE - 1);
  }

  /// Calculate optimal new capacity.
  private size_t optimalCapacity(size_t required) @nogc nothrow pure {
    if (required < MIN_CAPACITY) {
      return MIN_CAPACITY;
    }

    // Growth factor: 1.5x is good balance between memory waste and realloc frequency
    size_t growthBased = _capacity + (_capacity >> 1);
    size_t target = growthBased > required ? growthBased : required;

    // Round up to cache-aligned element count
    size_t bytesNeeded = target * T.sizeof;
    size_t alignedBytes = alignToCache(bytesNeeded);

    return alignedBytes / T.sizeof;
  }

  private void grow() @trusted @nogc nothrow {
    size_t newCap = optimalCapacity(_length + 1);
    _data = cast(T*) realloc(_data, newCap * T.sizeof);
    _capacity = newCap;
  }

  /// Pre-allocate space for additional items.
  void reserve(size_t additionalCount) @trusted @nogc nothrow {
    size_t needed = _length + additionalCount;
    if (needed <= _capacity) {
      return;
    }

    size_t newCap = optimalCapacity(needed);
    _data = cast(T*) realloc(_data, newCap * T.sizeof);
    _capacity = newCap;
  }

  /// Copy constructor (increments ref count).
  this(ref return scope HeapData other) @trusted @nogc nothrow {
    _data = other._data;
    _length = other._length;
    _capacity = other._capacity;
    _refCount = other._refCount;

    if (_refCount) {
      (*_refCount)++;
    }
  }

  /// Destructor (decrements ref count, frees when zero).
  ~this() @trusted @nogc nothrow {
    if (_refCount && --(*_refCount) == 0) {
      // If T is HeapData, destroy each nested HeapData
      static if (isHeapData) {
        foreach (ref item; _data[0 .. _length]) {
          destroy(item);
        }
      }
      free(_data);
      free(_refCount);
    }
  }

  // Specializations for char type (string building)
  static if (is(T == char)) {
    /// Returns the current contents as a string slice.
    const(char)[] toString() @nogc nothrow @trusted const {
      if (_data is null) {
        return null;
      }
      return _data[0 .. _length];
    }
  }
}

/// Convenience aliases
alias HeapString = HeapData!char;
alias HeapStringList = HeapData!HeapString;

// Unit tests
version (unittest) {
  @("put(char) appends individual characters to buffer")
  unittest {
    auto h = HeapData!char.create();
    h.put('a');
    h.put('b');
    h.put('c');
    assert(h[] == "abc", "slice should return concatenated chars");
    assert(h.length == 3, "length should match number of chars added");
  }

  @("put(string) appends multiple string slices sequentially")
  unittest {
    auto h = HeapData!char.create();
    h.put("hello");
    h.put(" world");
    assert(h[] == "hello world", "multiple puts should concatenate strings");
  }

  @("toString returns accumulated char content as string slice")
  unittest {
    auto h = HeapData!char.create();
    h.put("test string");
    assert(h.toString() == "test string", "toString should return same content as slice");
  }

  @("toString returns null for uninitialized HeapData")
  unittest {
    HeapData!char h;
    assert(h.toString() is null, "uninitialized HeapData should return null from toString");
  }

  @("copy constructor shares data and destructor preserves original after copy is destroyed")
  unittest {
    auto h1 = HeapData!int.create();
    h1.put(42);
    {
      auto h2 = h1;
      assert(h2[] == [42], "copy should see same data as original");
    }
    assert(h1[] == [42], "original should remain valid after copy is destroyed");
  }

  @("automatic growth when capacity exceeded by repeated puts")
  unittest {
    auto h = HeapData!int.create(2);
    foreach (i; 0 .. 100) {
      h.put(cast(int) i);
    }
    assert(h.length == 100, "should hold all 100 elements after growth");
    assert(h[0] == 0, "first element should be 0");
    assert(h[99] == 99, "last element should be 99");
  }

  @("empty returns true for new HeapData, false after adding element")
  unittest {
    auto h = HeapData!int.create();
    assert(h.empty, "newly created HeapData should be empty");
    h.put(1);
    assert(!h.empty, "HeapData with element should not be empty");
  }

  @("clear resets length to zero but preserves capacity")
  unittest {
    auto h = HeapData!int.create();
    h.put(1);
    h.put(2);
    h.put(3);
    assert(h.length == 3, "should have 3 elements before clear");
    h.clear();
    assert(h.length == 0, "length should be 0 after clear");
    assert(h.empty, "should be empty after clear");
  }

  @("opIndex returns element at specified position")
  unittest {
    auto h = HeapData!int.create();
    h.put(10);
    h.put(20);
    h.put(30);
    assert(h[0] == 10, "index 0 should return first element");
    assert(h[1] == 20, "index 1 should return second element");
    assert(h[2] == 30, "index 2 should return third element");
  }

  @("opDollar returns current length for use in slice expressions")
  unittest {
    auto h = HeapData!int.create();
    h.put(1);
    h.put(2);
    h.put(3);
    assert(h.opDollar() == 3, "opDollar should equal length");
  }

  @("reserve pre-allocates capacity without modifying length")
  unittest {
    auto h = HeapData!int.create();
    h.put(1);
    assert(h.length == 1, "should have 1 element before reserve");
    h.reserve(100);
    assert(h.length == 1, "reserve should not change length");
    foreach (i; 0 .. 100) {
      h.put(cast(int) i);
    }
    assert(h.length == 101, "should have 101 elements after adding 100 more");
  }

  @("put on uninitialized struct auto-initializes with malloc")
  unittest {
    HeapData!int h;
    h.put(42);
    assert(h[] == [42], "auto-initialized HeapData should contain put value");
    assert(h.length == 1, "auto-initialized HeapData should have length 1");
  }

  @("put slice on uninitialized struct allocates with correct capacity")
  unittest {
    HeapData!int h;
    h.put([1, 2, 3]);
    assert(h[] == [1, 2, 3], "auto-initialized HeapData should contain all slice elements");
  }

  @("opSlice returns null for uninitialized struct without allocation")
  unittest {
    HeapData!int h;
    assert(h[] is null, "uninitialized HeapData slice should be null");
  }

  @("multiple put slices append in order")
  unittest {
    auto h = HeapData!int.create();
    h.put([1, 2]);
    h.put([3, 4]);
    h.put([5]);
    assert(h[] == [1, 2, 3, 4, 5], "consecutive put slices should append in order");
  }

  @("create with large initial capacity avoids reallocation")
  unittest {
    auto h = HeapData!int.create(1000);
    foreach (i; 0 .. 1000) {
      h.put(cast(int) i);
    }
    assert(h.length == 1000, "should hold 1000 elements without reallocation");
  }
}
