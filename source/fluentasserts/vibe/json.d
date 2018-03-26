module fluentasserts.vibe.json;

version(Have_vibe_d_data):

import std.exception, std.conv, std.traits;
import std.array, std.algorithm, std.typecons;

import vibe.data.json;
import fluentasserts.core.base;
import fluentasserts.core.results;

@safe:

string[] keys(Json obj, const string file = __FILE__, const size_t line = __LINE__) {
  string[] list;

  if(obj.type != Json.Type.object) {
    IResult[] results = [ cast(IResult) new MessageResult("Invalid Json type."),
                          cast(IResult) new ExpectedActualResult("object", obj.type.to!string),
                          cast(IResult) new SourceResult(file, line) ];

    throw new TestException(results, file, line);
  }

  static if(typeof(obj.byKeyValue).stringof == "Rng") {
    foreach(string key, Json value; obj.byKeyValue) {
      list ~= key;
    }

    return list;
  } else {
    pragma(msg, "Json.keys is not compatible with your vibe.d version");
    assert(false, "Json.keys is not compatible with your vibe.d version");
  }
}

/// Empty Json object keys
unittest {
  Json.emptyObject.keys.length.should.equal(0);
}

/// Json object keys
unittest {
  auto obj = Json.emptyObject;
  obj["key1"] = 1;
  obj["key2"] = 3;

  obj.keys.should.containOnly(["key1", "key2"]);
}

/// Json array keys
unittest {
  auto obj = Json.emptyArray;

  ({
    obj.keys.should.contain(["key1", "key2"]);
  }).should.throwAnyException.msg.should.startWith("Invalid Json type.");
}


string[] nestedKeys(Json obj) {
  string[] result;

  auto root = tuple("", obj);
  Tuple!(string, Json)[] queue = [ root ];

  while(queue.length > 0) {
    auto element = queue[0];

    if(element[0] != "") {
      if(element[1].type != Json.Type.object) {
        result ~= element[0];
      }

      if(element[1].type == Json.Type.object && element[1].length == 0) {
        result ~= element[0];
      }
    }

    if(element[1].type == Json.Type.object) {
      foreach(string key, value; element[1].byKeyValue) {
        string nextKey = key;

        if(element[0] != "") {
          nextKey = element[0] ~ "." ~ nextKey;
        }

        queue ~= tuple(nextKey, value);
      }
    }

    queue = queue[1..$];
  }

  return result;
}

/// Empty Json object keys
unittest {
  Json.emptyObject.nestedKeys.length.should.equal(0);
}

/// Get all keys froom nested object
unittest {
  auto obj = Json.emptyObject;
  obj["key1"] = 1;
  obj["key2"] = 2;
  obj["key3"] = Json.emptyObject;
  obj["key3"]["item1"] = "3";
  obj["key3"]["item2"] = Json.emptyObject;
  obj["key3"]["item2"]["item4"] = Json.emptyObject;
  obj["key3"]["item2"]["item5"] = Json.emptyObject;
  obj["key3"]["item2"]["item5"]["item6"] = Json.emptyObject;

  obj.nestedKeys.should.containOnly(["key1", "key2", "key3.item1", "key3.item2.item4", "key3.item2.item5.item6"]);
}

auto unpackJsonArray(T : U[], U)(Json data) if(!isArray!U && isBasicType!U) {
  return data.byValue.map!(a => a.to!U).array.dup;
}

auto unpackJsonArray(T : U[], U)(Json data) if(!isArray!U && is(Unqual!U == Json)) {
  U[] result;

  foreach(element; data.byValue) {
    result ~= element;
  }

  return result;
}

auto unpackJsonArray(T : U[], U)(Json data) if(isArray!(U) && !isSomeString!(U[])) {
  U[] result;

  foreach(element; data.byValue) {
    result ~= unpackJsonArray!(U)(element);
  }

  return result;
}

struct ShouldJson(T) {
  private const T testData;

  this(U)(U value) {
    valueEvaluation = value.evaluation;
    testData = value.value;
  }

  mixin ShouldCommons;
  mixin ShouldThrowableCommons;

  auto validateJsonType(const T someValue, const string file, const size_t line) {
    auto haveSameType = someValue.type == testData.type;

    string expected = "a Json.Type." ~ testData.type.to!string;
    string actual = "a Json.Type." ~ someValue.type.to!string;

    Message[] msg;
    
    if(!haveSameType) {
      msg = [
        Message(false, "They have incompatible types "),
        Message(false, "`Json.Type."),
        Message(true, testData.type.to!string),
        Message(false, "` != `Json.Type."),
        Message(true, someValue.type.to!string),
        Message(false, "`.")
      ];

      return result(haveSameType, msg, [ new ExpectedActualResult(actual, expected) ], file, line);
    }

    return result(haveSameType, msg, [ ], file, line);
  }

  auto validateJsonType(U)(const string file, const size_t line) {
    Json.Type someType = Json.Type.undefined;
    string expected;
    string actual = "a Json.Type." ~ testData.type.to!string;
    bool haveSameType;

    static if(is(U == string)) {
      someType = Json.Type.string;
      expected = "a string or Json.Type." ~ someType.to!string;
      haveSameType = someType == testData.type;
    }

    static if(is(U == byte) || is(U == short) || is(U == int) || is(U == long) ||
              is(U == ubyte) || is(U == ushort) || is(U == uint) || is(U == ulong)) {
      someType = Json.Type.int_;
      haveSameType = Json.Type.int_ == testData.type || Json.Type.float_ == testData.type;

      expected = "a " ~ U.stringof ~ " or Json.Type." ~ someType.to!string;
    }

    static if(is(U == float) || is(U == double)) {
      someType = Json.Type.float_;
      haveSameType = Json.Type.int_ == testData.type || Json.Type.float_ == testData.type;

      expected = "a " ~ U.stringof ~ " or Json.Type." ~ someType.to!string;
    }

    static if(is(U == bool)) {
      someType = Json.Type.bool_;
      haveSameType = someType == testData.type;

      expected = "a " ~ U.stringof ~ " or Json.Type." ~ someType.to!string;
    }

    static if(isArray!U && !isSomeString!U) {
      someType = Json.Type.array;
      haveSameType = someType == testData.type;

      expected = "a " ~ U.stringof ~ "[] or Json.Type." ~ someType.to!string;
    }

    if(expected == "") {
      expected = "a Json.Type." ~ someType.to!string;
    }

    Message[] msg = [
      Message(false, "They have incompatible types "),
      Message(false, "`Json.Type."),
      Message(true, testData.type.to!string),
      Message(false, "` != `"),
      Message(true, U.stringof),
      Message(false, "`.")
    ];

    return result(haveSameType, msg, [ new ExpectedActualResult(expected, actual) ], file, line);
  }

  auto equal(U)(const U someValue, const string file = __FILE__, const size_t line = __LINE__) if(!isArray!U || isSomeString!U) {
    addMessage(" equal `");
    addValue(someValue.to!string);
    addMessage("`");

    static if(is(U == string) || std.traits.isNumeric!U || is(U == bool)) {
      U nativeVal;

      try {
        nativeVal = testData.to!U;
      } catch(ConvException e) {
        addMessage(". ");
        if(e.msg.length > 0 && e.msg[0].toUpper == e.msg[0]) {
          addValue(e.msg);
        } else {
          addMessage("During conversion ");
          addValue(e.msg);
        }
      }
      validateException;

      if(expectedValue) {
        auto typeResult = validateJsonType!U(file, line);

        if(typeResult.willThrow) {
          return typeResult;
        }

        return nativeVal.should.equal(someValue, file, line);
      } else {
        return nativeVal.should.not.equal(someValue, file, line);
      }
    } else static if(is(U == Json)) {
      return equalJson(someValue, file, line);
    } else {
      static assert(false, "You can not validate `Json` against `" ~ U.stringof ~ "`");
    }
  }

  auto equal(U)(const U[] someArray, const string file = __FILE__, const size_t line = __LINE__) {
    addMessage(" equal `");
    addValue(someArray.to!string);
    addMessage("`");

    validateException;

    Unqual!U[] nativeVal;

    try {
      nativeVal = unpackJsonArray!(U[])(testData);
    } catch(Exception e) {
      addMessage(". ");
      if(e.msg.length > 0 && e.msg[0].toUpper == e.msg[0]) {
        addValue(e.msg);
      } else {
        addMessage("During conversion ");
        addValue(e.msg);
      }
    }

    static if(is(U == string) || std.traits.isNumeric!U || is(U == bool)) {

      if(expectedValue) {
        auto typeResult = validateJsonType!(U[])(file, line);

        if(typeResult.willThrow) {
          return typeResult;
        }

        return nativeVal.should.equal(someArray, file, line);
      } else {
        return nativeVal.should.not.equal(someArray, file, line);
      }
    } else static if(isArray!U) {
      if(expectedValue) {
        auto typeResult = validateJsonType!(U[])(file, line);

        if(typeResult.willThrow) {
          return typeResult;
        }

        return nativeVal.should.equal(someArray, file, line);
      } else {
        return nativeVal.should.not.equal(someArray, file, line);
      }
    } else static if(is(U == Json)) {
      
      if(expectedValue) {
        auto typeResult = validateJsonType!(U[])(file, line);

        if(typeResult.willThrow) {
          return typeResult;
        }

        return nativeVal.should.equal(someArray, file, line);
      } else {
        return nativeVal.should.not.equal(someArray, file, line);
      }
    } else {
      static assert(false, "You can not validate `Json` against `" ~ U.stringof ~ "`");
    }
  }

  private {
    auto equalJson(const Json someValue, const string file, const size_t line) {
      if(expectedValue) {
        auto typeResult = validateJsonType(someValue, file, line);

        if(typeResult.willThrow) {
          return typeResult;
        }
      }

      beginCheck;
      if(testData.type == Json.Type.string) {
        return equal(someValue.to!string, file, line);
      }

      if(testData.type == Json.Type.int_) {
        return equal(someValue.to!long, file, line);
      }

      if(testData.type == Json.Type.float_) {
        return equal(someValue.to!double, file, line);
      }

      if(testData.type == Json.Type.bool_) {
        return equal(someValue.to!bool, file, line);
      }

      if(testData.type == Json.Type.array) {
        Json[] values;

        foreach(value; someValue.byValue) {
          values ~= value;
        }

        return equal(values, file, line);
      }

      auto isSame = testData == someValue;
      auto expected = expectedValue ? someValue.to!string : ("not " ~ someValue.to!string);

      IResult[] results;

      results ~= new ExpectedActualResult(expected, testData.to!string);

      if(expectedValue) {
        auto infoResult = new ListInfoResult();
        auto comparison = ListComparison!string(someValue.nestedKeys, testData.nestedKeys);

        infoResult.add("Extra key", "Extra keys", comparison.extra);
        infoResult.add("Missing key", "Missing keys", comparison.missing);

        results ~= infoResult;
      }

      return result(isSame, [], results, file, line);
    }
  }
}

version(unittest) {
  import std.string;
}

/// It should be able to compare 2 empty json objects
unittest {
  Json.emptyObject.should.equal(Json.emptyObject);
}

/// It should be able to compare an empty object with an empty array
unittest {
  auto msg = ({
    Json.emptyObject.should.equal(Json.emptyArray);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json.emptyObject should equal `[]`. They have incompatible types `Json.Type.object` != `Json.Type.array`.");
  msg.split("\n")[2].strip.should.equal("Expected:a Json.Type.array");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.object");

  ({
    Json.emptyObject.should.not.equal(Json.emptyArray);
  }).should.not.throwException!TestException;
}

/// It should be able to compare two strings
unittest {
  ({
    Json("test string").should.equal("test string");
    Json("other string").should.not.equal("test");
  }).should.not.throwAnyException;

  ({
    Json("test string").should.equal(Json("test string"));
    Json("other string").should.not.equal(Json("test"));
  }).should.not.throwAnyException;

  auto msg = ({
    Json("test string").should.equal("test");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(\"test string\") should equal `test`. `test string` is not equal to `test`.");

  msg = ({
    Json("test string").should.equal(Json("test"));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(\"test string\") should equal `test`. `test string` is not equal to `test`.");
}

/// It throw on comparing a Json number with a string
unittest {
  auto msg = ({
    Json(4).should.equal("some string");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(4) should equal `some string`. They have incompatible types `Json.Type.int_` != `string`.");
  msg.split("\n")[2].strip.should.equal("Expected:a string or Json.Type.string");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.int_");
}

/// It throws when you compare a Json string with integer values
unittest {
  auto msg = ({
    byte val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `byte`.");
  msg.split("\n")[2].strip.should.equal("Expected:a byte or Json.Type.int_");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.string");

  msg = ({
    short val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `short`.");

  msg = ({
    int val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `int`.");

  msg = ({
    long val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `long`.");
}

/// It throws when you compare a Json string with unsigned integer values
unittest {
  auto msg = ({
    ubyte val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `ubyte`.");

  msg = ({
    ushort val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `ushort`.");

  msg = ({
    uint val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `uint`.");

  msg = ({
    ulong val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have incompatible types `Json.Type.string` != `ulong`.");
}

/// It throws when you compare a Json string with floating point values
unittest {
  auto msg = ({
    float val = 3.14;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `3.14`. During conversion no digits seen. They have incompatible types `Json.Type.string` != `float`.");
  msg.split("\n")[2].strip.should.equal("Expected:a float or Json.Type.float_");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.string");

  msg = ({
    double val = 3.14;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `3.14`. During conversion no digits seen. They have incompatible types `Json.Type.string` != `double`.");
}

/// It throws when you compare a Json string with bool values
unittest {
  auto msg = ({
    Json("some string").should.equal(false);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `false`. They have incompatible types `Json.Type.string` != `bool`.");
  msg.split("\n")[2].strip.should.equal("Expected:a bool or Json.Type.bool_");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.string");
}

/// It should be able to compare two integers
unittest {
  Json(4L).should.equal(4f);
  Json(4).should.equal(4);
  Json(4).should.not.equal(5);

  Json(4).should.equal(Json(4));
  Json(4).should.not.equal(Json(5));
  Json(4L).should.not.equal(Json(5f));

  auto msg = ({
    Json(4).should.equal(5);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4) should equal `5`.");

  msg = ({
    Json(4).should.equal(Json(5));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4) should equal `5`.");
}

/// It throws on comparing an integer Json with a string
unittest {
  auto msg = ({
    Json(4).should.equal("5");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4) should equal `5`. They have incompatible types `Json.Type.int_` != `string`.");

  msg = ({
    Json(4).should.equal(Json("5"));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4) should equal `5`. They have incompatible types `Json.Type.int_` != `Json.Type.string`.");
}

/// It should be able to compare two floating point numbers
unittest {
  Json(4f).should.equal(4L);
  Json(4.3).should.equal(4.3);
  Json(4.3).should.not.equal(5.3);

  Json(4.3).should.equal(Json(4.3));
  Json(4.3).should.not.equal(Json(5.3));

  auto msg = ({
    Json(4.3).should.equal(5.3);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4.3) should equal `5.3`.");

  msg = ({
    Json(4.3).should.equal(Json(5.3));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4.3) should equal `5.3`.");
}

/// It throws on comparing an floating point Json with a string
unittest {
  auto msg = ({
    Json(4f).should.equal("5");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4f) should equal `5`. They have incompatible types `Json.Type.float_` != `string`.");

  msg = ({
    Json(4f).should.equal(Json("5"));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4f) should equal `5`. They have incompatible types `Json.Type.float_` != `Json.Type.string`.");
}

/// It should be able to compare two booleans
unittest {
  Json(true).should.equal(true);
  Json(true).should.not.equal(false);

  Json(true).should.equal(Json(true));
  Json(true).should.not.equal(Json(false));

  auto msg = ({
    Json(true).should.equal(false);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(true) should equal `false`.");

  msg = ({
    Json(true).should.equal(Json(false));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(true) should equal `false`.");
}

/// It throws on comparing a bool Json with a string
unittest {
  auto msg = ({
    Json(true).should.equal("5");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(true) should equal `5`. They have incompatible types `Json.Type.bool_` != `string`.");

  msg = ({
    Json(true).should.equal(Json("5"));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(true) should equal `5`. They have incompatible types `Json.Type.bool_` != `Json.Type.string`.");
}

/// It should be able to compare two arrays
unittest {
  Json[] elements = [Json(1), Json(2)];
  Json[] otherElements = [Json(1), Json(2), Json(3)];

  Json(elements).should.equal([1, 2]);
  Json(elements).should.not.equal([1, 2, 3]);

  Json(elements).should.equal(Json(elements));
  Json(elements).should.not.equal(Json(otherElements));

  auto msg = ({
    Json(elements).should.equal(otherElements);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `[1, 2, 3]`.");

  msg = ({
    Json(elements).should.equal(otherElements);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `[1, 2, 3]`.");
}

/// It throws on comparing a Json array with a string
unittest {
  Json[] elements = [Json(1), Json(2)];
  auto msg = ({
    Json(elements).should.equal("5");
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `5`. They have incompatible types `Json.Type.array` != `string`.");

  msg = ({
    Json(elements).should.equal(Json("5"));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `5`. They have incompatible types `Json.Type.array` != `Json.Type.string`.");
}

/// It should be able to compare two nested arrays
unittest {
  Json[] element1 = [Json(1), Json(2)];
  Json[] element2 = [Json(10), Json(20)];

  Json[] elements = [Json(element1), Json(element2)];
  Json[] otherElements = [Json(element1), Json(element2), Json(element1)];

  Json(elements).should.equal([element1, element2]);
  Json(elements).should.not.equal([element1, element2, element1]);

  Json(elements).should.equal(Json(elements));
  Json(elements).should.not.equal(Json(otherElements));

  auto msg = ({
    Json(elements).should.equal(otherElements);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `[[1,2], [10,20], [1,2]]`.");

  msg = ({
    Json(elements).should.equal(Json(otherElements));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `[[1,2], [10,20], [1,2]]`.");
}

/// It should be able to compare two nested arrays with different levels
unittest {
  Json nestedElement = Json([Json(1), Json(2)]);

  Json[] elements = [nestedElement, Json(1)];
  Json[] otherElements = [nestedElement, Json(1), nestedElement];

  Json(elements).should.equal([nestedElement, Json(1)]);
  Json(elements).should.not.equal([nestedElement, Json(1), nestedElement]);

  Json(elements).should.equal(Json(elements));
  Json(elements).should.not.equal(Json(otherElements));

  auto msg = ({
    Json(elements).should.equal(otherElements);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `[[1,2], 1, [1,2]]`.");

  msg = ({
    Json(elements).should.equal(Json(otherElements));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(elements) should equal `[[1,2], 1, [1,2]]`.");
}

/// It should find the key differences inside a Json object
unittest {
  Json expectedObject = Json.emptyObject;
  Json testObject = Json.emptyObject;
  testObject["key"] = "some value";
  testObject["nested"] = Json.emptyObject;
  testObject["nested"]["item1"] = "hello";
  testObject["nested"]["item2"] = Json.emptyObject;
  testObject["nested"]["item2"]["value"] = "world";

  expectedObject["other"] = "other value";

  auto msg = ({
    testObject.should.equal(expectedObject);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("testObject should equal `{\"other\":\"other value\"}`.");
  msg.split("\n")[2].strip.should.equal(`Expected:{"other":"other value"}`);
  msg.split("\n")[3].strip.should.equal(`Actual:{"nested":{"item1":"hello","item2":{"value":"world"}},"key":"some value"}`);
  msg.split("\n")[5].strip.should.equal(`Extra keys:key,nested.item1,nested.item2.value`);
  msg.split("\n")[6].strip.should.equal(`Missing key:other`);
}