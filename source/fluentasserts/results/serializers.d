/// Serialization utilities for fluent-asserts.
/// Provides type-aware serialization of values for assertion output.
module fluentasserts.results.serializers;

import std.array;
import std.string;
import std.algorithm;
import std.traits;
import std.conv;
import std.datetime;
import std.functional;

import fluentasserts.core.memory;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.lifecycle;
}

/// Registry for value serializers.
/// Converts values to string representations for assertion output.
/// Custom serializers can be registered for specific types.
class SerializerRegistry {
  /// Global singleton instance.
  static SerializerRegistry instance;

  private {
    string delegate(void*)[string] serializers;
    string delegate(const void*)[string] constSerializers;
    string delegate(immutable void*)[string] immutableSerializers;
  }

  /// Registers a custom serializer delegate for an aggregate type.
  /// The serializer will be used when serializing values of that type.
  void register(T)(string delegate(T) serializer) @trusted if(isAggregateType!T) {
    enum key = T.stringof;

    static if(is(Unqual!T == T)) {
      string wrap(void* val) @trusted {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      serializers[key] = &wrap;
    } else static if(is(ConstOf!T == T)) {
      string wrap(const void* val) @trusted {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      constSerializers[key] = &wrap;
    } else static if(is(ImmutableOf!T == T)) {
      string wrap(immutable void* val) @trusted {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      immutableSerializers[key] = &wrap;
    }
  }

  /// Registers a custom serializer function for a type.
  /// Converts the function to a delegate and registers it.
  void register(T)(string function(T) serializer) @trusted {
    auto serializerDelegate = serializer.toDelegate;
    this.register(serializerDelegate);
  }

  /// Serializes an array to a string representation.
  /// Each element is serialized and joined with commas.
  string serialize(T)(T[] value) @safe if(!isSomeString!(T[])) {
    import std.array : Appender;

    static if(is(Unqual!T == void)) {
      return "[]";
    } else {
      Appender!string result;
      result.put("[");
      bool first = true;
      foreach(elem; value) {
        if(!first) result.put(", ");
        first = false;
        result.put(serialize(elem));
      }
      result.put("]");
      return result[];
    }
  }

  /// Serializes an associative array to a string representation.
  /// Keys are sorted for consistent output.
  string serialize(T: V[K], V, K)(T value) @safe {
    import std.array : Appender;

    Appender!string result;
    result.put("[");
    auto keys = value.byKey.array.sort;
    bool first = true;
    foreach(k; keys) {
      if(!first) result.put(", ");
      first = false;
      result.put(`"`);
      result.put(serialize(k));
      result.put(`":`);
      result.put(serialize(value[k]));
    }
    result.put("]");
    return result[];
  }

  /// Serializes an aggregate type (class, struct, interface) to a string.
  /// Uses a registered custom serializer if available.
  string serialize(T)(T value) @trusted if(isAggregateType!T) {
    import std.array : Appender;

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

    string result;

    static if(is(T == class)) {
      if(value is null) {
        result = "null";
      } else {
        auto v = (cast() value);
        Appender!string buf;
        buf.put(T.stringof);
        buf.put("(");
        buf.put(v.toHash.to!string);
        buf.put(")");
        result = buf[];
      }
    } else static if(is(Unqual!T == Duration)) {
      result = value.total!"nsecs".to!string;
    } else static if(is(Unqual!T == SysTime)) {
      result = value.toISOExtString;
    } else {
      result = value.to!string;
    }

    if(result.indexOf("const(") == 0) {
      result = result[6..$];

      auto pos = result.indexOf(")");
      Appender!string buf;
      buf.put(result[0..pos]);
      buf.put(result[pos + 1..$]);
      result = buf[];
    }

    if(result.indexOf("immutable(") == 0) {
      result = result[10..$];
      auto pos = result.indexOf(")");
      Appender!string buf;
      buf.put(result[0..pos]);
      buf.put(result[pos + 1..$]);
      result = buf[];
    }

    return result;
  }

  /// Serializes a primitive type (string, char, number) to a string.
  /// Strings are quoted with double quotes, chars with single quotes.
  /// Special characters are replaced with their visual representations.
  string serialize(T)(T value) @trusted if(!is(T == enum) && (isSomeString!T || (!isArray!T && !isAssociativeArray!T && !isAggregateType!T))) {
    static if(isSomeString!T) {
      static if (is(T == string) || is(T == const(char)[])) {
        auto result = replaceSpecialChars(value);
        return result[].idup;
      } else {
        // For wstring/dstring, convert to string first
        auto result = replaceSpecialChars(value.to!string);
        return result[].idup;
      }
    } else static if(isSomeChar!T) {
      char[1] buf = [cast(char) value];
      auto result = replaceSpecialChars(buf[]);
      return result[].idup;
    } else {
      return value.to!string;
    }
  }

  /// Serializes an enum value to its underlying type representation.
  string serialize(T)(T value) @safe if(is(T == enum)) {
    static foreach(member; EnumMembers!T) {
      if(member == value) {
        return this.serialize(cast(OriginalType!T) member);
      }
    }

    throw new Exception("The value can not be serialized.");
  }

  /// Returns a human-readable representation of a value.
  /// Uses specialized formatting for SysTime and Duration.
  string niceValue(T)(T value) @safe {
    static if(is(Unqual!T == SysTime)) {
      return value.toISOExtString;
    } else static if(is(Unqual!T == Duration)) {
      return value.to!string;
    } else {
      return serialize(value);
    }
  }
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
  HeapString serialize(T)(T[] value) @trusted nothrow @nogc if(!isSomeString!(T[])) {
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
  HeapString serialize(T: V[K], V, K)(T value) @trusted nothrow {
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

  /// Serializes an aggregate type (class, struct, interface) to a HeapString.
  /// Uses a registered custom serializer if available.
  HeapString serialize(T)(T value) @trusted nothrow if(isAggregateType!T) {
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
        auto hashStr = v.toHash.to!string;
        result.put(hashStr);
        result.put(")");
      }
    } else static if(is(Unqual!T == Duration)) {
      auto str = value.total!"nsecs".to!string;
      result.put(str);
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
  HeapString serialize(T)(T value) @trusted nothrow @nogc if(!is(T == enum) && (isSomeString!T || (!isArray!T && !isAssociativeArray!T && !isAggregateType!T))) {
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
    } else {
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
  HeapString niceValue(T)(T value) @trusted nothrow {
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

/// Replaces ASCII control characters and trailing spaces with visual representations from ResultGlyphs.
/// Params:
///   value = The string to process
/// Returns: A HeapString with control characters and trailing spaces replaced by glyphs.
HeapString replaceSpecialChars(const(char)[] value) @trusted nothrow @nogc {
  import fluentasserts.results.message : ResultGlyphs;

  size_t trailingSpaceStart = value.length;
  foreach_reverse (i, c; value) {
    if (c != ' ') {
      trailingSpaceStart = i + 1;
      break;
    }
  }
  if (value.length > 0 && value[0] == ' ' && trailingSpaceStart == value.length) {
    trailingSpaceStart = 0;
  }

  auto result = HeapString.create(value.length);

  foreach (i, c; value) {
    if (c < 32 || c == 127) {
      switch (c) {
        case '\0': result.put(ResultGlyphs.nullChar); break;
        case '\a': result.put(ResultGlyphs.bell); break;
        case '\b': result.put(ResultGlyphs.backspace); break;
        case '\t': result.put(ResultGlyphs.tab); break;
        case '\n': result.put(ResultGlyphs.newline); break;
        case '\v': result.put(ResultGlyphs.verticalTab); break;
        case '\f': result.put(ResultGlyphs.formFeed); break;
        case '\r': result.put(ResultGlyphs.carriageReturn); break;
        case 27:   result.put(ResultGlyphs.escape); break;
        default:   putHex(result, cast(ubyte) c); break;
      }
    } else if (c == ' ' && i >= trailingSpaceStart) {
      result.put(ResultGlyphs.space);
    } else {
      result.put(c);
    }
  }

  return result;
}

/// Appends a hex escape sequence like `\x1F` to the buffer.
private void putHex(ref HeapString buf, ubyte b) @safe nothrow @nogc {
  static immutable hexDigits = "0123456789ABCDEF";
  buf.put('\\');
  buf.put('x');
  buf.put(hexDigits[b >> 4]);
  buf.put(hexDigits[b & 0xF]);
}

@("replaceSpecialChars replaces null character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\0world");
  result[].should.equal("hello\\0world");
}

@("replaceSpecialChars replaces tab character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\tworld");
  result[].should.equal("hello\\tworld");
}

@("replaceSpecialChars replaces newline character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\nworld");
  result[].should.equal("hello\\nworld");
}

@("replaceSpecialChars replaces carriage return character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\rworld");
  result[].should.equal("hello\\rworld");
}

@("replaceSpecialChars replaces trailing spaces")
unittest {
  import fluentasserts.results.message : ResultGlyphs;

  Lifecycle.instance.disableFailureHandling = false;
  auto savedSpace = ResultGlyphs.space;
  scope(exit) ResultGlyphs.space = savedSpace;
  ResultGlyphs.space = "\u00B7";

  auto result = replaceSpecialChars("hello   ");
  result[].should.equal("hello\u00B7\u00B7\u00B7");
}

@("replaceSpecialChars preserves internal spaces")
unittest {
  import fluentasserts.results.message : ResultGlyphs;

  Lifecycle.instance.disableFailureHandling = false;
  auto savedSpace = ResultGlyphs.space;
  scope(exit) ResultGlyphs.space = savedSpace;
  ResultGlyphs.space = "\u00B7";

  auto result = replaceSpecialChars("hello world");
  result[].should.equal("hello world");
}

@("replaceSpecialChars replaces all spaces when string is only spaces")
unittest {
  import fluentasserts.results.message : ResultGlyphs;

  Lifecycle.instance.disableFailureHandling = false;
  auto savedSpace = ResultGlyphs.space;
  scope(exit) ResultGlyphs.space = savedSpace;
  ResultGlyphs.space = "\u00B7";

  auto result = replaceSpecialChars("   ");
  result[].should.equal("\u00B7\u00B7\u00B7");
}

@("replaceSpecialChars handles empty string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("");
  result[].should.equal("");
}

@("replaceSpecialChars replaces unknown control character with hex")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\x01world");
  result[].should.equal("hello\\x01world");
}

@("replaceSpecialChars replaces DEL character with hex")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\x7Fworld");
  result[].should.equal("hello\\x7Fworld");
}

@("overrides the default struct serializer")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  struct A {}

  string serializer(A) {
    return "custom value";
  }
  auto registry = new SerializerRegistry();
  registry.register(&serializer);

  registry.serialize(A()).should.equal("custom value");
  registry.serialize([A()]).should.equal("[custom value]");
  registry.serialize(["key": A()]).should.equal(`["key":custom value]`);
}

@("overrides the default const struct serializer")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  struct A {}

  string serializer(const A) {
    return "custom value";
  }
  auto registry = new SerializerRegistry();
  registry.register(&serializer);

  const A value;

  registry.serialize(value).should.equal("custom value");
  registry.serialize([value]).should.equal("[custom value]");
  registry.serialize(["key": value]).should.equal(`["key":custom value]`);
}

@("overrides the default immutable struct serializer")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  struct A {}

  string serializer(immutable A) {
    return "value";
  }
  auto registry = new SerializerRegistry();
  registry.register(&serializer);

  immutable A ivalue;
  const A cvalue;
  A value;

  registry.serialize(value).should.equal("A()");
  registry.serialize(cvalue).should.equal("A()");
  registry.serialize(ivalue).should.equal("value");
  registry.serialize(ivalue).should.equal("value");
  registry.serialize([ivalue]).should.equal("[value]");
  registry.serialize(["key": ivalue]).should.equal(`["key":value]`);
}


@("overrides the default class serializer")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  class A {}

  string serializer(A) {
    return "custom value";
  }
  auto registry = new SerializerRegistry();
  registry.register(&serializer);

  registry.serialize(new A()).should.equal("custom value");
  registry.serialize([new A()]).should.equal("[custom value]");
  registry.serialize(["key": new A()]).should.equal(`["key":custom value]`);
}

@("overrides the default const class serializer")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  class A {}

  string serializer(const A) {
    return "custom value";
  }
  auto registry = new SerializerRegistry();
  registry.register(&serializer);

  const A value = new A;

  registry.serialize(value).should.equal("custom value");
  registry.serialize([value]).should.equal("[custom value]");
  registry.serialize(["key": value]).should.equal(`["key":custom value]`);
}

@("overrides the default immutable class serializer")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  class A {}

  string serializer(immutable A) {
    return "value";
  }
  auto registry = new SerializerRegistry();
  registry.register(&serializer);

  immutable A ivalue;
  const A cvalue;
  A value;

  registry.serialize(value).should.equal("null");
  registry.serialize(cvalue).should.equal("null");
  registry.serialize(ivalue).should.equal("value");
  registry.serialize(ivalue).should.equal("value");
  registry.serialize([ivalue]).should.equal("[value]");
  registry.serialize(["key": ivalue]).should.equal(`["key":value]`);
}

@("serializes a char")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  char ch = 'a';
  const char cch = 'a';
  immutable char ich = 'a';

  SerializerRegistry.instance.serialize(ch).should.equal("a");
  SerializerRegistry.instance.serialize(cch).should.equal("a");
  SerializerRegistry.instance.serialize(ich).should.equal("a");
}

@("serializes a SysTime")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  SysTime val = SysTime.fromISOExtString("2010-07-04T07:06:12");
  const SysTime cval = SysTime.fromISOExtString("2010-07-04T07:06:12");
  immutable SysTime ival = SysTime.fromISOExtString("2010-07-04T07:06:12");

  SerializerRegistry.instance.serialize(val).should.equal("2010-07-04T07:06:12");
  SerializerRegistry.instance.serialize(cval).should.equal("2010-07-04T07:06:12");
  SerializerRegistry.instance.serialize(ival).should.equal("2010-07-04T07:06:12");
}

@("serializes a string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  string str = "aaa";
  const string cstr = "aaa";
  immutable string istr = "aaa";

  SerializerRegistry.instance.serialize(str).should.equal(`aaa`);
  SerializerRegistry.instance.serialize(cstr).should.equal(`aaa`);
  SerializerRegistry.instance.serialize(istr).should.equal(`aaa`);
}

@("serializes an int")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int value = 23;
  const int cvalue = 23;
  immutable int ivalue = 23;

  SerializerRegistry.instance.serialize(value).should.equal(`23`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`23`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`23`);
}

@("serializes an int list")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[] value = [2,3];
  const int[] cvalue = [2,3];
  immutable int[] ivalue = [2,3];

  SerializerRegistry.instance.serialize(value).should.equal(`[2, 3]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`[2, 3]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`[2, 3]`);
}

@("serializes a void list")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  void[] value = [];
  const void[] cvalue = [];
  immutable void[] ivalue = [];

  SerializerRegistry.instance.serialize(value).should.equal(`[]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`[]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`[]`);
}

@("serializes a nested int list")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[][] value = [[0,1],[2,3]];
  const int[][] cvalue = [[0,1],[2,3]];
  immutable int[][] ivalue = [[0,1],[2,3]];

  SerializerRegistry.instance.serialize(value).should.equal(`[[0, 1], [2, 3]]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`[[0, 1], [2, 3]]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`[[0, 1], [2, 3]]`);
}

@("serializes an assoc array")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  int[string] value = ["a": 2,"b": 3, "c": 4];
  const int[string] cvalue = ["a": 2,"b": 3, "c": 4];
  immutable int[string] ivalue = ["a": 2,"b": 3, "c": 4];

  SerializerRegistry.instance.serialize(value).should.equal(`["a":2, "b":3, "c":4]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`["a":2, "b":3, "c":4]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`["a":2, "b":3, "c":4]`);
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

  SerializerRegistry.instance.serialize(value).should.equal(`a`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`a`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`a`);
}

version(unittest) { struct TestStruct { int a; string b; }; }
@("serializes a struct")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  TestStruct value = TestStruct(1, "2");
  const TestStruct cvalue = TestStruct(1, "2");
  immutable TestStruct ivalue = TestStruct(1, "2");

  SerializerRegistry.instance.serialize(value).should.equal(`TestStruct(1, "2")`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`TestStruct(1, "2")`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`TestStruct(1, "2")`);
}

/// Returns the unqualified type name for an array type.
/// Appends "[]" to the element type name.
string unqualString(T: U[], U)() pure @safe if(isArray!T && !isSomeString!T) {
  import std.array : Appender;

  Appender!string result;
  result.put(unqualString!U);
  result.put("[]");
  return result[];
}

/// Returns the unqualified type name for an associative array type.
/// Formats as "ValueType[KeyType]".
string unqualString(T: V[K], V, K)() pure @safe if(isAssociativeArray!T) {
  import std.array : Appender;

  Appender!string result;
  result.put(unqualString!V);
  result.put("[");
  result.put(unqualString!K);
  result.put("]");
  return result[];
}

/// Returns the unqualified type name for a non-array type.
/// Uses fully qualified names for classes, structs, and interfaces.
string unqualString(T)() pure @safe if(isSomeString!T || (!isArray!T && !isAssociativeArray!T)) {
  static if(is(T == class) || is(T == struct) || is(T == interface)) {
    return fullyQualifiedName!(Unqual!(T));
  } else {
    return Unqual!T.stringof;
  }

}

/// Joins the type names of a class hierarchy.
/// Includes base classes and implemented interfaces.
string joinClassTypes(T)() pure @safe {
  import std.array : Appender;

  Appender!string result;

  static if(is(T == class)) {
    static foreach(Type; BaseClassesTuple!T) {
      result.put(Type.stringof);
    }
  }

  static if(is(T == interface) || is(T == class)) {
    static foreach(Type; InterfacesTuple!T) {
      if(result[].length > 0) result.put(":");
      result.put(Type.stringof);
    }
  }

  static if(!is(T == interface) && !is(T == class)) {
    result.put(Unqual!T.stringof);
  }

  return result[];
}

/// Parses a serialized list string into individual elements.
/// Handles nested arrays, quoted strings, and char literals.
/// Params:
///   value = The serialized list string (e.g., "[1, 2, 3]")
/// Returns: A HeapStringList containing individual element strings.
HeapStringList parseList(HeapString value) @trusted nothrow @nogc {
  return parseList(value[]);
}

/// ditto
HeapStringList parseList(const(char)[] value) @trusted nothrow @nogc {
  HeapStringList result;

  if (value.length == 0) {
    return result;
  }

  if (value.length == 1) {
    auto item = HeapString.create(1);
    item.put(value[0]);
    result.put(item);
    return result;
  }

  if (value[0] != '[' || value[value.length - 1] != ']') {
    auto item = HeapString.create(value.length);
    item.put(value);
    result.put(item);
    return result;
  }

  HeapString currentValue;
  bool isInsideString;
  bool isInsideChar;
  bool isInsideArray;
  long arrayIndex = 0;

  foreach (index; 1 .. value.length - 1) {
    auto ch = value[index];
    auto canSplit = !isInsideString && !isInsideChar && !isInsideArray;

    if (canSplit && ch == ',' && currentValue.length > 0) {
      auto stripped = stripHeapString(currentValue);
      result.put(stripped);
      currentValue = HeapString.init;
      continue;
    }

    if (!isInsideChar && !isInsideString) {
      if (ch == '[') {
        arrayIndex++;
        isInsideArray = true;
      }

      if (ch == ']') {
        arrayIndex--;

        if (arrayIndex == 0) {
          isInsideArray = false;
        }
      }
    }

    if (!isInsideArray) {
      if (!isInsideChar && ch == '"') {
        isInsideString = !isInsideString;
      }

      if (!isInsideString && ch == '\'') {
        isInsideChar = !isInsideChar;
      }
    }

    currentValue.put(ch);
  }

  if (currentValue.length > 0) {
    auto stripped = stripHeapString(currentValue);
    result.put(stripped);
  }

  return result;
}

/// Strips leading and trailing whitespace from a HeapString.
private HeapString stripHeapString(ref HeapString input) @trusted nothrow @nogc {
  if (input.length == 0) {
    return HeapString.init;
  }

  auto data = input[];
  size_t start = 0;
  size_t end = data.length;

  while (start < end && (data[start] == ' ' || data[start] == '\t')) {
    start++;
  }

  while (end > start && (data[end - 1] == ' ' || data[end - 1] == '\t')) {
    end--;
  }

  auto result = HeapString.create(end - start);
  result.put(data[start .. end]);
  return result;
}

/// Helper function for testing: checks if HeapStringList matches expected strings.
version(unittest) {
  private void assertHeapStringListEquals(ref HeapStringList list, string[] expected) {
    import std.conv : to;
    assert(list.length == expected.length,
      "Length mismatch: got " ~ list.length.to!string ~ ", expected " ~ expected.length.to!string);
    foreach (i, exp; expected) {
      assert(list[i][] == exp,
        "Element " ~ i.to!string ~ " mismatch: got '" ~ list[i][].idup ~ "', expected '" ~ exp ~ "'");
    }
  }
}

@("parseList parses an empty string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "".parseList;
  assertHeapStringListEquals(pieces, []);
}

@("parseList does not parse a string that does not contain []")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "test".parseList;
  assertHeapStringListEquals(pieces, ["test"]);
}

@("parseList does not parse a char that does not contain []")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "t".parseList;
  assertHeapStringListEquals(pieces, ["t"]);
}

@("parseList parses an empty array")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[]".parseList;
  assertHeapStringListEquals(pieces, []);
}

@("parseList parses a list of one number")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[1]".parseList;
  assertHeapStringListEquals(pieces, ["1"]);
}

@("parseList parses a list of two numbers")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[1,2]".parseList;
  assertHeapStringListEquals(pieces, ["1", "2"]);
}

@("parseList removes the whitespaces from the parsed values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[ 1, 2 ]".parseList;
  assertHeapStringListEquals(pieces, ["1", "2"]);
}

@("parseList parses two string values that contain a comma")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ "a,b", "c,d" ]`.parseList;
  assertHeapStringListEquals(pieces, [`"a,b"`, `"c,d"`]);
}

@("parseList parses two string values that contain a single quote")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ "a'b", "c'd" ]`.parseList;
  assertHeapStringListEquals(pieces, [`"a'b"`, `"c'd"`]);
}

@("parseList parses two char values that contain a comma")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ ',' , ',' ]`.parseList;
  assertHeapStringListEquals(pieces, [`','`, `','`]);
}

@("parseList parses two char values that contain brackets")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ '[' , ']' ]`.parseList;
  assertHeapStringListEquals(pieces, [`'['`, `']'`]);
}

@("parseList parses two string values that contain brackets")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ "[" , "]" ]`.parseList;
  assertHeapStringListEquals(pieces, [`"["`, `"]"`]);
}

@("parseList parses two char values that contain a double quote")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ '"' , '"' ]`.parseList;
  assertHeapStringListEquals(pieces, [`'"'`, `'"'`]);
}

@("parseList parses two empty lists")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ [] , [] ]`.parseList;
  assertHeapStringListEquals(pieces, [`[]`, `[]`]);
}

@("parseList parses two nested lists")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ [[],[]] , [[[]],[]] ]`.parseList;
  assertHeapStringListEquals(pieces, [`[[],[]]`, `[[[]],[]]`]);
}

@("parseList parses two lists with items")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ [1,2] , [3,4] ]`.parseList;
  assertHeapStringListEquals(pieces, [`[1,2]`, `[3,4]`]);
}

@("parseList parses two lists with string and char items")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ ["1", "2"] , ['3', '4'] ]`.parseList;
  assertHeapStringListEquals(pieces, [`["1", "2"]`, `['3', '4']`]);
}

/// Removes surrounding quotes from a string value.
/// Handles both double quotes and single quotes.
/// Params:
///   value = The potentially quoted string
/// Returns: The string with surrounding quotes removed.
const(char)[] cleanString(HeapString value) @safe nothrow @nogc {
  return cleanString(value[]);
}

/// ditto
const(char)[] cleanString(const(char)[] value) @safe nothrow @nogc {
  if (value.length <= 1) {
    return value;
  }

  char first = value[0];
  char last = value[value.length - 1];

  if (first == last && (first == '"' || first == '\'')) {
    return value[1 .. $ - 1];
  }

  return value;
}

/// Overload for immutable strings that returns string for backward compatibility.
string cleanString(string value) @safe nothrow @nogc {
  if (value.length <= 1) {
    return value;
  }

  char first = value[0];
  char last = value[value.length - 1];

  if (first == last && (first == '"' || first == '\'')) {
    return value[1 .. $ - 1];
  }

  return value;
}

@("cleanString returns an empty string when the input is an empty string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  "".cleanString.should.equal("");
}

@("cleanString returns the input value when it has one char")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  "'".cleanString.should.equal("'");
}

@("cleanString removes the double quote from start and end of the string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  `""`.cleanString.should.equal(``);
}

@("cleanString removes the single quote from start and end of the string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  `''`.cleanString.should.equal(``);
}

/// Removes surrounding quotes from each HeapString in a HeapStringList.
/// Modifies the list in place.
/// Params:
///   pieces = The HeapStringList of potentially quoted strings
void cleanString(ref HeapStringList pieces) @trusted nothrow @nogc {
  foreach (i; 0 .. pieces.length) {
    auto cleaned = cleanString(pieces[i][]);
    if (cleaned.length != pieces[i].length) {
      auto newItem = HeapString.create(cleaned.length);
      newItem.put(cleaned);
      pieces[i] = newItem;
    }
  }
}

@("cleanString modifies empty HeapStringList without error")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  HeapStringList empty;
  cleanString(empty);
  assert(empty.length == 0, "empty list should remain empty");
}

@("cleanString removes double quotes from HeapStringList elements")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = parseList(`["1", "2"]`);
  cleanString(pieces);
  assert(pieces.length == 2, "should have 2 elements");
  assert(pieces[0][] == "1", "first element should be '1' without quotes");
  assert(pieces[1][] == "2", "second element should be '2' without quotes");
}
