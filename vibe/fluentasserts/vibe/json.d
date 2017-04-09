module fluentasserts.vibe.json;

import std.exception, std. conv;

import vibe.data.json;

string[] keys(Json obj, const string file = __FILE__, const size_t line = __LINE__) {
  string[] list;

  enforce(obj.type == Json.Type.object, "The json should be an object. `" ~ obj.type.to!string ~ "` found.", file, line);

  foreach(string key, Json value; obj) {
    list ~= key;
  }

  return list;
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

  should.throwAnyException({
    obj.keys.should.contain(["key1", "key2"]);
  }).msg.should.equal("The json should be an object. `array` found.");
}