/// SerializerRegistry for GC-based string serialization.
module fluentasserts.results.serializers.string_registry;

import std.array;
import std.string;
import std.algorithm;
import std.traits;
import std.conv;
import std.datetime;
import std.functional;

import fluentasserts.core.evaluation.constraints : isPrimitiveType;
import fluentasserts.results.serializers.helpers : replaceSpecialChars;

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

  /// Serializes an associative array to a string representation.
  /// Keys are sorted for consistent output.
  string serialize(T: V[K], V, K)(T value) @safe {
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
  string serialize(T)(T value) @trusted if(!is(T == enum) && isPrimitiveType!T) {
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

// Unit tests
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
