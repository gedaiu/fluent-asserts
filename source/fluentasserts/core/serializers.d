module fluentasserts.core.serializers;

import std.array;
import std.string;
import std.algorithm;
import std.traits;
import std.conv;
import std.datetime;
import std.functional;

version(unittest) import fluent.asserts;
/// Singleton used to serialize to string the tested values
class SerializerRegistry {
  static SerializerRegistry instance;

  private {
    string delegate(void*)[string] serializers;
    string delegate(const void*)[string] constSerializers;
    string delegate(immutable void*)[string] immutableSerializers;
  }

  ///
  void register(T)(string delegate(T) serializer) if(isAggregateType!T) {
    enum key = T.stringof;

    static if(is(Unqual!T == T)) {
      string wrap(void* val) {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      serializers[key] = &wrap;
    } else static if(is(ConstOf!T == T)) {
      string wrap(const void* val) {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      constSerializers[key] = &wrap;
    } else static if(is(ImmutableOf!T == T)) {
      string wrap(immutable void* val) {
        auto value = (cast(T*) val);
        return serializer(*value);
      }

      immutableSerializers[key] = &wrap;
    }
  }

  void register(T)(string function(T) serializer) {
    auto serializerDelegate = serializer.toDelegate;
    this.register(serializerDelegate);
  }

  ///
  string serialize(T)(T[] value) if(!isSomeString!(T[])) {
    static if(is(Unqual!T == void)) {
      return "[]";
    } else {
      return "[" ~ value.map!(a => serialize(a)).joiner(", ").array.to!string ~ "]";
    }
  }

  ///
  string serialize(T: V[K], V, K)(T value) {
    auto keys = value.byKey.array.sort;

    return "[" ~ keys.map!(a => serialize(a) ~ ":" ~ serialize(value[a])).joiner(", ").array.to!string ~ "]";
  }

  ///
  string serialize(T)(T value) if(isAggregateType!T) {
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
        result = T.stringof ~ "(" ~ v.toHash.to!string ~ ")";
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
      result = result[0..pos] ~ result[pos + 1..$];
    }

    if(result.indexOf("immutable(") == 0) {
      result = result[10..$];
      auto pos = result.indexOf(")");
      result = result[0..pos] ~ result[pos + 1..$];
    }

    return result;
  }

  ///
  string serialize(T)(T value) if(!is(T == enum) && (isSomeString!T || (!isArray!T && !isAssociativeArray!T && !isAggregateType!T))) {
    static if(isSomeString!T) {
      return `"` ~ value.to!string ~ `"`;
    } else static if(isSomeChar!T) {
      return `'` ~ value.to!string ~ `'`;
    } else {
      return value.to!string;
    }
  }

  string serialize(T)(T value) if(is(T == enum)) {
    static foreach(member; EnumMembers!T) {
      if(member == value) {
        return this.serialize(cast(OriginalType!T) member);
      }
    }

    throw new Exception("The value can not be serialized.");
  }

  string niceValue(T)(T value) {
    static if(is(Unqual!T == SysTime)) {
      return value.toISOExtString;
    } else static if(is(Unqual!T == Duration)) {
      return value.to!string;
    } else {
      return serialize(value);
    }
  }
}

/// It should be able to override the default struct serializer
unittest {
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

/// It should be able to override the default const struct serializer
unittest {
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

/// It should be able to override the default immutable struct serializer
unittest {
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


/// It should be able to override the default class serializer
unittest {
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

/// It should be able to override the default const class serializer
unittest {
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

/// It should be able to override the default immutable class serializer
unittest {
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

/// It should serialize a char
unittest {
  char ch = 'a';
  const char cch = 'a';
  immutable char ich = 'a';

  SerializerRegistry.instance.serialize(ch).should.equal("'a'");
  SerializerRegistry.instance.serialize(cch).should.equal("'a'");
  SerializerRegistry.instance.serialize(ich).should.equal("'a'");
}

/// It should serialize a SysTime
unittest {
  SysTime val = SysTime.fromISOExtString("2010-07-04T07:06:12");
  const SysTime cval = SysTime.fromISOExtString("2010-07-04T07:06:12");
  immutable SysTime ival = SysTime.fromISOExtString("2010-07-04T07:06:12");

  SerializerRegistry.instance.serialize(val).should.equal("2010-07-04T07:06:12");
  SerializerRegistry.instance.serialize(cval).should.equal("2010-07-04T07:06:12");
  SerializerRegistry.instance.serialize(ival).should.equal("2010-07-04T07:06:12");
}

/// It should serialize a string
unittest {
  string str = "aaa";
  const string cstr = "aaa";
  immutable string istr = "aaa";

  SerializerRegistry.instance.serialize(str).should.equal(`"aaa"`);
  SerializerRegistry.instance.serialize(cstr).should.equal(`"aaa"`);
  SerializerRegistry.instance.serialize(istr).should.equal(`"aaa"`);
}

/// It should serialize an int
unittest {
  int value = 23;
  const int cvalue = 23;
  immutable int ivalue = 23;

  SerializerRegistry.instance.serialize(value).should.equal(`23`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`23`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`23`);
}

/// It should serialize an int list
unittest {
  int[] value = [2,3];
  const int[] cvalue = [2,3];
  immutable int[] ivalue = [2,3];

  SerializerRegistry.instance.serialize(value).should.equal(`[2, 3]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`[2, 3]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`[2, 3]`);
}

/// It should serialize a void list
unittest {
  void[] value = [];
  const void[] cvalue = [];
  immutable void[] ivalue = [];

  SerializerRegistry.instance.serialize(value).should.equal(`[]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`[]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`[]`);
}

/// It should serialize a nested int list
unittest {
  int[][] value = [[0,1],[2,3]];
  const int[][] cvalue = [[0,1],[2,3]];
  immutable int[][] ivalue = [[0,1],[2,3]];

  SerializerRegistry.instance.serialize(value).should.equal(`[[0, 1], [2, 3]]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`[[0, 1], [2, 3]]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`[[0, 1], [2, 3]]`);
}

/// It should serialize an assoc array
unittest {
  int[string] value = ["a": 2,"b": 3, "c": 4];
  const int[string] cvalue = ["a": 2,"b": 3, "c": 4];
  immutable int[string] ivalue = ["a": 2,"b": 3, "c": 4];

  SerializerRegistry.instance.serialize(value).should.equal(`["a":2, "b":3, "c":4]`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`["a":2, "b":3, "c":4]`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`["a":2, "b":3, "c":4]`);
}

/// It should serialize a string enum
unittest {
  enum TestType : string {
    a = "a",
    b = "b"
  }
  TestType value = TestType.a;
  const TestType cvalue = TestType.a;
  immutable TestType ivalue = TestType.a;

  SerializerRegistry.instance.serialize(value).should.equal(`"a"`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`"a"`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`"a"`);
}

version(unittest) { struct TestStruct { int a; string b; }; }
/// It should serialize a struct
unittest {
  TestStruct value = TestStruct(1, "2");
  const TestStruct cvalue = TestStruct(1, "2");
  immutable TestStruct ivalue = TestStruct(1, "2");

  SerializerRegistry.instance.serialize(value).should.equal(`TestStruct(1, "2")`);
  SerializerRegistry.instance.serialize(cvalue).should.equal(`TestStruct(1, "2")`);
  SerializerRegistry.instance.serialize(ivalue).should.equal(`TestStruct(1, "2")`);
}

string unqualString(T: U[], U)() if(isArray!T && !isSomeString!T) {
  return unqualString!U ~ "[]";
}

string unqualString(T: V[K], V, K)() if(isAssociativeArray!T) {
  return unqualString!V ~ "[" ~ unqualString!K ~ "]";
}

string unqualString(T)() if(isSomeString!T || (!isArray!T && !isAssociativeArray!T)) {
  static if(is(T == class) || is(T == struct) || is(T == interface)) {
    return fullyQualifiedName!(Unqual!(T));
  } else {
    return Unqual!T.stringof;
  }

}


string joinClassTypes(T)() {
  string result;

  static if(is(T == class)) {
    static foreach(Type; BaseClassesTuple!T) {
      result ~= Type.stringof;
    }
  }

  static if(is(T == interface) || is(T == class)) {
    static foreach(Type; InterfacesTuple!T) {
      if(result.length > 0) result ~= ":";
      result ~= Type.stringof;
    }
  }

  static if(!is(T == interface) && !is(T == class)) {
    result = Unqual!T.stringof;
  }

  return result;
}

///
string[] parseList(string value) @safe nothrow {
  if(value.length == 0) {
    return [];
  }

  if(value.length == 1) {
    return [ value ];
  }

  if(value[0] != '[' || value[value.length - 1] != ']') {
    return [ value ];
  }

  string[] result;
  string currentValue;

  bool isInsideString;
  bool isInsideChar;
  bool isInsideArray;
  long arrayIndex = 0;

  foreach(index; 1..value.length - 1) {
    auto ch = value[index];
    auto canSplit = !isInsideString && !isInsideChar && !isInsideArray;

    if(canSplit && ch == ',' && currentValue.length > 0) {
      result ~= currentValue.strip.dup;
      currentValue = "";
      continue;
    }

    if(!isInsideChar && !isInsideString) {
      if(ch == '[') {
        arrayIndex++;
        isInsideArray = true;
      }

      if(ch == ']') {
        arrayIndex--;

        if(arrayIndex == 0) {
          isInsideArray = false;
        }
      }
    }

    if(!isInsideArray) {
      if(!isInsideChar && ch == '"') {
        isInsideString = !isInsideString;
      }

      if(!isInsideString && ch == '\'') {
        isInsideChar = !isInsideChar;
      }
    }

    currentValue ~= ch;
  }

  if(currentValue.length > 0) {
    result ~= currentValue.strip;
  }

  return result;
}

/// it should parse an empty string
unittest {
  auto pieces = "".parseList;

  pieces.should.equal([]);
}

/// it should not parse a string that does not contain []
unittest {
  auto pieces = "test".parseList;

  pieces.should.equal([ "test" ]);
}


/// it should not parse a char that does not contain []
unittest {
  auto pieces = "t".parseList;

  pieces.should.equal([ "t" ]);
}

/// it should parse an empty array
unittest {
  auto pieces = "[]".parseList;

  pieces.should.equal([]);
}

/// it should parse a list of one number
unittest {
  auto pieces = "[1]".parseList;

  pieces.should.equal(["1"]);
}

/// it should parse a list of two numbers
unittest {
  auto pieces = "[1,2]".parseList;

  pieces.should.equal(["1","2"]);
}

/// it should remove the whitespaces from the parsed values
unittest {
  auto pieces = "[ 1, 2 ]".parseList;

  pieces.should.equal(["1","2"]);
}

/// it should parse two string values that contain a `,`
unittest {
  auto pieces = `[ "a,b", "c,d" ]`.parseList;

  pieces.should.equal([`"a,b"`,`"c,d"`]);
}

/// it should parse two string values that contain a `'`
unittest {
  auto pieces = `[ "a'b", "c'd" ]`.parseList;

  pieces.should.equal([`"a'b"`,`"c'd"`]);
}

/// it should parse two char values that contain a `,`
unittest {
  auto pieces = `[ ',' , ',' ]`.parseList;

  pieces.should.equal([`','`,`','`]);
}

/// it should parse two char values that contain `[` and `]`
unittest {
  auto pieces = `[ '[' , ']' ]`.parseList;

  pieces.should.equal([`'['`,`']'`]);
}

/// it should parse two string values that contain `[` and `]`
unittest {
  auto pieces = `[ "[" , "]" ]`.parseList;

  pieces.should.equal([`"["`,`"]"`]);
}

/// it should parse two char values that contain a `"`
unittest {
  auto pieces = `[ '"' , '"' ]`.parseList;

  pieces.should.equal([`'"'`,`'"'`]);
}

/// it should parse two empty lists
unittest {
  auto pieces = `[ [] , [] ]`.parseList;
  pieces.should.equal([`[]`,`[]`]);
}

/// it should parse two nested lists
unittest {
  auto pieces = `[ [[],[]] , [[[]],[]] ]`.parseList;
  pieces.should.equal([`[[],[]]`,`[[[]],[]]`]);
}

/// it should parse two lists with items
unittest {
  auto pieces = `[ [1,2] , [3,4] ]`.parseList;
  pieces.should.equal([`[1,2]`,`[3,4]`]);
}

/// it should parse two lists with string and char items
unittest {
  auto pieces = `[ ["1", "2"] , ['3', '4'] ]`.parseList;
  pieces.should.equal([`["1", "2"]`,`['3', '4']`]);
}

/// it should parse two lists with string and char items
unittest {
  auto pieces = `[ ["1", "2"] , ['3', '4'] ]`.parseList;
  pieces.should.equal([`["1", "2"]`,`['3', '4']`]);
}

///
string cleanString(string value) @safe nothrow {
  if(value.length <= 1) {
    return value;
  }

  char first = value[0];
  char last = value[value.length - 1];

  if(first == last && (first == '"' || first == '\'')) {
    return value[1..$-1];
  }


  return value;
}

/// it should return an empty string when the input is an empty string
unittest {
  "".cleanString.should.equal("");
}

/// it should return the input value when it has one char
unittest {
  "'".cleanString.should.equal("'");
}

/// it should remove the " from start and end of the string
unittest {
  `""`.cleanString.should.equal(``);
}

/// it should remove the ' from start and end of the string
unittest {
  `''`.cleanString.should.equal(``);
}

///
string[] cleanString(string[] pieces) @safe nothrow {
  return pieces.map!(a => a.cleanString).array;
}

/// It should return an empty array when the input list is empty
unittest {
  string[] empty;

  empty.cleanString.should.equal(empty);
}

/// It should remove the `"` from the begin and end of the string
unittest {
  [`"1"`, `"2"`].cleanString.should.equal([`1`, `2`]);
}
