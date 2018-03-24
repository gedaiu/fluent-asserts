module fluentasserts.vibe.json;

version(Have_vibe_d_data):

import std.exception, std.conv;

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

version(unittest) {
  import fluentasserts.core.base;
}

@("Empty Json object keys")
unittest {
  Json.emptyObject.keys.length.should.equal(0);
}

@("Json object keys")
unittest {
  auto obj = Json.emptyObject;
  obj["key1"] = 1;
  obj["key2"] = 3;

  obj.keys.length.should.equal(2);
  obj.keys.should.contain(["key1", "key2"]);
}

@("Json array keys")
unittest {
  auto obj = Json.emptyArray;

  ({
    obj.keys.should.contain(["key1", "key2"]);
  }).should.throwAnyException.msg.should.startWith("Invalid Json type.");
}

/// It should be able to compare 2 empty json objects
unittest {
  Json.emptyObject.should.equal(Json.emptyObject);
}