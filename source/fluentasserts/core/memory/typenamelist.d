/// Fixed-size list of type names for @nogc contexts.
/// Stores type names as HeapStrings with a maximum capacity.
module fluentasserts.core.memory.typenamelist;

import fluentasserts.core.memory.heapstring;

@safe:

/// Fixed-size list of type names using HeapStrings.
/// Designed to store type hierarchy information without GC allocation.
/// Maximum capacity is 8, which is sufficient for most type hierarchies.
struct TypeNameList {
    private enum MAX_SIZE = 8;

    private {
        HeapString[MAX_SIZE] _names;
        size_t _length;
    }

    /// Adds a type name to the list.
    void put(string name) @trusted nothrow @nogc {
        if (_length >= MAX_SIZE) {
            return;
        }

        _names[_length] = toHeapString(name);
        _length++;
    }

    /// Adds a type name from a const(char)[] slice.
    void put(const(char)[] name) @trusted nothrow @nogc {
        if (_length >= MAX_SIZE) {
            return;
        }

        _names[_length] = toHeapString(name);
        _length++;
    }

    /// Returns the number of type names stored.
    size_t length() @nogc nothrow const {
        return _length;
    }

    /// Returns true if the list is empty.
    bool empty() @nogc nothrow const {
        return _length == 0;
    }

    /// Increment ref counts for all contained HeapStrings.
    /// Used when this TypeNameList is copied via blit (memcpy).
    void incrementRefCount() @trusted @nogc nothrow {
        foreach (i; 0 .. _length) {
            _names[i].incrementRefCount();
        }
    }

    /// Returns the type name at the given index.
    ref inout(HeapString) opIndex(size_t i) @nogc nothrow inout return {
        return _names[i];
    }

    /// Iteration support (@nogc version).
    int opApply(scope int delegate(ref HeapString) @safe nothrow @nogc dg) @trusted nothrow @nogc {
        foreach (i; 0 .. _length) {
            if (auto result = dg(_names[i])) {
                return result;
            }
        }
        return 0;
    }

    /// Iteration support (non-@nogc version for compatibility).
    int opApply(scope int delegate(ref HeapString) @safe nothrow dg) @trusted nothrow {
        foreach (i; 0 .. _length) {
            if (auto result = dg(_names[i])) {
                return result;
            }
        }
        return 0;
    }

    /// Const iteration support.
    int opApply(scope int delegate(ref const HeapString) @safe nothrow @nogc dg) @trusted nothrow @nogc const {
        foreach (i; 0 .. _length) {
            if (auto result = dg(_names[i])) {
                return result;
            }
        }
        return 0;
    }

    /// Clears all type names.
    void clear() @nogc nothrow {
        _length = 0;
    }

    /// Postblit - HeapStrings handle their own ref counting.
    this(this) @trusted @nogc nothrow {
        // HeapStrings use postblit internally for ref counting
    }

    /// Copy constructor - creates a deep copy.
    this(ref return scope inout TypeNameList rhs) @trusted nothrow {
        _length = rhs._length;
        foreach (i; 0 .. _length) {
            _names[i] = rhs._names[i];
        }
    }

    /// Assignment operator (ref).
    void opAssign(ref const TypeNameList rhs) @trusted nothrow {
        _length = rhs._length;
        foreach (i; 0 .. _length) {
            _names[i] = rhs._names[i];
        }
    }

    /// Assignment operator (rvalue).
    void opAssign(TypeNameList rhs) @trusted nothrow {
        _length = rhs._length;
        foreach (i; 0 .. _length) {
            _names[i] = rhs._names[i];
        }
    }
}

version (unittest) {
    @("TypeNameList stores and retrieves type names")
    unittest {
        TypeNameList list;
        list.put("int");
        list.put("Object");

        assert(list.length == 2);
        assert(list[0][] == "int");
        assert(list[1][] == "Object");
    }

    @("TypeNameList iteration works")
    unittest {
        TypeNameList list;
        list.put("A");
        list.put("B");
        list.put("C");

        size_t count = 0;
        foreach (ref name; list) {
            count++;
        }
        assert(count == 3);
    }

    @("TypeNameList copy creates independent copy")
    unittest {
        TypeNameList list1;
        list1.put("type1");

        auto list2 = list1;
        list2.put("type2");

        assert(list1.length == 1);
        assert(list2.length == 2);
    }

    @("TypeNameList respects maximum capacity")
    unittest {
        TypeNameList list;
        foreach (i; 0 .. 10) {
            list.put("type");
        }
        assert(list.length == 8);
    }
}
