/// HeapSerializerRegistry for @nogc HeapString serialization.
module fluentasserts.results.serializers.heap_registry;

import std.array;
import std.string;
import std.algorithm;
import std.traits;
import std.conv;
import std.datetime;
import std.functional;

import fluentasserts.core.memory.heapstring : HeapString, HeapStringList, toHeapString;
import fluentasserts.core.evaluation.constraints : isPrimitiveType;
import fluentasserts.core.toHeapString : StringResult, toHeapString;
import fluentasserts.results.serializers.helpers : replaceSpecialChars;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.lifecycle;
}

/// Registry for value serializers that returns HeapString.
/// Converts values to HeapString representations for assertion output in @nogc contexts.
/// Custom serializers can be registered for specific types.
class HeapSerializerRegistry {
  /// Global singleton instance.
  static HeapSerializerRegistry instance;

  private {
    HeapString delegate(void*)[string] serializers;
    HeapString delegate(const void*)[string] constSerializers;
    HeapString delegate(immutable void*)[string] immutableSerializers;
  }

  /// Registers a custom serializer delegate for an aggregate type.
  /// The serializer will be used when serializing values of that type.
  void register(T)(HeapString delegate(T) serializer) @trusted if(isAggregateType!T) {
    enum key = T.stringof;

    static if(is(Unqual!T == T)) {
      HeapString wrap(void* val) @trusted {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      serializers[key] = &wrap;
    } else static if(is(ConstOf!T == T)) {
      HeapString wrap(const void* val) @trusted {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      constSerializers[key] = &wrap;
    } else static if(is(ImmutableOf!T == T)) {
      HeapString wrap(immutable void* val) @trusted {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      immutableSerializers[key] = &wrap;
    }
  }

  /// Registers a custom serializer function for a type.
  /// Converts the function to a delegate and registers it.
  void register(T)(HeapString function(T) serializer) @trusted {
    auto serializerDelegate = serializer.toDelegate;
    this.register(serializerDelegate);
  }

  /// Serializes an array to a HeapString representation.
  /// Each element is serialized and joined with commas.
  HeapString serialize(T)(T[] value) @trusted if(!isSomeString!(T[])) {
    static if(is(Unqual!T == void)) {
      auto result = HeapString.create(2);
      result.put("[]");
      return result;
    } else {
      auto result = HeapString.create();
      result.put("[");
      bool first = true;
      foreach(elem; value) {
        if(!first) result.put(", ");
        first = false;
        auto serialized = serialize(elem);
        result.put(serialized[]);
      }
      result.put("]");
      return result;
    }
  }

  /// Serializes an associative array to a HeapString representation.
  /// Keys are sorted for consistent output.
  HeapString serialize(T: V[K], V, K)(T value) @trusted {
    auto result = HeapString.create();
    result.put("[");
    auto keys = value.byKey.array.sort;
    bool first = true;
    foreach(k; keys) {
      if(!first) result.put(", ");
      first = false;
      result.put(`"`);
      auto serializedKey = serialize(k);
      result.put(serializedKey[]);
      result.put(`":`);
      auto serializedValue = serialize(value[k]);
      result.put(serializedValue[]);
    }
    result.put("]");
    return result;
  }

  /// Serializes a HeapString (HeapData!char) to itself.
  /// This avoids calling .to!string which is not nothrow.
  HeapString serialize(T)(T value) @trusted nothrow @nogc if(is(T == HeapString)) {
    return value;
  }

  /// Serializes an aggregate type (class, struct, interface) to a HeapString.
  /// Uses a registered custom serializer if available.
  HeapString serialize(T)(T value) @trusted if(isAggregateType!T && !is(T == HeapString)) {
    auto key = T.stringof;
    auto tmp = &value;

    static if(is(Unqual!T == T)) {
      if(key in serializers) {
        return serializers[key](tmp);
      }
    }

    static if(is(ConstOf!T == T)) {
      if(key in constSerializers) {
        return constSerializers[key](tmp);
      }
    }

    static if(is(ImmutableOf!T == T)) {
      if(key in immutableSerializers) {
        return immutableSerializers[key](tmp);
      }
    }

    auto result = HeapString.create();

    static if(is(T == class)) {
      if(value is null) {
        result.put("null");
      } else {
        auto v = (cast() value);
        result.put(T.stringof);
        result.put("(");
        auto hashResult = toHeapString(v.toHash);
        if (hashResult.success) {
          result.put(hashResult.value[]);
        }
        result.put(")");
      }
    } else static if(is(Unqual!T == Duration)) {
      // Serialize as nanoseconds for parsing compatibility with toNumeric
      auto strResult = toHeapString(value.total!"nsecs");
      if (strResult.success) {
        result.put(strResult.value[]);
      }
    } else static if(is(Unqual!T == SysTime)) {
      auto str = value.toISOExtString;
      result.put(str);
    } else {
      auto str = value.to!string;
      result.put(str);
    }

    // Remove const() wrapper if present
    auto resultSlice = result[];
    if(resultSlice.length >= 6 && resultSlice[0..6] == "const(") {
      auto temp = HeapString.create();
      size_t pos = 6;
      while(pos < resultSlice.length && resultSlice[pos] != ')') {
        pos++;
      }
      temp.put(resultSlice[6..pos]);
      if(pos + 1 < resultSlice.length) {
        temp.put(resultSlice[pos + 1..$]);
      }
      return temp;
    }

    // Remove immutable() wrapper if present
    if(resultSlice.length >= 10 && resultSlice[0..10] == "immutable(") {
      auto temp = HeapString.create();
      size_t pos = 10;
      while(pos < resultSlice.length && resultSlice[pos] != ')') {
        pos++;
      }
      temp.put(resultSlice[10..pos]);
      if(pos + 1 < resultSlice.length) {
        temp.put(resultSlice[pos + 1..$]);
      }
      return temp;
    }

    return result;
  }

  /// Serializes a primitive type (string, char, number) to a HeapString.
  /// Strings are quoted with double quotes, chars with single quotes.
  /// Special characters are replaced with their visual representations.
  /// Note: Only string types are @nogc. Numeric types use .to!string which allocates.
  HeapString serialize(T)(T value) @trusted if(!is(T == enum) && isPrimitiveType!T) {
    static if(isSomeString!T) {
      static if (is(T == string) || is(T == const(char)[])) {
        return replaceSpecialChars(value);
      } else {
        // For wstring/dstring, convert to string first
        auto str = value.to!string;
        return replaceSpecialChars(str);
      }
    } else static if(isSomeChar!T) {
      char[1] buf = [cast(char) value];
      return replaceSpecialChars(buf[]);
    } else static if(__traits(isIntegral, T)) {
      // Use toHeapString for integral types (better for @nogc contexts)
      auto strResult = toHeapString(value);
      if (strResult.success) {
        return strResult.value;
      }
      // Fallback to empty string on failure
      return HeapString.create();
    } else {
      // For floating point, delegates, function pointers, etc., use .to!string
      // This ensures better precision for floats and compatibility with existing behavior
      auto result = HeapString.create();
      auto str = value.to!string;
      result.put(str);
      return result;
    }
  }

  /// Serializes an enum value to its underlying type representation.
  HeapString serialize(T)(T value) @trusted nothrow if(is(T == enum)) {
    static foreach(member; EnumMembers!T) {
      if(member == value) {
        return this.serialize(cast(OriginalType!T) member);
      }
    }

    auto result = HeapString.create();
    result.put("unknown enum value");
    return result;
  }

  /// Returns a human-readable representation of a value.
  /// Uses specialized formatting for SysTime and Duration.
  HeapString niceValue(T)(T value) @trusted {
    static if(is(Unqual!T == SysTime)) {
      auto result = HeapString.create();
      auto str = value.toISOExtString;
      result.put(str);
      return result;
    } else static if(is(Unqual!T == Duration)) {
      auto result = HeapString.create();
      auto str = value.to!string;
      result.put(str);
      return result;
    } else {
      return serialize(value);
    }
  }
}

// Unit tests
@("serializes a char")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  char ch = 'a';
  const char cch = 'a';
  immutable char ich = 'a';

  HeapSerializerRegistry.instance.serialize(ch).should.equal("a");
  HeapSerializerRegistry.instance.serialize(cch).should.equal("a");
  HeapSerializerRegistry.instance.serialize(ich).should.equal("a");
}

@("serializes a SysTime")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  SysTime val = SysTime.fromISOExtString("2010-07-04T07:06:12");
  const SysTime cval = SysTime.fromISOExtString("2010-07-04T07:06:12");
  immutable SysTime ival = SysTime.fromISOExtString("2010-07-04T07:06:12");

  HeapSerializerRegistry.instance.serialize(val).should.equal("2010-07-04T07:06:12");
  HeapSerializerRegistry.instance.serialize(cval).should.equal("2010-07-04T07:06:12");
  HeapSerializerRegistry.instance.serialize(ival).should.equal("2010-07-04T07:06:12");
}

@("serializes a string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string str = "aaa";
  const string cstr = "aaa";
  immutable string istr = "aaa";

  HeapSerializerRegistry.instance.serialize(str).should.equal(`aaa`);
  HeapSerializerRegistry.instance.serialize(cstr).should.equal(`aaa`);
  HeapSerializerRegistry.instance.serialize(istr).should.equal(`aaa`);
}

@("serializes an int")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int value = 23;
  const int cvalue = 23;
  immutable int ivalue = 23;

  HeapSerializerRegistry.instance.serialize(value).should.equal(`23`);
  HeapSerializerRegistry.instance.serialize(cvalue).should.equal(`23`);
  HeapSerializerRegistry.instance.serialize(ivalue).should.equal(`23`);
}

@("serializes an int list")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[] value = [2,3];
  const int[] cvalue = [2,3];
  immutable int[] ivalue = [2,3];

  HeapSerializerRegistry.instance.serialize(value).should.equal(`[2, 3]`);
  HeapSerializerRegistry.instance.serialize(cvalue).should.equal(`[2, 3]`);
  HeapSerializerRegistry.instance.serialize(ivalue).should.equal(`[2, 3]`);
}

@("serializes a void list")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  void[] value = [];
  const void[] cvalue = [];
  immutable void[] ivalue = [];

  HeapSerializerRegistry.instance.serialize(value).should.equal(`[]`);
  HeapSerializerRegistry.instance.serialize(cvalue).should.equal(`[]`);
  HeapSerializerRegistry.instance.serialize(ivalue).should.equal(`[]`);
}

@("serializes a nested int list")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[][] value = [[0,1],[2,3]];
  const int[][] cvalue = [[0,1],[2,3]];
  immutable int[][] ivalue = [[0,1],[2,3]];

  HeapSerializerRegistry.instance.serialize(value).should.equal(`[[0, 1], [2, 3]]`);
  HeapSerializerRegistry.instance.serialize(cvalue).should.equal(`[[0, 1], [2, 3]]`);
  HeapSerializerRegistry.instance.serialize(ivalue).should.equal(`[[0, 1], [2, 3]]`);
}

@("serializes an assoc array")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[string] value = ["a": 2,"b": 3, "c": 4];
  const int[string] cvalue = ["a": 2,"b": 3, "c": 4];
  immutable int[string] ivalue = ["a": 2,"b": 3, "c": 4];

  HeapSerializerRegistry.instance.serialize(value).should.equal(`["a":2, "b":3, "c":4]`);
  HeapSerializerRegistry.instance.serialize(cvalue).should.equal(`["a":2, "b":3, "c":4]`);
  HeapSerializerRegistry.instance.serialize(ivalue).should.equal(`["a":2, "b":3, "c":4]`);
}

@("serializes a string enum")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  enum TestType : string {
    a = "a",
    b = "b"
  }
  TestType value = TestType.a;
  const TestType cvalue = TestType.a;
  immutable TestType ivalue = TestType.a;

  HeapSerializerRegistry.instance.serialize(value).should.equal(`a`);
  HeapSerializerRegistry.instance.serialize(cvalue).should.equal(`a`);
  HeapSerializerRegistry.instance.serialize(ivalue).should.equal(`a`);
}

version(unittest) { struct TestStruct { int a; string b; }; }
@("serializes a struct")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  TestStruct value = TestStruct(1, "2");
  const TestStruct cvalue = TestStruct(1, "2");
  immutable TestStruct ivalue = TestStruct(1, "2");

  HeapSerializerRegistry.instance.serialize(value).should.equal(`TestStruct(1, "2")`);
  HeapSerializerRegistry.instance.serialize(cvalue).should.equal(`TestStruct(1, "2")`);
  HeapSerializerRegistry.instance.serialize(ivalue).should.equal(`TestStruct(1, "2")`);
}
