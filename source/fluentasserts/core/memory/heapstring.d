/// Heap-allocated dynamic array using malloc/free for @nogc contexts.
/// This is an alternative to FixedArray when dynamic sizing is needed.
///
/// Features:
/// - Small Buffer Optimization (SBO): stores small data inline to avoid heap allocation
/// - Reference counting for cheap copying of heap-allocated data
/// - Combined allocation: refCount stored with data to reduce malloc calls
///
/// Note: FixedArray is preferred for most use cases due to its simplicity
/// and performance (no malloc/free overhead). Use HeapData when:
/// - The data size is unbounded or unpredictable
/// - You need cheap copying via ref-counting
/// - Stack space is a co
module fluentasserts.core.memory.heapstring;

import core.stdc.stdlib : malloc, free, realloc;
import core.stdc.string : memcpy, memset;

@safe:

/// Heap-allocated dynamic array with ref-counting and small buffer optimization.
/// Uses malloc/free instead of GC for @nogc compatibility.
///
/// Small Buffer Optimization (SBO):
/// - Data up to SBO_SIZE elements is stored inline (no heap allocation)
/// - Larger data uses heap with reference counting
/// - SBO threshold is tuned to fit within L1 cache line
///
/// The postblit constructor handles reference counting automatically for
/// blit operations (memcpy), so manual incrementRefCount() calls are rarely needed.
struct HeapData(T) {
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

  /// Size of small buffer in bytes - fits data + metadata in cache line
  /// Reserve space for: length (size_t), capacity (size_t), discriminator flag
  private enum size_t SBO_BYTES = CACHE_LINE_SIZE - size_t.sizeof * 2 - 1;

  /// Number of elements that fit in small buffer
  private enum size_t SBO_SIZE = SBO_BYTES / T.sizeof > 0 ? SBO_BYTES / T.sizeof : 0;

  /// Minimum heap allocation to avoid tiny reallocs
  private enum size_t MIN_HEAP_CAPACITY = CACHE_LINE_SIZE / T.sizeof > SBO_SIZE
    ? CACHE_LINE_SIZE / T.sizeof : SBO_SIZE + 1;

  /// Check if T is a HeapData instantiation (for recursive cleanup)
  private enum isHeapData = is(T == HeapData!U, U);

  /// Heap payload: refCount stored at start of allocation, followed by data
  private struct HeapPayload {
    size_t refCount;
    size_t capacity;

    /// Get pointer to data area (immediately after header)
    inout(T)* dataPtr() @trusted @nogc nothrow inout {
      return cast(inout(T)*)(cast(inout(void)*)&this + HeapPayload.sizeof);
    }

    /// Allocate a new heap payload with given capacity
    static HeapPayload* create(size_t capacity) @trusted @nogc nothrow {
      size_t totalSize = HeapPayload.sizeof + capacity * T.sizeof;
      auto payload = cast(HeapPayload*) malloc(totalSize);
      if (payload) {
        payload.refCount = 1;
        payload.capacity = capacity;
        memset(payload.dataPtr(), 0, capacity * T.sizeof);
      }
      return payload;
    }

    /// Reallocate with new capacity
    static HeapPayload* realloc(HeapPayload* old, size_t newCapacity) @trusted @nogc nothrow {
      size_t totalSize = HeapPayload.sizeof + newCapacity * T.sizeof;
      auto payload = cast(HeapPayload*) .realloc(old, totalSize);
      if (payload && newCapacity > payload.capacity) {
        memset(payload.dataPtr() + payload.capacity, 0, (newCapacity - payload.capacity) * T.sizeof);
      }
      if (payload) {
        payload.capacity = newCapacity;
      }
      return payload;
    }
  }

  /// Union for small buffer optimization
  private union Payload {
    /// Small buffer for inline storage (no heap allocation)
    T[SBO_SIZE] small;

    /// Pointer to heap-allocated payload (refCount + data)
    HeapPayload* heap;
  }

  private {
    Payload _payload;
    size_t _length;
    ubyte _flags;  // bit 0: isHeap flag

    version (DebugHeapData) {
      size_t _creationId;
      static size_t _nextId = 0;
    }
  }

  /// Check if curr
  private bool isHeap() @nogc nothrow const {
    return (_flags & 1) != 0;
  }

  /// Set heap storage flag
  private void setHeap(bool value) @nogc nothrow {
    if (value) {
      _flags |= 1;
    } else {
      _flags &= ~1;
    }
  }

  /// Get pointer to data (either small buffer or heap)
  private inout(T)* dataPtr() @trusted @nogc nothrow inout {
    if (isHeap()) {
      return _payload.heap ? (cast(inout(HeapPayload)*) _payload.heap).dataPtr() : null;
    }
    return cast(inout(T)*) _payload.small.ptr;
  }

  /// Get current capacity
  private size_t capacity() @nogc nothrow const @trusted {
    if (isHeap()) {
      return _payload.heap ? _payload.heap.capacity : 0;
    }
    return SBO_SIZE;
  }

  /// Creates a new HeapData with the given initial capacity.
  static HeapData create(size_t initialCapacity = 0) @trusted @nogc nothrow {
    HeapData h;
    h._flags = 0;
    h._length = 0;

    if (initialCapacity > SBO_SIZE) {
      size_t cap = initialCapacity < MIN_HEAP_CAPACITY ? MIN_HEAP_CAPACITY : initialCapacity;
      h._payload.heap = HeapPayload.create(cap);
      h.setHeap(true);
    }

    version (DebugHeapData) {
      h._creationId = _nextId++;
    }

    return h;
  }

  /// Transition from small buffer to heap when capacity exceeded
  private void transitionToHeap(size_t requiredCapacity) @trusted @nogc nothrow {
    size_t newCap = optimalCapacity(requiredCapacity);
    auto newPayload = HeapPayload.create(newCap);
    if (newPayload && _length > 0) {
      memcpy(newPayload.dataPtr(), _payload.small.ptr, _length * T.sizeof);
    }
    _payload.heap = newPayload;
    setHeap(true);
  }

  /// Appends a single item.
  void put(T item) @trusted @nogc nothrow {
    ensureCapacity(_length + 1);
    dataPtr()[_length++] = item;
  }

  /// Appends multiple items (for simple types).
  static if (!isHeapData) {
    void put(const(T)[] items) @trusted @nogc nothrow {
      reserve(items.length);

      auto ptr = dataPtr();
      foreach (item; items) {
        ptr[_length++] = item;
      }
    }

    /// Appends contents from another HeapData.
    void put(ref const HeapData other) @trusted @nogc nothrow {
      if (other._length == 0) {
        return;
      }
      put(other[]);
    }

    /// Appends contents from another HeapData (rvalue).
    void put(const HeapData other) @trusted @nogc nothrow {
      if (other._length == 0) {
        return;
      }
      put(other[]);
    }
  }

  /// Returns the contents as a slice.
  inout(T)[] opSlice() @nogc nothrow @trusted inout {
    if (_length == 0) {
      return null;
    }
    return dataPtr()[0 .. _length];
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
    return dataPtr()[i];
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

  /// Removes the last element (if any).
  void popBack() @nogc nothrow {
    if (_length > 0) {
      _length--;
    }
  }

  /// Truncates to a specific length (if shorter than current).
  void truncate(size_t newLength) @nogc nothrow {
    if (newLength < _length) {
      _length = newLength;
    }
  }

  /// Returns the current length (for $ in slices).
  size_t opDollar() @nogc nothrow const {
    return _length;
  }

  /// Equality comparison with a slice (e.g., HeapString == "hello").
  bool opEquals(const(T)[] other) @nogc nothrow const @trusted {
    if (_length != other.length) {
      return false;
    }

    if (_length == 0) {
      return true;
    }

    auto ptr = dataPtr();
    foreach (i; 0 .. _length) {
      if (ptr[i] != other[i]) {
        return false;
      }
    }

    return true;
  }

  /// Equality comparison with another HeapData.
  bool opEquals(ref const HeapData other) @nogc nothrow const @trusted {
    if (_length != other._length) {
      return false;
    }

    if (_length == 0) {
      return true;
    }

    auto ptr = dataPtr();
    auto otherPtr = other.dataPtr();

    if (ptr is otherPtr) {
      return true;
    }

    foreach (i; 0 .. _length) {
      if (ptr[i] != otherPtr[i]) {
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
  private size_t optimalCapacity(size_t required) @nogc nothrow const {
    if (required <= SBO_SIZE) {
      return SBO_SIZE;
    }

    if (required < MIN_HEAP_CAPACITY) {
      return MIN_HEAP_CAPACITY;
    }

    // Growth factor: 1.5x is good balance between memory waste and realloc frequency
    size_t currentCap = capacity();
    size_t growthBased = currentCap + (currentCap >> 1);
    size_t target = growthBased > required ? growthBased : required;

    // Round up to cache-aligned element count
    size_t bytesNeeded = target * T.sizeof;
    size_t alignedBytes = alignToCache(bytesNeeded);

    return alignedBytes / T.sizeof;
  }

  /// Ensure capacity for at least `needed` total elements.
  private void ensureCapacity(size_t needed) @trusted @nogc nothrow {
    if (needed <= capacity()) {
      return;
    }

    if (!isHeap()) {
      transitionToHeap(needed);
      return;
    }

    size_t newCap = optimalCapacity(needed);
    _payload.heap = HeapPayload.realloc(_payload.heap, newCap);
  }

  /// Pre-allocate space for additional items.
  void reserve(size_t additionalCount) @trusted @nogc nothrow {
    ensureCapacity(_length + additionalCount);
  }

  /// Manually increment ref count. Used to prepare for blit operations
  /// where D's memcpy won't call copy constructors.
  /// Note: With SBO, this only applies to heap-allocated data.
  void incrementRefCount() @trusted @nogc nothrow {
    if (isHeap() && _payload.heap) {
      _payload.heap.refCount++;
    }
  }

  /// Returns true if this HeapData appears to be in a valid state.
  bool isValid() @trusted @nogc nothrow const {
    if (!isHeap()) {
      return true;  // Small buffer is always valid
    }

    if (_payload.heap is null) {
      return _length == 0;
    }

    if (_payload.heap.refCount == 0 || _payload.heap.refCount > 1_000_000) {
      return false;
    }

    return true;
  }

  /// Returns the current reference count (for debugging).
  /// Returns 0 for small buffer (no ref counting needed).
  size_t refCount() @trusted @nogc nothrow const {
    if (!isHeap()) {
      return 0;  // Small buffer doesn't use ref counting
    }
    return _payload.heap ? _payload.heap.refCount : 0;
  }

  /// Postblit constructor - called after D blits (memcpy) this struct.
  /// For heap data: increments ref count to account for the new copy.
  /// For small buffer: data is already copied by blit, nothing to do.
  this(this) @trusted @nogc nothrow {
    if (isHeap() && _payload.heap) {
      _payload.heap.refCount++;
    }
  }

  /// Assignment operator (properly handles ref counting).
  void opAssign(HeapData rhs) @trusted @nogc nothrow {
    // rhs is a copy (postblit already incremented refCount if heap)
    // So we just need to release our old data and take rhs's data

    // Release old data
    if (isHeap() && _payload.heap) {
      if (--_payload.heap.refCount == 0) {
        static if (isHeapData) {
          foreach (ref item; dataPtr()[0 .. _length]) {
            destroy(item);
          }
        }
        free(_payload.heap);
      }
    }

    // Take data from rhs
    _length = rhs._length;
    _flags = rhs._flags;
    _payload = rhs._payload;

    // Prevent rhs destructor from releasing
    rhs._payload.heap = null;
    rhs._flags = 0;
    rhs._length = 0;
  }

  /// Destructor (decrements ref count for heap, frees when zero).
  ~this() @trusted @nogc nothrow {
    if (!isHeap()) {
      return;  // Small buffer - nothing to free
    }

    if (_payload.heap is null) {
      return;
    }

    version (DebugHeapData) {
      if (_payload.heap.refCount == 0) {
        assert(false, "HeapData: Double-free detected!");
      }
      if (_payload.heap.refCount > 1_000_000) {
        assert(false, "HeapData: Corrupted ref count detected!");
      }
    }

    if (--_payload.heap.refCount == 0) {
      static if (isHeapData) {
        foreach (ref item; dataPtr()[0 .. _length]) {
          destroy(item);
        }
      }
      free(_payload.heap);
    }
  }

  /// Concatenation operator - creates new HeapData with combined contents.
  HeapData opBinary(string op : "~")(const(T)[] rhs) @trusted @nogc nothrow const {
    HeapData result;
    result.reserve(_length + rhs.length);

    auto ptr = dataPtr();
    foreach (i; 0 .. _length) {
      result.put(ptr[i]);
    }
    foreach (item; rhs) {
      result.put(item);
    }

    return result;
  }

  /// Concatenation operator with another HeapData.
  HeapData opBinary(string op : "~")(ref const HeapData rhs) @trusted @nogc nothrow const {
    HeapData result;
    result.reserve(_length + rhs._length);

    auto ptr = dataPtr();
    foreach (i; 0 .. _length) {
      result.put(ptr[i]);
    }

    auto rhsPtr = rhs.dataPtr();
    foreach (i; 0 .. rhs._length) {
      result.put(rhsPtr[i]);
    }

    return result;
  }

  /// Append operator - appends to this HeapData in place.
  void opOpAssign(string op : "~")(const(T)[] rhs) @trusted @nogc nothrow {
    reserve(rhs.length);
    auto ptr = dataPtr();
    foreach (item; rhs) {
      ptr[_length++] = item;
    }
  }

  /// Append operator with another HeapData.
  void opOpAssign(string op : "~")(ref const HeapData rhs) @trusted @nogc nothrow {
    reserve(rhs._length);
    auto ptr = dataPtr();
    auto rhsPtr = rhs.dataPtr();
    foreach (i; 0 .. rhs._length) {
      ptr[_length++] = rhsPtr[i];
    }
  }

  // Specializations for char type (string building)
  static if (is(T == char)) {
    /// Returns the current contents as a string slice.
    const(char)[] toString() @nogc nothrow @trusted const {
      if (_length == 0) {
        return null;
      }
      return dataPtr()[0 .. _length];
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

/// Converts a const(char)[] to HeapString.
HeapString toHeapString(const(char)[] s) @trusted nothrow @nogc {
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

  @("small buffer optimization stores short strings inline")
  unittest {
    auto h = HeapData!char.create();
    h.put("short");
    assert(h[] == "short", "short string should be stored");
    assert(h.refCount() == 0, "small buffer should not use ref counting");
  }

  @("small buffer transitions to heap when capacity exceeded")
  unittest {
    auto h = HeapData!char.create();
    // Add enough data to exceed SBO threshold (varies by arch: ~47 on x86-64, ~111 on ARM64)
    // Use a large enough value to exceed any architecture's SBO
    foreach (i; 0 .. 200) {
      h.put('x');
    }
    assert(h.length == 200, "should store all chars");
    assert(h.refCount() == 1, "heap allocation should have ref count of 1");
  }

  @("concatenation operator creates new HeapData with combined content")
  unittest {
    auto h = HeapData!char.create();
    h.put("hello");
    auto result = h ~ " world";
    assert(result[] == "hello world", "concatenation should combine strings");
    assert(h[] == "hello", "original should be unchanged");
  }

  @("concatenation of two HeapData instances")
  unittest {
    auto h1 = HeapData!char.create();
    h1.put("hello");
    auto h2 = HeapData!char.create();
    h2.put(" world");
    auto result = h1 ~ h2;
    assert(result[] == "hello world", "concatenation should combine HeapData instances");
  }

  @("append operator modifies HeapData in place")
  unittest {
    auto h = HeapData!char.create();
    h.put("hello");
    h ~= " world";
    assert(h[] == "hello world", "append should modify in place");
  }

  @("append HeapData to another HeapData")
  unittest {
    auto h1 = HeapData!char.create();
    h1.put("hello");
    auto h2 = HeapData!char.create();
    h2.put(" world");
    h1 ~= h2;
    assert(h1[] == "hello world", "append should combine HeapData instances");
  }

  @("copy of heap-allocated data shares reference")
  unittest {
    auto h1 = HeapData!char.create();
    // Force heap allocation with long string (200 chars exceeds any arch's SBO)
    foreach (i; 0 .. 200) {
      h1.put('x');
    }
    auto h2 = h1;
    assert(h1.refCount() == 2, "copy should share reference");
    assert(h2.refCount() == 2, "both should see same ref count");
  }

  @("copy of small buffer data is independent")
  unittest {
    auto h1 = HeapData!char.create();
    h1.put("short");
    auto h2 = h1;
    h2.put("!");  // Modify copy
    assert(h1[] == "short", "original should be unchanged");
    assert(h2[] == "short!", "copy should be modified");
  }

  @("combined allocation reduces malloc calls")
  unittest {
    // Create heap-allocated data (200 exceeds any arch's SBO)
    auto h = HeapData!char.create(200);
    h.put("test");
    // With combined allocation, refCount is stored with data
    // so only one malloc was needed (vs two in old implementation)
    assert(h.refCount() == 1, "heap data should have ref count");
    assert(h.isValid(), "data should be valid");
  }
}
