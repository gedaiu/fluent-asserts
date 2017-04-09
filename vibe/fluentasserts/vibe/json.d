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
