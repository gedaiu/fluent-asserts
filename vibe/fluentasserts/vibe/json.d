module fluentasserts.vibe.json;

import std.exception, std.conv;

import vibe.data.json;
import fluentasserts.core.base;
import fluentasserts.core.results;

string[] keys(Json obj, const string file = __FILE__, const size_t line = __LINE__) {
  string[] list;

  if(obj.type != Json.Type.object) {
    IResult[] results = [ cast(IResult) new MessageResult("Invalid Json type."),
                          cast(IResult) new ExpectedActualResult("object", obj.type.to!string),
                          cast(IResult) new SourceResult(file, line) ];

    throw new TestException(results, file, line);
  }

  foreach(string key, Json value; obj) {
    list ~= key;
  }

  return list;
}

version(unittest) {
  import fluentasserts.core.base;
}

@("Should work on Json string values")
unittest {
  Json("text").should.equal("text");
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
