/// Fixed-size metadata storage for fluent-asserts.
/// Optimized for storing 2-5 key-value pairs with O(n) linear search.
/// Much simpler and faster than a hash table for small collections.
module fluentasserts.core.memory.fixedmeta;

import fluentasserts.core.memory.heapstring;

@safe:

/// Fixed-size metadata storage using linear search.
/// Optimized for 2-5 entries - faster than hash table overhead.
struct FixedMeta {
  private enum MAX_ENTRIES = 8;

  private struct Entry {
    HeapString key;
    HeapString value;
    bool occupied;
  }

  private {
    Entry[MAX_ENTRIES] _entries;
    size_t _count = 0;
  }

  /// Disable postblit - use copy constructor instead
  @disable this(this);

  /// Copy constructor - creates a deep copy from the source.
  this(ref return scope const FixedMeta rhs) @trusted nothrow {
    _count = rhs._count;
    foreach (i; 0 .. _count) {
      _entries[i].key = rhs._entries[i].key;
      _entries[i].value = rhs._entries[i].value;
      _entries[i].occupied = rhs._entries[i].occupied;
    }
  }

  /// Assignment operator - creates a deep copy from the source.
  void opAssign(ref const FixedMeta rhs) @trusted nothrow {
    _count = rhs._count;
    foreach (i; 0 .. _count) {
      _entries[i].key = rhs._entries[i].key;
      _entries[i].value = rhs._entries[i].value;
      _entries[i].occupied = rhs._entries[i].occupied;
    }
    // Clear remaining entries
    foreach (i; _count .. MAX_ENTRIES) {
      _entries[i] = Entry.init;
    }
  }

  /// Lookup value by key (O(n) where n ≤ 8).
  /// Returns slice of value if found, empty slice otherwise.
  const(char)[] opIndex(const(char)[] key) const @nogc nothrow {
    foreach (ref entry; _entries[0 .. _count]) {
      if (entry.occupied && entry.key[] == key) {
        return entry.value[];
      }
    }
    return "";
  }

  /// Check if key exists.
  bool has(const(char)[] key) const @nogc nothrow {
    foreach (ref entry; _entries[0 .. _count]) {
      if (entry.occupied && entry.key[] == key) {
        return true;
      }
    }
    return false;
  }

  /// Support "key" in meta syntax for key existence checking.
  bool opBinaryRight(string op : "in")(const(char)[] key) const @nogc nothrow {
    return has(key);
  }

  /// Set or update a key-value pair (HeapString key and value).
  void opIndexAssign(HeapString value, HeapString key) @nogc nothrow {
    // Try to find existing key
    foreach (ref entry; _entries[0 .. _count]) {
      if (entry.occupied && entry.key[] == key[]) {
        entry.value = value;
        return;
      }
    }

    // Add new entry if space available
    if (_count < MAX_ENTRIES) {
      _entries[_count].key = key;
      _entries[_count].value = value;
      _entries[_count].occupied = true;
      _count++;
    }
  }

  /// Set or update a key-value pair (const(char)[] key, HeapString value).
  void opIndexAssign(HeapString value, const(char)[] key) @nogc nothrow {
    // Try to find existing key
    foreach (ref entry; _entries[0 .. _count]) {
      if (entry.occupied && entry.key[] == key) {
        entry.value = value;
        return;
      }
    }

    // Add new entry if space available
    if (_count < MAX_ENTRIES) {
      auto heapKey = HeapString.create(key.length);
      heapKey.put(key);
      _entries[_count].key = heapKey;
      _entries[_count].value = value;
      _entries[_count].occupied = true;
      _count++;
    }
  }

  /// Set or update a key-value pair (string key and value convenience).
  void opIndexAssign(const(char)[] value, const(char)[] key) @nogc nothrow {
    auto heapValue = HeapString.create(value.length);
    heapValue.put(value);
    opIndexAssign(heapValue, key);
  }

  /// Iterate over key-value pairs.
  int opApply(scope int delegate(HeapString key, HeapString value) @safe nothrow dg) @safe nothrow {
    foreach (ref entry; _entries[0 .. _count]) {
      if (entry.occupied) {
        auto result = dg(entry.key, entry.value);
        if (result) {
          return result;
        }
      }
    }
    return 0;
  }

  /// Iterate over key-value pairs (for byKeyValue compatibility).
  auto byKeyValue() @safe nothrow {
    static struct KeyValueRange {
      const(Entry)[] entries;
      size_t index;

      bool empty() const @nogc nothrow {
        return index >= entries.length;
      }

      auto front() const @nogc nothrow {
        static struct KeyValue {
          HeapString key;
          HeapString value;
        }
        return KeyValue(entries[index].key, entries[index].value);
      }

      void popFront() @nogc nothrow {
        index++;
      }
    }

    return KeyValueRange(_entries[0 .. _count], 0);
  }

  /// Number of entries.
  size_t length() const @nogc nothrow {
    return _count;
  }

  /// Clear all entries.
  void clear() @nogc nothrow {
    foreach (i; 0 .. _count) {
      _entries[i] = Entry.init;
    }
    _count = 0;
  }
}

version(unittest) {
  @("FixedMeta stores and retrieves values")
  nothrow unittest {
    FixedMeta meta;
    meta["key1"] = "value1";
    meta["key2"] = "value2";

    assert(meta["key1"] == "value1");
    assert(meta["key2"] == "value2");
    assert(meta.length == 2);
  }

  @("FixedMeta updates existing keys")
  nothrow unittest {
    FixedMeta meta;
    meta["key1"] = "value1";
    meta["key1"] = "value2";

    assert(meta["key1"] == "value2");
    assert(meta.length == 1);
  }

  @("FixedMeta returns empty for missing keys")
  nothrow unittest {
    FixedMeta meta;
    auto result = meta["missing"];
    assert(result == "");
  }

  @("FixedMeta has() checks for key existence")
  nothrow unittest {
    FixedMeta meta;
    meta["exists"] = "yes";

    assert(meta.has("exists"));
    assert(!meta.has("missing"));
  }

  @("FixedMeta iterates over entries")
  nothrow unittest {
    FixedMeta meta;
    meta["a"] = "1";
    meta["b"] = "2";
    meta["c"] = "3";

    size_t count = 0;
    foreach (key, value; meta) {
      count++;
    }
    assert(count == 3);
  }

  @("FixedMeta byKeyValue iteration")
  nothrow unittest {
    FixedMeta meta;
    meta["x"] = "10";
    meta["y"] = "20";

    size_t count = 0;
    foreach (kv; meta.byKeyValue) {
      count++;
      assert(kv.key[] == "x" || kv.key[] == "y");
      assert(kv.value[] == "10" || kv.value[] == "20");
    }
    assert(count == 2);
  }

  @("FixedMeta copy creates independent copy")
  nothrow unittest {
    FixedMeta meta1;
    meta1["a"] = "1";

    auto meta2 = meta1;
    meta2["b"] = "2";

    assert(meta1.length == 1);
    assert(meta2.length == 2);
    assert(meta1["a"] == "1");
    assert(!meta1.has("b"));
  }

  @("FixedMeta clear removes all entries")
  nothrow unittest {
    FixedMeta meta;
    meta["a"] = "1";
    meta["b"] = "2";

    meta.clear();
    assert(meta.length == 0);
    assert(!meta.has("a"));
    assert(!meta.has("b"));
  }
}
