/// Fixed-size array for @nogc contexts.
/// Uses stack storage first, then spills overflow to heap.
module fluentasserts.core.array;

import fluentasserts.core.config : config = FluentAssertsConfig;

@safe:

/// Stack-allocated fixed-size buffer.
/// Simple wrapper around a static array with length tracking.
struct StackBuffer(T, size_t N) {
  private {
    T[N] _data = T.init;
    size_t _length;
  }

  /// Returns the current length.
  size_t length() @nogc nothrow const {
    return _length;
  }

  /// Returns remaining capacity.
  size_t available() @nogc nothrow const {
    return N - _length;
  }

  /// Returns true if buffer is full.
  bool full() @nogc nothrow const {
    return _length >= N;
  }

  /// Returns true if buffer is empty.
  bool empty() @nogc nothrow const {
    return _length == 0;
  }

  /// Appends an element. Returns true if successful.
  bool append(T elem) @nogc nothrow {
    if (_length < N) {
      _data[_length++] = elem;
      return true;
    }
    return false;
  }

  /// Appends multiple elements. Returns number appended.
  size_t append(const(T)[] elems) @nogc nothrow {
    auto space = N - _length;
    auto toAppend = elems.length < space ? elems.length : space;

    if (toAppend > 0) {
      _data[_length .. _length + toAppend] = elems[0 .. toAppend];
      _length += toAppend;
    }
    return toAppend;
  }

  /// Returns the contents as a slice.
  inout(T)[] opSlice() @nogc nothrow inout {
    return _data[0 .. _length];
  }

  /// Returns a slice with indices.
  inout(T)[] opSlice(size_t start, size_t end) @nogc nothrow inout {
    return _data[start .. end];
  }

  /// Index operator.
  inout(T) opIndex(size_t i) @nogc nothrow inout {
    return _data[i];
  }

  /// Clears the buffer.
  void clear() @nogc nothrow {
    _length = 0;
  }
}

/// Heap-allocated dynamic buffer.
/// Manages memory using malloc/realloc/free for @nogc compatibility.
struct HeapBuffer(T) {
  private {
    T* _data;
    size_t _length;
    size_t _capacity;
  }

  /// Destructor to free heap memory.
  ~this() @nogc nothrow {
    free();
  }

  /// Copy constructor from mutable.
  this(ref return scope HeapBuffer other) @trusted @nogc nothrow {
    copyFrom(other);
  }

  /// Copy constructor from const.
  this(ref return scope const HeapBuffer other) @trusted @nogc nothrow {
    copyFrom(other);
  }

  /// Assignment from const.
  void opAssign(ref const HeapBuffer other) @trusted @nogc nothrow {
    free();
    copyFrom(other);
  }

  private void copyFrom(ref const HeapBuffer other) @trusted @nogc nothrow {
    if (other._data !is null && other._length > 0) {
      _data = allocBuffer(other._length);
      if (_data !is null) {
        _length = other._length;
        _capacity = other._length;
        _data[0 .. _length] = other._data[0 .. other._length];
      }
    }
  }

  private void free() @nogc nothrow {
    if (_data !is null) {
      () @trusted {
        import core.stdc.stdlib : free;
        free(_data);
      }();
      _data = null;
      _length = 0;
      _capacity = 0;
    }
  }

  private static T* allocBuffer(size_t count) @nogc nothrow {
    return () @trusted {
      import core.stdc.stdlib : malloc;
      return cast(T*) malloc(count * T.sizeof);
    }();
  }

  /// Returns the current length.
  size_t length() @nogc nothrow const {
    return _length;
  }

  /// Returns true if buffer is empty.
  bool empty() @nogc nothrow const {
    return _length == 0;
  }

  /// Returns true if buffer has data.
  bool hasData() @nogc nothrow const {
    return _length > 0;
  }

  /// Appends an element.
  void append(T elem) @trusted @nogc nothrow {
    if (_length >= _capacity) {
      import core.stdc.stdlib : realloc;
      auto newCap = _capacity == 0 ? 16 : _capacity * 2;
      auto newData = cast(T*) realloc(_data, newCap * T.sizeof);
      if (newData is null) {
        return;
      }
      _data = newData;
      _capacity = newCap;
    }
    _data[_length++] = elem;
  }

  /// Appends multiple elements.
  void append(const(T)[] elems) @trusted @nogc nothrow {
    if (elems.length == 0) {
      return;
    }

    auto newLen = _length + elems.length;

    if (newLen > _capacity) {
      import core.stdc.stdlib : realloc;
      auto newCap = newLen * 2;
      auto newData = cast(T*) realloc(_data, newCap * T.sizeof);
      if (newData is null) {
        return;
      }
      _data = newData;
      _capacity = newCap;
    }

    _data[_length .. newLen] = elems[];
    _length = newLen;
  }

  /// Returns the contents as a slice.
  inout(T)[] opSlice() @trusted @nogc nothrow inout {
    if (_data is null) {
      return null;
    }
    return _data[0 .. _length];
  }

  /// Returns a slice with indices.
  inout(T)[] opSlice(size_t start, size_t end) @trusted @nogc nothrow inout {
    if (_data is null) {
      return null;
    }
    return _data[start .. end];
  }

  /// Index operator.
  inout(T) opIndex(size_t i) @trusted @nogc nothrow inout {
    return _data[i];
  }

  /// Clears the buffer (keeps capacity).
  void clear() @nogc nothrow {
    _length = 0;
  }
}

/// A fixed-size array that uses stack storage first (N elements),
/// then moves everything to heap on overflow.
/// This design ensures slicing always returns contiguous memory without allocation.
struct FixedArray(T, size_t N = 512) {
  private {
    T[N] _stack = T.init;
    T* _heap;
    size_t _length;
    size_t _heapCapacity;
    bool _usingHeap;
  }

  /// Destructor to free heap memory.
  ~this() @nogc nothrow {
    freeHeap();
  }

  /// Copy constructor from mutable.
  this(ref return scope FixedArray other) @trusted @nogc nothrow {
    copyFrom(other);
  }

  /// Copy constructor from const.
  this(ref return scope const FixedArray other) @trusted @nogc nothrow {
    copyFrom(other);
  }

  /// Assignment from const (by ref).
  void opAssign(ref const FixedArray other) @trusted @nogc nothrow {
    freeHeap();
    copyFrom(other);
  }

  /// Assignment from const (by value).
  void opAssign(const FixedArray other) @trusted @nogc nothrow {
    freeHeap();
    copyFrom(other);
  }

  private void copyFrom(ref const FixedArray other) @trusted @nogc nothrow {
    _length = other._length;
    _usingHeap = other._usingHeap;

    if (!_usingHeap) {
      _stack[0 .. _length] = other._stack[0 .. _length];
      _heap = null;
      return;
    }

    _heapCapacity = 0;
    _heapCapacity = other._heapCapacity;
    _heap = allocBuffer(_heapCapacity);

    if (_heap !is null && other._heap !is null) {
      _heap[0 .. _length] = other._heap[0 .. _length];
    }
  }

  private void freeHeap() @nogc nothrow {
    if (_heap !is null) {
      () @trusted {
        import core.stdc.stdlib : free;
        free(_heap);
      }();
      _heap = null;
      _heapCapacity = 0;
    }
  }

  private static T* allocBuffer(size_t count) @nogc nothrow {
    return () @trusted {
      import core.stdc.stdlib : malloc;
      return cast(T*) malloc(count * T.sizeof);
    }();
  }

  /// Moves stack data to heap when overflow occurs.
  private void moveToHeap(size_t minCapacity) @trusted @nogc nothrow {
    import core.stdc.stdlib : realloc;

    auto newCap = minCapacity < N * 2 ? N * 2 : minCapacity * 2;
    auto newHeap = cast(T*) realloc(_heap, newCap * T.sizeof);

    if (newHeap is null) {
      return;
    }

    // Copy stack data to heap
    newHeap[0 .. _length] = _stack[0 .. _length];
    _heap = newHeap;
    _heapCapacity = newCap;
    _usingHeap = true;
  }

  /// Grows heap capacity when needed.
  private void growHeap(size_t minCapacity) @trusted @nogc nothrow {
    import core.stdc.stdlib : realloc;

    auto newCap = _heapCapacity * 2;
    if (newCap < minCapacity) {
      newCap = minCapacity * 2;
    }

    auto newHeap = cast(T*) realloc(_heap, newCap * T.sizeof);
    if (newHeap !is null) {
      _heap = newHeap;
      _heapCapacity = newCap;
    }
  }

  /// Returns the current length.
  size_t length() @nogc nothrow const {
    return _length;
  }

  /// Appends an element. Uses stack first, moves to heap on overflow.
  void opOpAssign(string op : "~")(T elem) @nogc nothrow {
    if (_usingHeap) {
      if (_length >= _heapCapacity) {
        growHeap(_length + 1);
      }
      if (_length < _heapCapacity) {
        () @trusted { _heap[_length++] = elem; }();
      }
    } else if (_length < N) {
      _stack[_length++] = elem;
    } else {
      moveToHeap(_length + 1);
      if (_usingHeap && _length < _heapCapacity) {
        () @trusted { _heap[_length++] = elem; }();
      }
    }
  }

  /// Returns the full contents as a slice.
  inout(T)[] opSlice() @trusted @nogc nothrow inout {
    if (_usingHeap) {
      if (_heap is null) {
        return null;
      }
      return _heap[0 .. _length];
    }
    return _stack[0 .. _length];
  }

  /// Returns a slice with indices.
  inout(T)[] opSlice(size_t start, size_t end) @trusted @nogc nothrow inout {
    if (_usingHeap) {
      if (_heap is null) {
        return null;
      }
      return _heap[start .. end];
    }
    return _stack[start .. end];
  }

  /// Index operator.
  inout(T) opIndex(size_t i) @trusted @nogc nothrow inout {
    if (_usingHeap) {
      return _heap[i];
    }
    return _stack[i];
  }

  /// Clears the array.
  void clear() @nogc nothrow {
    _length = 0;
    // Keep heap allocated for reuse, but switch back to stack mode
    _usingHeap = false;
  }

  /// Returns true if the array is empty.
  bool empty() @nogc nothrow const {
    return _length == 0;
  }

  /// Returns the current length (for $ in slices).
  size_t opDollar() @nogc nothrow const {
    return _length;
  }

  /// Returns true if data is stored on heap.
  bool hasHeapData() @nogc const nothrow {
    return _usingHeap;
  }

  /// For char arrays: append a string slice.
  static if (is(T == char)) {
    /// Assignment from string slice.
    void opAssign(const(char)[] s) @nogc nothrow {
      clear();
      put(s);
    }

    /// Appends a string slice.
    void put(const(char)[] s) @trusted @nogc nothrow {
      if (s.length == 0) {
        return;
      }

      auto newLen = _length + s.length;

      if (_usingHeap) {
        if (newLen > _heapCapacity) {
          growHeap(newLen);
        }
        if (newLen <= _heapCapacity) {
          _heap[_length .. newLen] = s[];
          _length = newLen;
        }
      } else if (newLen <= N) {
        _stack[_length .. newLen] = s[];
        _length = newLen;
      } else {
        moveToHeap(newLen);
        if (_usingHeap && newLen <= _heapCapacity) {
          _heap[_length .. newLen] = s[];
          _length = newLen;
        }
      }
    }

    /// Returns the full contents as a string slice.
    const(char)[] toString() @nogc nothrow const {
      return opSlice();
    }
  }
}

/// Alias for backward compatibility - fixed char buffer for string building.
alias FixedAppender(size_t N = config.buffers.defaultFixedArraySize) = FixedArray!(char, N);

/// Alias for backward compatibility - fixed string reference array.
alias FixedStringArray(size_t N = config.buffers.defaultStringArraySize) = FixedArray!(string, N);

// Unit tests
version (unittest) {
  @("FixedArray: opOpAssign ~= appends elements sequentially")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    assert(arr[] == [1, 2, 3], "~= should append elements in order");
    assert(arr.length == 3, "length should match appended count");
  }

  @("FixedArray: opIndex returns element at specified position")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 10;
    arr ~= 20;
    arr ~= 30;
    assert(arr[0] == 10, "index 0 should return first element");
    assert(arr[1] == 20, "index 1 should return second element");
    assert(arr[2] == 30, "index 2 should return third element");
  }

  @("FixedArray: empty returns true initially, false after append, true after clear")
  unittest {
    FixedArray!(int, 10) arr;
    assert(arr.empty, "new array should be empty");
    arr ~= 1;
    assert(!arr.empty, "array with element should not be empty");
    arr.clear();
    assert(arr.empty, "cleared array should be empty");
  }

  @("FixedArray: string element type stores references correctly")
  unittest {
    FixedArray!(string, 10) arr;
    arr ~= "one";
    arr ~= "two";
    arr ~= "three";
    assert(arr[] == ["one", "two", "three"], "should store string references");
  }

  @("FixedArray: append beyond stack capacity spills to heap")
  unittest {
    FixedArray!(int, 3) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    arr ~= 4;
    assert(arr[] == [1, 2, 3, 4], "should contain all 4 elements");
    assert(arr.length == 4, "length should include heap elements");
    assert(arr.hasHeapData(), "should have heap data");
  }

  @("FixedArray char: put appends characters and updates length")
  unittest {
    FixedArray!(char, 64) buf;
    buf.put("hello");
    assert(buf[] == "hello", "slice should return put string");
    assert(buf.length == 5, "length should equal string length");
  }

  @("FixedArray char: put called multiple times concatenates content")
  unittest {
    FixedArray!(char, 64) buf;
    buf.put("hello");
    buf.put(" ");
    buf.put("world");
    assert(buf[] == "hello world", "multiple puts should concatenate");
  }

  @("FixedArray char: opAssign clears buffer and replaces with new content")
  unittest {
    FixedArray!(char, 64) buf;
    buf = "test";
    assert(buf[] == "test", "assignment should set content");
    buf = "replaced";
    assert(buf[] == "replaced", "second assignment should replace content");
  }

  @("FixedArray char: put spills to heap when exceeding stack capacity")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello world");
    assert(buf.toString() == "hello world", "should contain full string via heap spillover");
    assert(buf.length == 11, "length should equal full string length");
    assert(buf.hasHeapData(), "should have heap data");
  }

  @("FixedArray char: put stays on stack when within capacity")
  unittest {
    FixedArray!(char, 20) buf;
    buf.put("hello");
    assert(buf.toString() == "hello", "should contain string");
    assert(buf.length == 5, "length should equal string length");
    assert(!buf.hasHeapData(), "should not have heap data");
  }

  @("FixedArray char: clear resets buffer")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello world");
    assert(buf.hasHeapData(), "should have heap data before clear");
    buf.clear();
    assert(buf.empty(), "should be empty after clear");
  }

  @("FixedArray char: copy preserves heap data")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello world");
    auto copy = buf;
    assert(copy.toString() == "hello world", "copy should have same content");
    assert(copy.hasHeapData(), "copy should have heap data");
  }

  @("FixedArray char: multiple puts accumulate in heap")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello");
    buf.put(" ");
    buf.put("world");
    assert(buf.toString() == "hello world", "should accumulate all puts");
    assert(buf.length == 11, "length should be total");
  }

  @("FixedArray char: slice works after heap spillover")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello world");
    assert(buf[0 .. 5] == "hello", "first part slice should work");
    assert(buf[6 .. 11] == "world", "second part slice should work");
    assert(buf[3 .. 8] == "lo wo", "middle slice should work");
  }

  @("FixedAppender alias provides char buffer functionality")
  unittest {
    FixedAppender!64 buf;
    buf.put("test");
    assert(buf[] == "test", "FixedAppender should work as char buffer");
  }

  @("FixedStringArray alias provides string array functionality")
  unittest {
    FixedStringArray!10 arr;
    arr ~= "item";
    assert(arr[] == ["item"], "FixedStringArray should store strings");
  }

  // Additional comprehensive tests

  @("FixedArray: length returns 0 for empty array")
  unittest {
    FixedArray!(int, 10) arr;
    assert(arr.length == 0, "empty array should have length 0");
  }

  @("FixedArray: opDollar returns correct length for $ in slices")
  unittest {
    FixedArray!(int, 5) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    assert(arr[0 .. $] == [1, 2, 3], "$ should equal length");
    assert(arr[1 .. $] == [2, 3], "$ should work with offset");
  }

  @("FixedArray: opDollar works with heap spillover")
  unittest {
    FixedArray!(int, 2) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    arr ~= 4;
    assert(arr[0 .. $] == [1, 2, 3, 4], "$ should include heap elements");
    assert(arr[2 .. $] == [3, 4], "$ should work for heap-only slice");
  }

  @("FixedArray: opIndex works after heap spillover")
  unittest {
    FixedArray!(int, 2) arr;
    arr ~= 10;
    arr ~= 20;
    arr ~= 30;
    arr ~= 40;
    assert(arr[0] == 10, "index 0 correct");
    assert(arr[1] == 20, "index 1 correct");
    assert(arr[2] == 30, "index 2 correct");
    assert(arr[3] == 40, "index 3 correct");
  }

  @("FixedArray: copy constructor preserves stack-only data")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    auto copy = arr;
    assert(copy[] == [1, 2, 3], "copy should have same content");
    assert(!copy.hasHeapData(), "copy should not have heap data");
  }

  @("FixedArray: copy constructor creates independent copy")
  unittest {
    FixedArray!(int, 2) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    auto copy = arr;
    arr ~= 4;
    assert(arr[] == [1, 2, 3, 4], "original should have 4 elements");
    assert(copy[] == [1, 2, 3], "copy should still have 3 elements");
  }

  @("FixedArray: assignment operator works correctly")
  unittest {
    FixedArray!(int, 3) arr1;
    arr1 ~= 1;
    arr1 ~= 2;

    FixedArray!(int, 3) arr2;
    arr2 ~= 10;
    arr2 ~= 20;
    arr2 ~= 30;
    arr2 ~= 40;

    arr1 = arr2;
    assert(arr1[] == [10, 20, 30, 40], "assignment should copy all data");
    assert(arr1.hasHeapData(), "assignment should copy heap data");
  }

  @("FixedArray: clear does not deallocate heap (reuses capacity)")
  unittest {
    FixedArray!(int, 2) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    assert(arr.hasHeapData(), "should have heap data");
    arr.clear();
    assert(arr.empty(), "should be empty after clear");
    assert(arr.length == 0, "length should be 0");
    arr ~= 100;
    assert(arr[] == [100], "should work after clear");
  }

  @("FixedArray: many elements trigger heap reallocation")
  unittest {
    FixedArray!(int, 2) arr;
    foreach (i; 0 .. 100) {
      arr ~= cast(int) i;
    }
    assert(arr.length == 100, "should have 100 elements");
    assert(arr[0] == 0, "first element correct");
    assert(arr[50] == 50, "middle element correct");
    assert(arr[99] == 99, "last element correct");
  }

  @("FixedArray: slicing works after heap spillover")
  unittest {
    FixedArray!(int, 3) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    arr ~= 4;
    arr ~= 5;
    assert(arr[0 .. 3] == [1, 2, 3], "first three elements");
    assert(arr[3 .. 5] == [4, 5], "last two elements");
  }

  @("FixedArray: empty slice returns empty array")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 1;
    arr ~= 2;
    assert(arr[1 .. 1].length == 0, "empty slice should have length 0");
  }

  @("FixedArray char: put empty string does nothing")
  unittest {
    FixedArray!(char, 10) buf;
    buf.put("hello");
    buf.put("");
    assert(buf[] == "hello", "empty put should not change content");
    assert(buf.length == 5, "length should remain 5");
  }

  @("FixedArray char: put exactly fills stack")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello");
    assert(buf[] == "hello", "should contain exactly 5 chars");
    assert(buf.length == 5, "length should be 5");
    assert(!buf.hasHeapData(), "should not have heap data");
  }

  @("FixedArray char: put one char over stack capacity")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello!");
    assert(buf.toString() == "hello!", "should contain 6 chars");
    assert(buf.length == 6, "length should be 6");
    assert(buf.hasHeapData(), "should have heap data for 1 char");
  }

  @("FixedArray char: append single chars with ~=")
  unittest {
    FixedArray!(char, 3) buf;
    buf ~= 'a';
    buf ~= 'b';
    buf ~= 'c';
    buf ~= 'd';
    assert(buf.toString() == "abcd", "should append single chars");
    assert(buf.hasHeapData(), "should have heap data");
  }

  @("FixedArray char: index returns correct char after heap spillover")
  unittest {
    FixedArray!(char, 3) buf;
    buf.put("abcdef");
    assert(buf[0] == 'a', "index 0 correct");
    assert(buf[2] == 'c', "index 2 correct");
    assert(buf[3] == 'd', "index 3 correct");
    assert(buf[5] == 'f', "index 5 correct");
  }

  @("FixedArray char: assignment replaces existing heap data")
  unittest {
    FixedArray!(char, 3) buf;
    buf.put("hello world");
    assert(buf.hasHeapData(), "should have heap data");
    buf = "hi";
    assert(buf[] == "hi", "should replace with new content");
    assert(!buf.hasHeapData(), "should not have heap data anymore");
  }

  @("FixedArray char: multiple puts after heap spillover")
  unittest {
    FixedArray!(char, 3) buf;
    buf.put("abc");
    buf.put("def");
    buf.put("ghi");
    assert(buf.toString() == "abcdefghi", "should accumulate all puts");
    assert(buf.length == 9, "length should be 9");
  }

  @("FixedArray: works with struct element type")
  unittest {
    struct Point {
      int x, y;
    }
    FixedArray!(Point, 2) arr;
    arr ~= Point(1, 2);
    arr ~= Point(3, 4);
    arr ~= Point(5, 6);
    assert(arr.length == 3, "should have 3 points");
    assert(arr[0].x == 1 && arr[0].y == 2, "first point correct");
    assert(arr[2].x == 5 && arr[2].y == 6, "heap point correct");
  }

  @("FixedArray: hasHeapData returns false when only using stack")
  unittest {
    FixedArray!(int, 100) arr;
    foreach (i; 0 .. 50) {
      arr ~= cast(int) i;
    }
    assert(!arr.hasHeapData(), "should not have heap data");
    assert(arr.length == 50, "should have 50 elements");
  }

  @("FixedArray: slice from 0 to length equals full slice")
  unittest {
    FixedArray!(int, 3) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    arr ~= 4;
    assert(arr[0 .. arr.length] == arr[], "explicit slice should equal implicit");
  }

  @("FixedArray char: toString on empty buffer returns empty")
  unittest {
    FixedArray!(char, 10) buf;
    assert(buf.toString() == "", "empty buffer toString should return empty");
    assert(buf.toString().length == 0, "empty buffer toString length should be 0");
  }

  @("FixedArray char: large string entirely in heap")
  unittest {
    FixedArray!(char, 2) buf;
    buf.put("abcdefghijklmnopqrstuvwxyz");
    assert(buf.toString() == "abcdefghijklmnopqrstuvwxyz", "large string should work");
    assert(buf.length == 26, "length should be 26");
    assert(buf.hasHeapData(), "should have heap data");
  }

  @("FixedArray: copy of empty array works")
  unittest {
    FixedArray!(int, 10) arr;
    auto copy = arr;
    assert(copy.empty(), "copy of empty should be empty");
    assert(copy.length == 0, "copy length should be 0");
  }

  @("FixedArray: assignment of empty array clears destination")
  unittest {
    FixedArray!(int, 3) arr1;
    arr1 ~= 1;
    arr1 ~= 2;
    arr1 ~= 3;
    arr1 ~= 4;

    FixedArray!(int, 3) arr2;
    arr1 = arr2;
    assert(arr1.empty(), "should be empty after assignment from empty");
  }
}
