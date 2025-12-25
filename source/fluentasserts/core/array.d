/// Fixed-size array for @nogc contexts.
/// Preferred over HeapData for most use cases due to simplicity and performance.
///
/// Note: HeapData is available as an alternative when:
/// - The data size is unbounded or unpredictable
/// - You need cheap copying via ref-counting
/// - Stack space is a concern
module fluentasserts.core.array;

import fluentasserts.core.config : config = FluentAssertsConfig;

@safe:

/// A fixed-size array for storing elements without GC allocation.
/// Useful for @nogc contexts where dynamic arrays would normally be used.
/// Template parameter T is the element type (e.g., char for strings, string for string arrays).
struct FixedArray(T, size_t N = 512) {
  private {
    T[N] _data = T.init;
    size_t _length;
  }

  /// Returns the current length.
  size_t length() @nogc nothrow const {
    return _length;
  }

  /// Appends an element to the array.
  void opOpAssign(string op : "~")(T s) @nogc nothrow {
    if (_length < N) {
      _data[_length++] = s;
    }
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

  /// Clears the array.
  void clear() @nogc nothrow {
    _length = 0;
  }

  /// Returns true if the array is empty.
  bool empty() @nogc nothrow const {
    return _length == 0;
  }

  /// Returns the current length (for $ in slices).
  size_t opDollar() @nogc nothrow const {
    return _length;
  }

  // Specializations for char type (string building)
  static if (is(T == char)) {
    /// Appends a string slice to the buffer (char specialization).
    void put(const(char)[] s) @nogc nothrow {
      import std.algorithm : min;
      auto copyLen = min(s.length, N - _length);
      _data[_length .. _length + copyLen] = s[0 .. copyLen];
      _length += copyLen;
    }

    /// Assigns from a string (char specialization).
    void opAssign(const(char)[] s) @nogc nothrow {
      clear();
      put(s);
    }

    /// Returns the current contents as a string slice.
    const(char)[] toString() @nogc nothrow const {
      return _data[0 .. _length];
    }
  }
}

/// Alias for backward compatibility - fixed char buffer for string building.
/// Default size from config.buffers.defaultFixedArraySize.
alias FixedAppender(size_t N = config.buffers.defaultFixedArraySize) = FixedArray!(char, N);

/// Alias for backward compatibility - fixed string reference array.
/// Default size from config.buffers.defaultStringArraySize.
alias FixedStringArray(size_t N = config.buffers.defaultStringArraySize) = FixedArray!(string, N);

// Unit tests
version (unittest) {
  @("put(string) appends characters and updates length")
  unittest {
    FixedArray!(char, 64) buf;
    buf.put("hello");
    assert(buf[] == "hello", "slice should return put string");
    assert(buf.length == 5, "length should equal string length");
  }

  @("put(string) called multiple times concatenates content")
  unittest {
    FixedArray!(char, 64) buf;
    buf.put("hello");
    buf.put(" ");
    buf.put("world");
    assert(buf[] == "hello world", "multiple puts should concatenate");
  }

  @("opAssign clears buffer and replaces with new content")
  unittest {
    FixedArray!(char, 64) buf;
    buf = "test";
    assert(buf[] == "test", "assignment should set content");
    buf = "replaced";
    assert(buf[] == "replaced", "second assignment should replace content");
  }

  @("put(string) truncates input when exceeding capacity")
  unittest {
    FixedArray!(char, 5) buf;
    buf.put("hello world");
    assert(buf[] == "hello", "should truncate to capacity");
    assert(buf.length == 5, "length should equal capacity");
  }

  @("opOpAssign ~= appends elements sequentially")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    assert(arr[] == [1, 2, 3], "~= should append elements in order");
    assert(arr.length == 3, "length should match appended count");
  }

  @("opIndex returns element at specified position")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 10;
    arr ~= 20;
    arr ~= 30;
    assert(arr[0] == 10, "index 0 should return first element");
    assert(arr[1] == 20, "index 1 should return second element");
    assert(arr[2] == 30, "index 2 should return third element");
  }

  @("empty returns true initially, false after append, true after clear")
  unittest {
    FixedArray!(int, 10) arr;
    assert(arr.empty, "new array should be empty");
    arr ~= 1;
    assert(!arr.empty, "array with element should not be empty");
    arr.clear();
    assert(arr.empty, "cleared array should be empty");
    assert(arr.length == 0, "cleared array length should be 0");
  }

  @("string element type stores references correctly")
  unittest {
    FixedArray!(string, 10) arr;
    arr ~= "one";
    arr ~= "two";
    arr ~= "three";
    assert(arr[] == ["one", "two", "three"], "should store string references");
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

  @("opDollar enables $ syntax in slice expressions")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    assert(arr[0 .. $] == [1, 2, 3], "[0..$] should return all elements");
    assert(arr[1 .. $] == [2, 3], "[1..$] should return elements from index 1");
  }

  @("toString returns accumulated char content")
  unittest {
    FixedArray!(char, 64) buf;
    buf.put("hello world");
    assert(buf.toString() == "hello world", "toString should return buffer content");
  }

  @("append beyond capacity silently ignores excess elements")
  unittest {
    FixedArray!(int, 3) arr;
    arr ~= 1;
    arr ~= 2;
    arr ~= 3;
    arr ~= 4;
    assert(arr[] == [1, 2, 3], "should contain only first 3 elements");
    assert(arr.length == 3, "length should not exceed capacity");
  }

  @("opSlice with start and end returns subrange")
  unittest {
    FixedArray!(int, 10) arr;
    arr ~= 10;
    arr ~= 20;
    arr ~= 30;
    arr ~= 40;
    assert(arr[1 .. 3] == [20, 30], "[1..3] should return elements at index 1 and 2");
  }
}
