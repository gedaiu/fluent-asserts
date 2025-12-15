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
import core.stdc.string : memcpy, memset;

@safe:

/// Heap-allocated dynamic array with ref-counting.
/// Uses malloc/free instead of GC for @nogc compatibility.
///
/// IMPORTANT: When returning structs containing HeapData fields from functions,
/// you MUST call prepareForBlit() or incrementRefCount() before the return statement.
/// D uses blit (memcpy) for struct returns which doesn't call copy constructors.
///
/// Example:
/// ---
/// HeapString createString() {
///     auto result = toHeapString("hello");
///     result.incrementRefCount();  // Required before return!
///     return result;
/// }
/// ---
struct HeapData(T) {
  private {
    T* _data;
    size_t _length;
    size_t _capacity;
    size_t* _refCount;

    // Debug-mode tracking for detecting ref count issues
    version (DebugHeapData) {
      bool _blitPrepared;
      size_t _creationId;
      static size_t _nextId = 0;
    }
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

    // Zero-initialize data array to ensure clean state for types with opAssign
    if (h._data) {
      memset(h._data, 0, cap * T.sizeof);
    }

    if (h._refCount) {
      *h._refCount = 1;
    }

    version (DebugHeapData) {
      h._creationId = _nextId++;
      h._blitPrepared = false;
    }

    return h;
  }

  /// Initialize uninitialized HeapData in-place (avoids assignment issues).
  private void initInPlace(size_t initialCapacity = MIN_CAPACITY) @trusted @nogc nothrow {
    size_t cap = initialCapacity < MIN_CAPACITY ? MIN_CAPACITY : initialCapacity;
    _data = cast(T*) malloc(cap * T.sizeof);
    _capacity = cap;
    _length = 0;
    _refCount = cast(size_t*) malloc(size_t.sizeof);

    // Zero-initialize data array to ensure clean state for types with opAssign
    if (_data) {
      memset(_data, 0, cap * T.sizeof);
    }

    if (_refCount) {
      *_refCount = 1;
    }
  }

  /// Appends a single item.
  void put(T item) @trusted @nogc nothrow {
    if (_data is null) {
      initInPlace();
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
        initInPlace(items.length);
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

  /// Equality comparison with a slice (e.g., HeapString == "hello").
  bool opEquals(const(T)[] other) @nogc nothrow const @trusted {
    if (_data is null) {
      return other.length == 0;
    }

    if (_length != other.length) {
      return false;
    }

    foreach (i; 0 .. _length) {
      if (_data[i] != other[i]) {
        return false;
      }
    }

    return true;
  }

  /// Equality comparison with another HeapData.
  bool opEquals(ref const HeapData other) @nogc nothrow const @trusted {
    if (_data is other._data) {
      return true;
    }

    if (_data is null || other._data is null) {
      return _length == other._length;
    }

    if (_length != other._length) {
      return false;
    }

    foreach (i; 0 .. _length) {
      if (_data[i] != other._data[i]) {
        return false;
      }
    }

    return true;
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
    size_t oldCap = _capacity;
    size_t newCap = optimalCapacity(_length + 1);
    _data = cast(T*) realloc(_data, newCap * T.sizeof);

    // Zero-initialize new portion for types with opAssign
    if (_data && newCap > oldCap) {
      memset(_data + oldCap, 0, (newCap - oldCap) * T.sizeof);
    }

    _capacity = newCap;
  }

  /// Pre-allocate space for additional items.
  void reserve(size_t additionalCount) @trusted @nogc nothrow {
    size_t needed = _length + additionalCount;
    if (needed <= _capacity) {
      return;
    }

    size_t oldCap = _capacity;
    size_t newCap = optimalCapacity(needed);
    _data = cast(T*) realloc(_data, newCap * T.sizeof);

    // Zero-initialize new portion for types with opAssign
    if (_data && newCap > oldCap) {
      memset(_data + oldCap, 0, (newCap - oldCap) * T.sizeof);
    }

    _capacity = newCap;
  }

  /// Manually increment ref count. Used to prepare for blit operations
  /// where D's memcpy won't call copy constructors.
  ///
  /// Call this IMMEDIATELY before returning a HeapData or a struct containing
  /// HeapData fields from a function. D uses blit (memcpy) for returns which
  /// doesn't call copy constructors, causing ref count mismatches.
  void incrementRefCount() @trusted @nogc nothrow {
    if (_refCount) {
      (*_refCount)++;
      version (DebugHeapData) {
        _blitPrepared = true;
      }
    }
  }

  /// Returns true if this HeapData appears to be in a valid state.
  /// Useful for debug assertions.
  bool isValid() @trusted @nogc nothrow const {
    if (_data is null && _refCount is null) {
      return true;  // Uninitialized is valid
    }
    if (_data is null || _refCount is null) {
      return false;  // Partially initialized is invalid
    }
    if (*_refCount == 0 || *_refCount > 1_000_000) {
      return false;  // Invalid ref count
    }
    return true;
  }

  /// Returns the current reference count (for debugging).
  size_t refCount() @trusted @nogc nothrow const {
    return _refCount ? *_refCount : 0;
  }

  /// Postblit constructor - called after D blits (memcpy) this struct.
  /// Increments the ref count to account for the new copy.
  ///
  /// Using postblit instead of copy constructor because:
  /// 1. Postblit is called AFTER blit happens (perfect for ref count fix-up)
  /// 2. D's Tuple and other containers use blit internally
  /// 3. Copy constructors have incomplete druntime support for arrays/AAs
  ///
  /// With postblit, prepareForBlit() is NO LONGER NEEDED for HeapData itself,
  /// but still needed for structs containing HeapData when returning from functions
  /// (since the containing struct's postblit won't automatically fix nested HeapData).
  this(this) @trusted @nogc nothrow {
    if (_refCount) {
      (*_refCount)++;
    }
  }

  /// Assignment operator for lvalues (properly handles ref counting).
  void opAssign(ref HeapData rhs) @trusted @nogc nothrow {
    // Handle self-assignment: if same underlying data, nothing to do
    if (_data is rhs._data) {
      return;
    }

    // Decrement old ref count and free if needed
    if (_refCount && --(*_refCount) == 0) {
      static if (isHeapData) {
        foreach (ref item; _data[0 .. _length]) {
          destroy(item);
        }
      }
      free(_data);
      free(_refCount);
    }

    // Copy new data
    _data = rhs._data;
    _length = rhs._length;
    _capacity = rhs._capacity;
    _refCount = rhs._refCount;

    // Increment new ref count
    if (_refCount) {
      (*_refCount)++;
    }
  }

  /// Assignment operator for rvalues (takes ownership, no ref count change needed).
  void opAssign(HeapData rhs) @trusted @nogc nothrow {
    // For rvalues, D has already blitted the data to rhs.
    // We take ownership without incrementing ref count,
    // because rhs will be destroyed after this and decrement.

    // Decrement old ref count and free if needed
    if (_refCount && --(*_refCount) == 0) {
      static if (isHeapData) {
        foreach (ref item; _data[0 .. _length]) {
          destroy(item);
        }
      }
      free(_data);
      free(_refCount);
    }

    // Take ownership of rhs's data
    _data = rhs._data;
    _length = rhs._length;
    _capacity = rhs._capacity;
    _refCount = rhs._refCount;

    // Don't increment - rhs's destructor will decrement, balancing the original count
    // Actually, we need to prevent rhs's destructor from running.
    // Clear rhs's pointers so its destructor does nothing.
    rhs._data = null;
    rhs._refCount = null;
    rhs._length = 0;
    rhs._capacity = 0;
  }

  /// Destructor (decrements ref count, frees when zero).
  ~this() @trusted @nogc nothrow {
    version (DebugHeapData) {
      // Detect potential double-free or corruption
      if (_refCount !is null && *_refCount == 0) {
        // This indicates a double-free - ref count already zero
        assert(false, "HeapData: Double-free detected! Ref count already zero.");
      }
      if (_refCount !is null && *_refCount > 1_000_000) {
        // Likely garbage/corrupted pointer - ref count impossibly high
        assert(false, "HeapData: Corrupted ref count detected! Did you forget prepareForBlit()?");
      }
    }

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

/// Converts a string to HeapString.
HeapString toHeapString(string s) @trusted nothrow @nogc {
  auto h = HeapString.create(s.length);
  h.put(s);
  return h;
}

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

  @("opEquals compares HeapString with string literal")
  unittest {
    auto h = HeapData!char.create();
    h.put("hello");
    assert(h == "hello", "HeapString should equal matching string");
    assert(!(h == "world"), "HeapString should not equal different string");
  }

  @("opEquals handles empty HeapString")
  unittest {
    auto h = HeapData!char.create();
    assert(h == "", "empty HeapString should equal empty string");
    assert(!(h == "x"), "empty HeapString should not equal non-empty string");
  }

  @("opEquals handles uninitialized HeapData")
  unittest {
    HeapData!char h;
    assert(h == "", "uninitialized HeapData should equal empty string");
  }

  @("opEquals compares two HeapData instances")
  unittest {
    auto h1 = HeapData!int.create();
    h1.put([1, 2, 3]);
    auto h2 = HeapData!int.create();
    h2.put([1, 2, 3]);
    assert(h1 == h2, "HeapData with same content should be equal");
  }

  @("opEquals detects different HeapData content")
  unittest {
    auto h1 = HeapData!int.create();
    h1.put([1, 2, 3]);
    auto h2 = HeapData!int.create();
    h2.put([1, 2, 4]);
    assert(!(h1 == h2), "HeapData with different content should not be equal");
  }

  @("opEquals detects different HeapData lengths")
  unittest {
    auto h1 = HeapData!int.create();
    h1.put([1, 2, 3]);
    auto h2 = HeapData!int.create();
    h2.put([1, 2]);
    assert(!(h1 == h2), "HeapData with different lengths should not be equal");
  }

  @("opEquals returns true for same underlying data")
  unittest {
    auto h1 = HeapData!int.create();
    h1.put([1, 2, 3]);
    auto h2 = h1;  // Copy shares same data
    assert(h1 == h2, "copies sharing same data should be equal");
  }
}
