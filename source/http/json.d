module http.json;

import vibe.data.json;

string[] keys(Json obj) {
  string[] list;

  assert(obj.type == Json.Type.object, "The object should be an object.");

  foreach(string key, Json value; obj) {
    list ~= key;
  }

  return list;
}
