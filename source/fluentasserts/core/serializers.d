module fluentasserts.core.serializers;

import std.array;
import std.string;
import std.algorithm;
import std.traits;
import std.conv;
import std.datetime;

version(unittest) import fluent.asserts;

/// Singleton used to serialize to string the tested values
class SerializerRegistry {
  ///
  static SerializerRegistry instance;

  private {
    void*[] serializers;
  }

  ///
  void register(T)(string delegate(T) serializer) {
    serializers[T.stringof] = &serializer;
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
    string result;

    static if(is(T == class)) {
      if(value is null) {
        result = "null";
      } else {
        result = T.stringof ~ "(" ~ (cast() value).toHash.to!string ~ ")";
      }
    } else static if(is(Unqual!T == Duration)) {
      result = value.total!"nsecs".to!string;
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
  string serialize(T)(T value) if(isSomeString!T || (!isArray!T && !isAssociativeArray!T && !isAggregateType!T)) {
    static if(isSomeString!T) {
      return `"` ~ value.to!string ~ `"`;
    } else static if(isSomeChar!T) {
      return `'` ~ value.to!string ~ `'`;
    } else {
      return value.to!string;
    }
  }

  string niceValue(T)(T value) {
    static if(is(Unqual!T == Duration)) {
      return value.to!string;
    } else {
      return serialize(value);
    }
  }
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

version(unittest) { struct TestStruct { int a; string b; }; }
/// It should serialzie a struct
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
  return Unqual!T.stringof;
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