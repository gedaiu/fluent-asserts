/// A simple hash map using HeapString for keys and values.
/// Designed for @nogc @safe nothrow operation using linear probing.
module fluentasserts.core.memory.heapmap;

import core.stdc.stdlib : malloc, free;

import fluentasserts.core.memory.heapstring : HeapString, HeapData;

/// A simple hash map using HeapString for keys and values.
/// Designed for @nogc @safe nothrow operation using linear probing.
struct HeapMap {
  private enum size_t INITIAL_CAPACITY = 16;
  private enum size_t DELETED_HASH = size_t.max;

  private struct Entry {
    HeapString key;
    HeapString value;
    size_t hash;
    bool occupied;
  }

  private {
    Entry[] _entries = null;
    size_t _count = 0;
    size_t _capacity = 0;
  }

  /// Creates a new HeapMap with the given initial capacity.
  static HeapMap create(size_t initialCapacity = INITIAL_CAPACITY) @trusted nothrow {
    HeapMap map;
    map._capacity = initialCapacity;
    map._count = 0;
    map._entries = (cast(Entry*) malloc(Entry.sizeof * initialCapacity))[0 .. initialCapacity];

    if (map._entries.ptr !is null) {
      foreach (ref entry; map._entries) {
        entry = Entry.init;
      }
    }

    return map;
  }

  /// Postblit - creates a deep copy when struct is copied.
  this(this) @trusted nothrow @nogc {
    if (_entries.ptr is null || _capacity == 0) {
      return;
    }

    // Save old entries reference
    auto oldEntries = _entries;
    auto oldCapacity = _capacity;

    // Allocate new entries
    _entries = (cast(Entry*) malloc(Entry.sizeof * oldCapacity))[0 .. oldCapacity];

    if (_entries.ptr !is null) {
      foreach (i; 0 .. oldCapacity) {
        if (oldEntries[i].occupied) {
          _entries[i].key = HeapString.create(oldEntries[i].key.length);
          _entries[i].key.put(oldEntries[i].key[]);
          _entries[i].value = HeapString.create(oldEntries[i].value.length);
          _entries[i].value.put(oldEntries[i].value[]);
          _entries[i].hash = oldEntries[i].hash;
          _entries[i].occupied = true;
        } else {
          _entries[i] = Entry.init;
        }
      }
    }
  }

  /// Destructor - frees all entries.
  ~this() @trusted nothrow @nogc {
    if (_capacity > 0 && _entries.ptr !is null) {
      foreach (ref entry; _entries) {
        if (entry.occupied) {
          destroy(entry.key);
          destroy(entry.value);
        }
      }
      free(_entries.ptr);
    }
  }

  /// Assignment operator.
  void opAssign(ref HeapMap rhs) @trusted nothrow @nogc {
    if (&this is &rhs) {
      return;
    }
    assignFrom(rhs._entries, rhs._count, rhs._capacity);
  }

  /// Assignment operator (const overload).
  void opAssign(ref const HeapMap rhs) @trusted nothrow @nogc {
    assignFrom(rhs._entries, rhs._count, rhs._capacity);
  }

  /// Assignment operator (rvalue overload).
  void opAssign(HeapMap rhs) @trusted nothrow @nogc {
    assignFrom(rhs._entries, rhs._count, rhs._capacity);
  }

  /// Internal assignment helper.
  private void assignFrom(const(Entry)[] rhsEntries, size_t rhsCount, size_t rhsCapacity) @trusted nothrow @nogc {
    // Destroy old data
    if (_capacity > 0 && _entries.ptr !is null) {
      foreach (ref entry; _entries) {
        if (entry.occupied) {
          destroy(entry.key);
          destroy(entry.value);
        }
      }
      free(_entries.ptr);
    }

    // Copy from rhs
    if (rhsEntries.ptr is null || rhsCapacity == 0) {
      _entries = null;
      _count = 0;
      _capacity = 0;
      return;
    }

    _capacity = rhsCapacity;
    _count = rhsCount;
    _entries = (cast(Entry*) malloc(Entry.sizeof * _capacity))[0 .. _capacity];

    if (_entries.ptr !is null) {
      foreach (i; 0 .. _capacity) {
        if (rhsEntries[i].occupied) {
          _entries[i].key = HeapString.create(rhsEntries[i].key.length);
          _entries[i].key.put(rhsEntries[i].key[]);
          _entries[i].value = HeapString.create(rhsEntries[i].value.length);
          _entries[i].value.put(rhsEntries[i].value[]);
          _entries[i].hash = rhsEntries[i].hash;
          _entries[i].occupied = true;
        } else {
          _entries[i] = Entry.init;
        }
      }
    }
  }

  /// Simple hash function for strings.
  private static size_t hashOf(const(char)[] key) @nogc nothrow pure {
    size_t hash = 5381;
    foreach (c; key) {
      hash = ((hash << 5) + hash) + c;
    }
    return hash == 0 ? 1 : (hash == DELETED_HASH ? hash - 1 : hash);
  }

  /// Finds the index for a key, or the first empty slot if not found.
  private size_t findIndex(const(char)[] key, size_t hash) @nogc nothrow const {
    if (_capacity == 0) {
      return size_t.max;
    }

    size_t index = hash % _capacity;
    size_t firstDeleted = size_t.max;

    for (size_t i = 0; i < _capacity; i++) {
      size_t probeIndex = (index + i) % _capacity;

      if (!_entries[probeIndex].occupied) {
        if (_entries[probeIndex].hash == DELETED_HASH) {
          if (firstDeleted == size_t.max) {
            firstDeleted = probeIndex;
          }
          continue;
        }
        return firstDeleted != size_t.max ? firstDeleted : probeIndex;
      }

      if (_entries[probeIndex].hash == hash && _entries[probeIndex].key[] == key) {
        return probeIndex;
      }
    }

    return firstDeleted != size_t.max ? firstDeleted : size_t.max;
  }

  /// Grows the map when load factor exceeds threshold.
  private void grow() @trusted nothrow {
    size_t newCapacity = _capacity == 0 ? INITIAL_CAPACITY : _capacity * 2;
    auto newEntries = (cast(Entry*) malloc(Entry.sizeof * newCapacity))[0 .. newCapacity];

    if (newEntries.ptr is null) {
      return;
    }

    foreach (ref entry; newEntries) {
      entry = Entry.init;
    }

    // Rehash all entries
    if (_entries.ptr !is null) {
      foreach (ref oldEntry; _entries) {
        if (oldEntry.occupied) {
          size_t newIndex = oldEntry.hash % newCapacity;

          for (size_t i = 0; i < newCapacity; i++) {
            size_t probeIndex = (newIndex + i) % newCapacity;
            if (!newEntries[probeIndex].occupied) {
              newEntries[probeIndex] = oldEntry;
              break;
            }
          }
        }
      }
      free(_entries.ptr);
    }

    _entries = newEntries;
    _capacity = newCapacity;
  }

  /// Sets a value for the given key.
  void opIndexAssign(const(char)[] value, const(char)[] key) @trusted nothrow {
    if (_capacity == 0 || (_count + 1) * 2 > _capacity) {
      grow();
    }

    size_t hash = hashOf(key);
    size_t index = findIndex(key, hash);

    if (index == size_t.max) {
      grow();
      index = findIndex(key, hash);
      if (index == size_t.max) {
        return;
      }
    }

    if (_entries[index].occupied && _entries[index].hash == hash && _entries[index].key[] == key) {
      // Update existing entry
      _entries[index].value.clear();
      _entries[index].value.put(value);
    } else {
      // New entry
      _entries[index].key = HeapString.create(key.length);
      _entries[index].key.put(key);
      _entries[index].value = HeapString.create(value.length);
      _entries[index].value.put(value);
      _entries[index].hash = hash;
      _entries[index].occupied = true;
      _count++;
    }
  }

  /// Gets the value for a key, returns empty string if not found.
  const(char)[] opIndex(const(char)[] key) @nogc nothrow const {
    if (_capacity == 0) {
      return null;
    }

    size_t hash = hashOf(key);
    size_t index = hash % _capacity;

    for (size_t i = 0; i < _capacity; i++) {
      size_t probeIndex = (index + i) % _capacity;

      if (!_entries[probeIndex].occupied) {
        if (_entries[probeIndex].hash == DELETED_HASH) {
          continue;
        }
        return null;
      }

      if (_entries[probeIndex].hash == hash && _entries[probeIndex].key[] == key) {
        return _entries[probeIndex].value[];
      }
    }

    return null;
  }

  /// Checks if a key exists in the map.
  bool opBinaryRight(string op : "in")(const(char)[] key) @nogc nothrow const {
    if (_capacity == 0) {
      return false;
    }

    size_t hash = hashOf(key);
    size_t index = hash % _capacity;

    for (size_t i = 0; i < _capacity; i++) {
      size_t probeIndex = (index + i) % _capacity;

      if (!_entries[probeIndex].occupied) {
        if (_entries[probeIndex].hash == DELETED_HASH) {
          continue;
        }
        return false;
      }

      if (_entries[probeIndex].hash == hash && _entries[probeIndex].key[] == key) {
        return true;
      }
    }

    return false;
  }

  /// Removes a key from the map.
  bool remove(const(char)[] key) @trusted nothrow @nogc {
    if (_capacity == 0) {
      return false;
    }

    size_t hash = hashOf(key);
    size_t index = hash % _capacity;

    for (size_t i = 0; i < _capacity; i++) {
      size_t probeIndex = (index + i) % _capacity;

      if (!_entries[probeIndex].occupied) {
        if (_entries[probeIndex].hash == DELETED_HASH) {
          continue;
        }
        return false;
      }

      if (_entries[probeIndex].hash == hash && _entries[probeIndex].key[] == key) {
        destroy(_entries[probeIndex].key);
        destroy(_entries[probeIndex].value);
        _entries[probeIndex].occupied = false;
        _entries[probeIndex].hash = DELETED_HASH;
        _count--;
        return true;
      }
    }

    return false;
  }

  /// Returns the number of entries.
  size_t length() @nogc nothrow const {
    return _count;
  }

  /// Returns true if the map is empty.
  bool empty() @nogc nothrow const {
    return _count == 0;
  }

  /// Range for iterating over key-value pairs.
  auto byKeyValue() @nogc nothrow const {
    return KeyValueRange(&this);
  }

  private struct KeyValueRange {
    private const(HeapMap)* map;
    private size_t index;

    this(const(HeapMap)* m) @nogc nothrow {
      map = m;
      index = 0;
      advance();
    }

    private void advance() @nogc nothrow {
      if (map is null || map._entries.ptr is null) {
        index = size_t.max;
        return;
      }

      while (index < map._capacity && !map._entries[index].occupied) {
        index++;
      }
    }

    bool empty() @nogc nothrow const {
      return map is null || map._entries.ptr is null || index >= map._capacity;
    }

    auto front() @nogc nothrow const {
      struct KV {
        const(char)[] key;
        const(char)[] value;
      }
      return KV(map._entries[index].key[], map._entries[index].value[]);
    }

    void popFront() @nogc nothrow {
      index++;
      advance();
    }
  }
}

version (unittest) {
  @("HeapMap set and get")
  unittest {
    auto map = HeapMap.create();
    map["foo"] = "bar";
    assert(map["foo"] == "bar");
  }

  @("HeapMap in operator")
  unittest {
    auto map = HeapMap.create();
    map["foo"] = "bar";
    assert("foo" in map);
    assert(!("baz" in map));
  }

  @("HeapMap update existing key")
  unittest {
    auto map = HeapMap.create();
    map["foo"] = "bar";
    map["foo"] = "baz";
    assert(map["foo"] == "baz");
    assert(map.length == 1);
  }

  @("HeapMap multiple entries")
  unittest {
    auto map = HeapMap.create();
    map["a"] = "1";
    map["b"] = "2";
    map["c"] = "3";
    assert(map.length == 3);
    assert(map["a"] == "1");
    assert(map["b"] == "2");
    assert(map["c"] == "3");
  }

  @("HeapMap remove")
  unittest {
    auto map = HeapMap.create();
    map["foo"] = "bar";
    assert(map.remove("foo"));
    assert(!("foo" in map));
    assert(map.length == 0);
  }

  @("HeapMap copy via postblit")
  unittest {
    auto map1 = HeapMap.create();
    map1["foo"] = "bar";
    auto map2 = map1;
    map2["foo"] = "baz";
    assert(map1["foo"] == "bar");
    assert(map2["foo"] == "baz");
  }

  @("HeapMap grow")
  unittest {
    auto map = HeapMap.create(4);
    foreach (i; 0 .. 20) {
      import std.conv : to;
      map[i.to!string] = (i * 2).to!string;
    }
    assert(map.length == 20);
    foreach (i; 0 .. 20) {
      import std.conv : to;
      assert(map[i.to!string] == (i * 2).to!string);
    }
  }

  @("HeapMap iteration")
  unittest {
    auto map = HeapMap.create();
    map["a"] = "1";
    map["b"] = "2";

    size_t count = 0;
    foreach (kv; map.byKeyValue) {
      count++;
      if (kv.key == "a") {
        assert(kv.value == "1");
      } else if (kv.key == "b") {
        assert(kv.value == "2");
      }
    }
    assert(count == 2);
  }

  @("HeapMap opAssign from const")
  unittest {
    auto map1 = HeapMap.create();
    map1["foo"] = "bar";
    map1["baz"] = "qux";

    const HeapMap constMap = map1;

    HeapMap map2;
    map2 = constMap;

    assert(map2["foo"] == "bar");
    assert(map2["baz"] == "qux");
    assert(map2.length == 2);
  }
}
