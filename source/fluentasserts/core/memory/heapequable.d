/// Heap-allocated equable value supporting both string and opEquals comparison.
/// Stores object references for proper opEquals-based comparison when available.
module fluentasserts.core.memory.heapequable;

import core.stdc.stdlib : malloc, free;
import core.stdc.string : memset;

import fluentasserts.core.memory.heapstring;
import fluentasserts.core.conversion.floats : parseDouble;

@safe:

/// A heap-allocated wrapper for comparing values.
/// Supports both string-based comparison and opEquals for objects.
struct HeapEquableValue {
  enum Kind : ubyte { empty, scalar, array, assocArray }

  HeapString _serialized;
  Kind _kind;
  HeapEquableValue* _elements;
  size_t _elementCount;
  Object _objectRef;  // For opEquals comparison

  // --- Factory methods ---

  static HeapEquableValue create() @nogc nothrow {
    HeapEquableValue result;
    result._kind = Kind.empty;
    return result;
  }

  static HeapEquableValue createScalar(const(char)[] serialized) @nogc nothrow {
    HeapEquableValue result;
    result._kind = Kind.scalar;
    result._serialized = toHeapString(serialized);
    return result;
  }

  static HeapEquableValue createArray(const(char)[] serialized) @nogc nothrow {
    HeapEquableValue result;
    result._kind = Kind.array;
    result._serialized = toHeapString(serialized);
    return result;
  }

  static HeapEquableValue createAssocArray(const(char)[] serialized) @nogc nothrow {
    HeapEquableValue result;
    result._kind = Kind.assocArray;
    result._serialized = toHeapString(serialized);
    return result;
  }

  static HeapEquableValue createObject(const(char)[] serialized, Object obj) nothrow {
    HeapEquableValue result;
    result._kind = Kind.scalar;
    result._serialized = toHeapString(serialized);
    result._objectRef = obj;
    return result;
  }

  // --- Accessors ---

  Kind kind() @nogc nothrow const { return _kind; }
  const(char)[] getSerialized() @nogc nothrow const { return _serialized[]; }
  const(char)[] opSlice() @nogc nothrow const { return _serialized[]; }
  bool isNull() @nogc nothrow const { return _kind == Kind.empty; }
  bool isArray() @nogc nothrow const { return _kind == Kind.array; }
  size_t elementCount() @nogc nothrow const { return _elementCount; }
  Object getObjectRef() @nogc nothrow const @trusted { return cast(Object)_objectRef; }

  // --- Comparison ---

  bool isEqualTo(ref const HeapEquableValue other) nothrow const @trusted {
    // If both have object references, use opEquals
    if (_objectRef !is null && other._objectRef !is null) {
      return objectEquals(cast(Object)_objectRef, cast(Object)other._objectRef);
    }

    // If only one has object reference, not equal
    if (_objectRef !is null || other._objectRef !is null) {
      return false;
    }

    // Try string comparison first
    if (_serialized == other._serialized) {
      return true;
    }

    // For scalars, try numeric comparison (handles double vs int, scientific notation)
    if (_kind == Kind.scalar && other._kind == Kind.scalar) {
      return numericEquals(_serialized[], other._serialized[]);
    }

    return false;
  }

  bool isEqualTo(const HeapEquableValue other) nothrow const @trusted {
    // If both have object references, use opEquals
    if (_objectRef !is null && other._objectRef !is null) {
      return objectEquals(cast(Object)_objectRef, cast(Object)other._objectRef);
    }

    // If only one has object reference, not equal
    if (_objectRef !is null || other._objectRef !is null) {
      return false;
    }

    // Try string comparison first
    if (_serialized == other._serialized) {
      return true;
    }

    // For scalars, try numeric comparison (handles double vs int, scientific notation)
    if (_kind == Kind.scalar && other._kind == Kind.scalar) {
      return numericEquals(_serialized[], other._serialized[]);
    }

    return false;
  }

  /// Compares two string representations as numbers if both are numeric.
  /// Uses relative epsilon comparison for floating point tolerance.
  private static bool numericEquals(const(char)[] a, const(char)[] b) @nogc nothrow pure @safe {
    bool aIsNum, bIsNum;
    double aVal = parseDouble(a, aIsNum);
    double bVal = parseDouble(b, bIsNum);

    if (aIsNum && bIsNum) {
      return approxEqual(aVal, bVal);
    }

    return false;
  }

  /// Approximate equality check for floating point numbers.
  /// Uses relative epsilon for large numbers and absolute epsilon for small numbers.
  private static bool approxEqual(double a, double b) @nogc nothrow pure @safe {
    import core.stdc.math : fabs;

    // Handle exact equality (including infinities)
    if (a == b) {
      return true;
    }

    double diff = fabs(a - b);
    double larger = fabs(a) > fabs(b) ? fabs(a) : fabs(b);

    // Use relative epsilon scaled to the magnitude of the numbers
    // For numbers around 1e6, epsilon of ~1e-9 relative gives ~1e-3 absolute tolerance
    enum double relEpsilon = 1e-9;
    enum double absEpsilon = 1e-9;

    return diff <= larger * relEpsilon || diff <= absEpsilon;
  }

  bool isLessThan(ref const HeapEquableValue other) @nogc nothrow const @trusted {
    if (_kind == Kind.array || _kind == Kind.assocArray) {
      return false;
    }

    bool thisIsNum, otherIsNum;
    double thisVal = parseDouble(_serialized[], thisIsNum);
    double otherVal = parseDouble(other._serialized[], otherIsNum);

    // Try to extract numbers from wrapper types like "Checked!(long, Abort)(5)"
    if (!thisIsNum) {
      thisVal = extractWrappedNumber(_serialized[], thisIsNum);
    }
    if (!otherIsNum) {
      otherVal = extractWrappedNumber(other._serialized[], otherIsNum);
    }

    if (thisIsNum && otherIsNum) {
      return thisVal < otherVal;
    }

    return _serialized[] < other._serialized[];
  }

  /// Extracts a number from wrapper type notation like "Type(123)" or "Type(-45.6)"
  private static double extractWrappedNumber(const(char)[] s, out bool success) @nogc nothrow {
    success = false;
    if (s.length == 0) {
      return 0;
    }

    // Find the last '(' and matching ')'
    ptrdiff_t lastParen = -1;
    foreach_reverse (i, c; s) {
      if (c == '(') {
        lastParen = i;
        break;
      }
    }

    if (lastParen < 0 || lastParen >= cast(ptrdiff_t)(s.length - 1)) {
      return 0;
    }

    // Check if it ends with ')'
    if (s[$ - 1] != ')') {
      return 0;
    }

    // Extract content between parentheses
    auto content = s[lastParen + 1 .. $ - 1];
    return parseDouble(content, success);
  }

  // --- Array operations ---

  void addElement(HeapEquableValue element) @trusted @nogc nothrow {
    if (_kind != Kind.array && _kind != Kind.assocArray) {
      return;
    }

    auto newCount = _elementCount + 1;
    auto newElements = allocateHeapEquableArray(newCount);
    if (newElements is null) {
      return;
    }

    copyHeapEquableArray(_elements, newElements, _elementCount);
    copyHeapEquableElement(&newElements[_elementCount], element);
    freeHeapEquableArray(_elements, _elementCount);

    _elements = newElements;
    _elementCount = newCount;
  }

  ref const(HeapEquableValue) getElement(size_t index) @nogc nothrow const @trusted {
    static HeapEquableValue empty;

    if (_elements is null || index >= _elementCount) {
      return empty;
    }

    return _elements[index];
  }

  int opApply(scope int delegate(ref const HeapEquableValue) @safe nothrow dg) @trusted nothrow const {
    foreach (i; 0 .. _elementCount) {
      auto result = dg(_elements[i]);
      if (result) {
        return result;
      }
    }
    return 0;
  }

  HeapEquableValue[] toArray() @trusted nothrow {
    if (_kind == Kind.scalar || _kind == Kind.empty) {
      return allocateSingleGCElement(this);
    }

    if (_elements is null || _elementCount == 0) {
      return [];
    }

    return copyToGCArray(_elements, _elementCount);
  }

  // --- Copy semantics ---

  @disable this(this);

  this(ref return scope const HeapEquableValue rhs) @trusted nothrow {
    _serialized = rhs._serialized;
    _kind = rhs._kind;
    _elements = duplicateHeapEquableArray(rhs._elements, rhs._elementCount);
    _elementCount = (_elements !is null) ? rhs._elementCount : 0;
    _objectRef = cast(Object) rhs._objectRef;
  }

  void opAssign(ref const HeapEquableValue rhs) @trusted nothrow {
    freeHeapEquableArray(_elements, _elementCount);

    _serialized = rhs._serialized;
    _kind = rhs._kind;
    _elements = duplicateHeapEquableArray(rhs._elements, rhs._elementCount);
    _elementCount = (_elements !is null) ? rhs._elementCount : 0;
    _objectRef = cast(Object) rhs._objectRef;
  }

  void opAssign(HeapEquableValue rhs) @trusted nothrow {
    freeHeapEquableArray(_elements, _elementCount);

    _serialized = rhs._serialized;
    _kind = rhs._kind;
    _elementCount = rhs._elementCount;
    _elements = rhs._elements;
    _objectRef = rhs._objectRef;

    rhs._elements = null;
    rhs._elementCount = 0;
    rhs._objectRef = null;
  }

  ~this() @trusted @nogc nothrow {
    freeHeapEquableArray(_elements, _elementCount);
    _elements = null;
    _elementCount = 0;
  }

  void incrementRefCount() @trusted @nogc nothrow {
    _serialized.incrementRefCount();
  }
}

// --- Module-level memory helpers ---

HeapEquableValue* allocateHeapEquableArray(size_t count) @trusted @nogc nothrow {
  auto ptr = cast(HeapEquableValue*) malloc(count * HeapEquableValue.sizeof);

  if (ptr !is null) {
    memset(ptr, 0, count * HeapEquableValue.sizeof);
  }

  return ptr;
}

void copyHeapEquableArray(
  const HeapEquableValue* src,
  HeapEquableValue* dst,
  size_t count
) @trusted @nogc nothrow {
  if (src is null || count == 0) {
    return;
  }

  foreach (i; 0 .. count) {
    dst[i]._serialized = src[i]._serialized;
    dst[i]._kind = src[i]._kind;
    dst[i]._elementCount = src[i]._elementCount;
    dst[i]._elements = cast(HeapEquableValue*) src[i]._elements;
    dst[i]._serialized.incrementRefCount();
  }
}

void copyHeapEquableElement(HeapEquableValue* dst, ref HeapEquableValue src) @trusted @nogc nothrow {
  dst._serialized = src._serialized;
  dst._kind = src._kind;
  dst._elementCount = src._elementCount;
  dst._elements = src._elements;
  dst._serialized.incrementRefCount();
}

HeapEquableValue* duplicateHeapEquableArray(
  const HeapEquableValue* src,
  size_t count
) @trusted @nogc nothrow {
  if (src is null || count == 0) {
    return null;
  }

  auto dst = allocateHeapEquableArray(count);

  if (dst !is null) {
    copyHeapEquableArray(src, dst, count);
  }

  return dst;
}

void freeHeapEquableArray(HeapEquableValue* elements, size_t count) @trusted @nogc nothrow {
  if (elements is null) {
    return;
  }

  foreach (i; 0 .. count) {
    destroy(elements[i]);
  }
  free(elements);
}

HeapEquableValue[] allocateSingleGCElement(ref const HeapEquableValue value) @trusted nothrow {
  try {
    auto result = new HeapEquableValue[1];
    result[0] = value;
    return result;
  } catch (Exception) {
    return [];
  }
}

HeapEquableValue[] copyToGCArray(const HeapEquableValue* elements, size_t count) @trusted nothrow {
  try {
    auto result = new HeapEquableValue[count];
    foreach (i; 0 .. count) {
      result[i] = elements[i];
    }
    return result;
  } catch (Exception) {
    return [];
  }
}

HeapEquableValue toHeapEquableValue(const(char)[] serialized) @nogc nothrow {
  return HeapEquableValue.createScalar(serialized);
}

/// Compares two objects using opEquals.
/// Returns false if opEquals throws an exception.
bool objectEquals(Object a, Object b) @trusted nothrow {
  try {
    return a.opEquals(b);
  } catch (Exception) {
    return false;
  } catch (Error) {
    return false;
  }
}

version (unittest) {
  @("createScalar stores serialized value")
  unittest {
    auto v = HeapEquableValue.createScalar("test");
    assert(v.getSerialized() == "test");
    assert(v.kind() == HeapEquableValue.Kind.scalar);
  }

  @("isEqualTo compares serialized values")
  unittest {
    auto v1 = HeapEquableValue.createScalar("hello");
    auto v2 = HeapEquableValue.createScalar("hello");
    auto v3 = HeapEquableValue.createScalar("world");

    assert(v1.isEqualTo(v2));
    assert(!v1.isEqualTo(v3));
  }

  @("isEqualTo handles numeric comparison for double vs int")
  unittest {
    // 1003200.0 serialized as scientific notation vs integer
    auto doubleVal = HeapEquableValue.createScalar("1.0032e+06");
    auto intVal = HeapEquableValue.createScalar("1003200");

    assert(doubleVal.kind() == HeapEquableValue.Kind.scalar);
    assert(intVal.kind() == HeapEquableValue.Kind.scalar);
    assert(doubleVal.isEqualTo(intVal), "1.0032e+06 should equal 1003200");
    assert(intVal.isEqualTo(doubleVal), "1003200 should equal 1.0032e+06");
  }

  @("array type stores elements")
  unittest {
    auto arr = HeapEquableValue.createArray("[1, 2, 3]");
    arr.addElement(HeapEquableValue.createScalar("1"));
    arr.addElement(HeapEquableValue.createScalar("2"));
    arr.addElement(HeapEquableValue.createScalar("3"));

    assert(arr.elementCount() == 3);
    assert(arr.getElement(0).getSerialized() == "1");
    assert(arr.getElement(1).getSerialized() == "2");
    assert(arr.getElement(2).getSerialized() == "3");
  }

  @("copy creates independent copy")
  unittest {
    auto v1 = HeapEquableValue.createScalar("test");
    auto v2 = v1;
    assert(v2.getSerialized() == "test");
  }

  @("array copy creates independent copy")
  unittest {
    auto arr1 = HeapEquableValue.createArray("[1, 2]");
    arr1.addElement(HeapEquableValue.createScalar("1"));
    arr1.addElement(HeapEquableValue.createScalar("2"));

    auto arr2 = arr1;
    arr2.addElement(HeapEquableValue.createScalar("3"));

    assert(arr1.elementCount() == 2);
    assert(arr2.elementCount() == 3);
  }
}
