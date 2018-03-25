module fluentasserts.vibe.json;

version(Have_vibe_d_data):

import std.exception, std.conv, std.traits;

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

  obj.keys.length.should.equal(2);
  obj.keys.should.contain(["key1", "key2"]);
}

/// Json array keys
unittest {
  auto obj = Json.emptyArray;

  ({
    obj.keys.should.contain(["key1", "key2"]);
  }).should.throwAnyException.msg.should.startWith("Invalid Json type.");
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

    Message[] msg = [
      Message(false, "They have different types "),
      Message(false, "`Json.Type."),
      Message(true, testData.type.to!string),
      Message(false, "` != `Json.Type."),
      Message(true, someValue.type.to!string),
      Message(false, "`.")
    ];

    return result(haveSameType, msg, [ new ExpectedActualResult(actual, expected) ], file, line);
  }

  auto validateJsonType(U)(const string file, const size_t line) {
    Json.Type someType = Json.Type.undefined;
    string expected;
    string actual = "a Json.Type." ~ testData.type.to!string;

    static if(is(U == string)) {
      someType = Json.Type.string;
      expected = "a string or Json.Type." ~ someType.to!string;
    }

    static if(is(U == byte) || is(U == short) || is(U == int) || is(U == long) ||
              is(U == ubyte) || is(U == ushort) || is(U == uint) || is(U == ulong)) {
      someType = Json.Type.int_;

      expected = "a " ~ U.stringof ~ " or Json.Type." ~ someType.to!string;
    }

    static if(is(U == float)) {
      someType = Json.Type.float_;

      expected = "a " ~ U.stringof ~ " or Json.Type." ~ someType.to!string;
    }

    static if(is(U == bool)) {
      someType = Json.Type.bool_;

      expected = "a " ~ U.stringof ~ " or Json.Type." ~ someType.to!string;
    }

    if(expected == "") {
      expected = "a Json.Type." ~ someType.to!string;
    }

    auto haveSameType = someType == testData.type;

    Message[] msg = [
      Message(false, "They have different types "),
      Message(false, "`Json.Type."),
      Message(true, testData.type.to!string),
      Message(false, "` != `"),
      Message(true, U.stringof),
      Message(false, "`.")
    ];

    return result(haveSameType, msg, [ new ExpectedActualResult(expected, actual) ], file, line);
  }

  auto equal(U)(const U someValue, const string file = __FILE__, const size_t line = __LINE__) {
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
      static assert("You can not compare `" ~ U.stringof ~ "` with `Json`");
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

      auto isSame = testData == someValue;
      auto expected = expectedValue ? someValue.to!string : ("not " ~ someValue.to!string);

      return result(isSame, new ExpectedActualResult(expected, testData.to!string), file, line);
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

  msg.split("\n")[0].strip.should.equal("Json.emptyObject should equal `[]`. They have different types `Json.Type.object` != `Json.Type.array`.");
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

  msg.split("\n")[0].strip.should.equal("Json(4) should equal `some string`. They have different types `Json.Type.int_` != `string`.");
  msg.split("\n")[2].strip.should.equal("Expected:a string or Json.Type.string");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.int_");
}

/// It throws when you compare a Json string with integer values
unittest {
  auto msg = ({
    byte val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `byte`.");
  msg.split("\n")[2].strip.should.equal("Expected:a byte or Json.Type.int_");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.string");

  msg = ({
    short val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `short`.");

  msg = ({
    int val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `int`.");

  msg = ({
    long val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `long`.");
}

/// It throws when you compare a Json string with unsigned integer values
unittest {
  auto msg = ({
    ubyte val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `ubyte`.");

  msg = ({
    ushort val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `ushort`.");

  msg = ({
    uint val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `uint`.");

  msg = ({
    ulong val = 4;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `4`. Unexpected 's' when converting from type string to type long. They have different types `Json.Type.string` != `ulong`.");
}

/// It throws when you compare a Json string with floating point values
unittest {
  auto msg = ({
    float val = 3.14;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `3.14`. During conversion no digits seen. They have different types `Json.Type.string` != `float`.");
  msg.split("\n")[2].strip.should.equal("Expected:a float or Json.Type.float_");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.string");

  msg = ({
    double val = 3.14;
    Json("some string").should.equal(val);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `3.14`. During conversion no digits seen. They have different types `Json.Type.string` != `double`.");
}

/// It throws when you compare a Json string with bool values
unittest {
  auto msg = ({
    Json("some string").should.equal(false);
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].strip.should.equal("Json(\"some string\") should equal `false`. They have different types `Json.Type.string` != `bool`.");
  msg.split("\n")[2].strip.should.equal("Expected:a bool or Json.Type.bool_");
  msg.split("\n")[3].strip.should.equal("Actual:a Json.Type.string");
}

/// It should be able to compare two integers
unittest {
  ({
    Json(4).should.equal(4);
    Json(4).should.not.equal(5);
  }).should.not.throwAnyException;

  ({
    Json(4).should.equal(Json(4));
    Json(4).should.not.equal(Json(5));
  }).should.not.throwAnyException;

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

  msg.split("\n")[0].should.equal("Json(4) should equal `5`. They have different types `Json.Type.int_` != `string`.");

  msg = ({
    Json(4).should.equal(Json("5"));
  }).should.throwException!TestException.msg;

  msg.split("\n")[0].should.equal("Json(4) should equal `5`. They have different types `Json.Type.int_` != `Json.Type.string`.");
}
