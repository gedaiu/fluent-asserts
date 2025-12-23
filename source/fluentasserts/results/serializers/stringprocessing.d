/// String processing and list parsing functions for serializers.
module fluentasserts.results.serializers.stringprocessing;

import std.array;
import std.string;
import std.algorithm;
import std.traits;
import std.conv;
import std.datetime;

import fluentasserts.core.memory.heapstring : HeapString, HeapStringList;

version(unittest) {
  import fluent.asserts;
  import fluentasserts.core.lifecycle;
}

/// Replaces ASCII control characters and trailing spaces with visual representations from ResultGlyphs.
/// Params:
///   value = The string to process
/// Returns: A HeapString with control characters and trailing spaces replaced by glyphs.
HeapString replaceSpecialChars(const(char)[] value) @trusted nothrow @nogc {
  import fluentasserts.results.message : ResultGlyphs;

  size_t trailingSpaceStart = value.length;
  foreach_reverse (i, c; value) {
    if (c != ' ') {
      trailingSpaceStart = i + 1;
      break;
    }
  }
  if (value.length > 0 && value[0] == ' ' && trailingSpaceStart == value.length) {
    trailingSpaceStart = 0;
  }

  auto result = HeapString.create(value.length);

  foreach (i, c; value) {
    if (c < 32 || c == 127) {
      switch (c) {
        case '\0': result.put(ResultGlyphs.nullChar); break;
        case '\a': result.put(ResultGlyphs.bell); break;
        case '\b': result.put(ResultGlyphs.backspace); break;
        case '\t': result.put(ResultGlyphs.tab); break;
        case '\n': result.put(ResultGlyphs.newline); break;
        case '\v': result.put(ResultGlyphs.verticalTab); break;
        case '\f': result.put(ResultGlyphs.formFeed); break;
        case '\r': result.put(ResultGlyphs.carriageReturn); break;
        case 27:   result.put(ResultGlyphs.escape); break;
        default:   putHex(result, cast(ubyte) c); break;
      }
    } else if (c == ' ' && i >= trailingSpaceStart) {
      result.put(ResultGlyphs.space);
    } else {
      result.put(c);
    }
  }

  return result;
}

/// Appends a hex escape sequence like `\x1F` to the buffer.
private void putHex(ref HeapString buf, ubyte b) @safe nothrow @nogc {
  static immutable hexDigits = "0123456789ABCDEF";
  buf.put('\\');
  buf.put('x');
  buf.put(hexDigits[b >> 4]);
  buf.put(hexDigits[b & 0xF]);
}

/// Parses a serialized list string into individual elements.
/// Handles nested arrays, quoted strings, and char literals.
/// Params:
///   value = The serialized list string (e.g., "[1, 2, 3]")
/// Returns: A HeapStringList containing individual element strings.
HeapStringList parseList(HeapString value) @trusted nothrow @nogc {
  return parseList(value[]);
}

/// ditto
HeapStringList parseList(const(char)[] value) @trusted nothrow @nogc {
  HeapStringList result;

  if (value.length == 0) {
    return result;
  }

  if (value.length == 1) {
    auto item = HeapString.create(1);
    item.put(value[0]);
    result.put(item);
    return result;
  }

  if (value[0] != '[' || value[value.length - 1] != ']') {
    auto item = HeapString.create(value.length);
    item.put(value);
    result.put(item);
    return result;
  }

  HeapString currentValue;
  bool isInsideString;
  bool isInsideChar;
  bool isInsideArray;
  long arrayIndex = 0;

  foreach (index; 1 .. value.length - 1) {
    auto ch = value[index];
    auto canSplit = !isInsideString && !isInsideChar && !isInsideArray;

    if (canSplit && ch == ',' && currentValue.length > 0) {
      auto stripped = stripHeapString(currentValue);
      result.put(stripped);
      currentValue = HeapString.init;
      continue;
    }

    if (!isInsideChar && !isInsideString) {
      if (ch == '[') {
        arrayIndex++;
        isInsideArray = true;
      }

      if (ch == ']') {
        arrayIndex--;

        if (arrayIndex == 0) {
          isInsideArray = false;
        }
      }
    }

    if (!isInsideArray) {
      if (!isInsideChar && ch == '"') {
        isInsideString = !isInsideString;
      }

      if (!isInsideString && ch == '\'') {
        isInsideChar = !isInsideChar;
      }
    }

    currentValue.put(ch);
  }

  if (currentValue.length > 0) {
    auto stripped = stripHeapString(currentValue);
    result.put(stripped);
  }

  return result;
}

/// Strips leading and trailing whitespace from a HeapString.
private HeapString stripHeapString(ref HeapString input) @trusted nothrow @nogc {
  if (input.length == 0) {
    return HeapString.init;
  }

  auto data = input[];
  size_t start = 0;
  size_t end = data.length;

  while (start < end && (data[start] == ' ' || data[start] == '\t')) {
    start++;
  }

  while (end > start && (data[end - 1] == ' ' || data[end - 1] == '\t')) {
    end--;
  }

  auto result = HeapString.create(end - start);
  result.put(data[start .. end]);
  return result;
}

/// Removes surrounding quotes from a string value.
/// Handles both double quotes and single quotes.
/// Params:
///   value = The potentially quoted string
/// Returns: The string with surrounding quotes removed.
const(char)[] cleanString(HeapString value) @safe nothrow @nogc {
  return cleanString(value[]);
}

/// ditto
const(char)[] cleanString(const(char)[] value) @safe nothrow @nogc {
  if (value.length <= 1) {
    return value;
  }

  char first = value[0];
  char last = value[value.length - 1];

  if (first == last && (first == '"' || first == '\'')) {
    return value[1 .. $ - 1];
  }

  return value;
}

/// Overload for immutable strings that returns string for backward compatibility.
string cleanString(string value) @safe nothrow @nogc {
  if (value.length <= 1) {
    return value;
  }

  char first = value[0];
  char last = value[value.length - 1];

  if (first == last && (first == '"' || first == '\'')) {
    return value[1 .. $ - 1];
  }

  return value;
}

/// Removes surrounding quotes from each HeapString in a HeapStringList.
/// Modifies the list in place.
/// Params:
///   pieces = The HeapStringList of potentially quoted strings
void cleanString(ref HeapStringList pieces) @trusted nothrow @nogc {
  foreach (i; 0 .. pieces.length) {
    auto cleaned = cleanString(pieces[i][]);
    if (cleaned.length != pieces[i].length) {
      auto newItem = HeapString.create(cleaned.length);
      newItem.put(cleaned);
      pieces[i] = newItem;
    }
  }
}

/// Helper function for testing: checks if HeapStringList matches expected strings.
version(unittest) {
  private void assertHeapStringListEquals(ref HeapStringList list, string[] expected) {
    import std.conv : to;
    assert(list.length == expected.length,
      "Length mismatch: got " ~ list.length.to!string ~ ", expected " ~ expected.length.to!string);
    foreach (i, exp; expected) {
      assert(list[i][] == exp,
        "Element " ~ i.to!string ~ " mismatch: got '" ~ list[i][].idup ~ "', expected '" ~ exp ~ "'");
    }
  }
}

// Unit tests for replaceSpecialChars
@("replaceSpecialChars replaces null character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\0world");
  result[].should.equal("hello\\0world");
}

@("replaceSpecialChars replaces tab character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\tworld");
  result[].should.equal("hello\\tworld");
}

@("replaceSpecialChars replaces newline character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\nworld");
  result[].should.equal("hello\\nworld");
}

@("replaceSpecialChars replaces carriage return character")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\rworld");
  result[].should.equal("hello\\rworld");
}

@("replaceSpecialChars replaces trailing spaces")
unittest {
  import fluentasserts.results.message : ResultGlyphs;

  Lifecycle.instance.disableFailureHandling = false;
  auto savedSpace = ResultGlyphs.space;
  scope(exit) ResultGlyphs.space = savedSpace;
  ResultGlyphs.space = "\u00B7";

  auto result = replaceSpecialChars("hello   ");
  result[].should.equal("hello\u00B7\u00B7\u00B7");
}

@("replaceSpecialChars preserves internal spaces")
unittest {
  import fluentasserts.results.message : ResultGlyphs;

  Lifecycle.instance.disableFailureHandling = false;
  auto savedSpace = ResultGlyphs.space;
  scope(exit) ResultGlyphs.space = savedSpace;
  ResultGlyphs.space = "\u00B7";

  auto result = replaceSpecialChars("hello world");
  result[].should.equal("hello world");
}

@("replaceSpecialChars replaces all spaces when string is only spaces")
unittest {
  import fluentasserts.results.message : ResultGlyphs;

  Lifecycle.instance.disableFailureHandling = false;
  auto savedSpace = ResultGlyphs.space;
  scope(exit) ResultGlyphs.space = savedSpace;
  ResultGlyphs.space = "\u00B7";

  auto result = replaceSpecialChars("   ");
  result[].should.equal("\u00B7\u00B7\u00B7");
}

@("replaceSpecialChars handles empty string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("");
  result[].should.equal("");
}

@("replaceSpecialChars replaces unknown control character with hex")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\x01world");
  result[].should.equal("hello\\x01world");
}

@("replaceSpecialChars replaces DEL character with hex")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto result = replaceSpecialChars("hello\x7Fworld");
  result[].should.equal("hello\\x7Fworld");
}

// Unit tests for parseList
@("parseList parses an empty string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "".parseList;
  assertHeapStringListEquals(pieces, []);
}

@("parseList does not parse a string that does not contain []")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "test".parseList;
  assertHeapStringListEquals(pieces, ["test"]);
}

@("parseList does not parse a char that does not contain []")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "t".parseList;
  assertHeapStringListEquals(pieces, ["t"]);
}

@("parseList parses an empty array")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[]".parseList;
  assertHeapStringListEquals(pieces, []);
}

@("parseList parses a list of one number")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[1]".parseList;
  assertHeapStringListEquals(pieces, ["1"]);
}

@("parseList parses a list of two numbers")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[1,2]".parseList;
  assertHeapStringListEquals(pieces, ["1", "2"]);
}

@("parseList removes the whitespaces from the parsed values")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = "[ 1, 2 ]".parseList;
  assertHeapStringListEquals(pieces, ["1", "2"]);
}

@("parseList parses two string values that contain a comma")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ "a,b", "c,d" ]`.parseList;
  assertHeapStringListEquals(pieces, [`"a,b"`, `"c,d"`]);
}

@("parseList parses two string values that contain a single quote")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ "a'b", "c'd" ]`.parseList;
  assertHeapStringListEquals(pieces, [`"a'b"`, `"c'd"`]);
}

@("parseList parses two char values that contain a comma")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ ',' , ',' ]`.parseList;
  assertHeapStringListEquals(pieces, [`','`, `','`]);
}

@("parseList parses two char values that contain brackets")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ '[' , ']' ]`.parseList;
  assertHeapStringListEquals(pieces, [`'['`, `']'`]);
}

@("parseList parses two string values that contain brackets")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ "[" , "]" ]`.parseList;
  assertHeapStringListEquals(pieces, [`"["`, `"]"`]);
}

@("parseList parses two char values that contain a double quote")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ '"' , '"' ]`.parseList;
  assertHeapStringListEquals(pieces, [`'"'`, `'"'`]);
}

@("parseList parses two empty lists")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ [] , [] ]`.parseList;
  assertHeapStringListEquals(pieces, [`[]`, `[]`]);
}

@("parseList parses two nested lists")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ [[],[]] , [[[]],[]] ]`.parseList;
  assertHeapStringListEquals(pieces, [`[[],[]]`, `[[[]],[]]`]);
}

@("parseList parses two lists with items")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ [1,2] , [3,4] ]`.parseList;
  assertHeapStringListEquals(pieces, [`[1,2]`, `[3,4]`]);
}

@("parseList parses two lists with string and char items")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = `[ ["1", "2"] , ['3', '4'] ]`.parseList;
  assertHeapStringListEquals(pieces, [`["1", "2"]`, `['3', '4']`]);
}

// Unit tests for cleanString
@("cleanString returns an empty string when the input is an empty string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  "".cleanString.should.equal("");
}

@("cleanString returns the input value when it has one char")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  "'".cleanString.should.equal("'");
}

@("cleanString removes the double quote from start and end of the string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  `""`.cleanString.should.equal(``);
}

@("cleanString removes the single quote from start and end of the string")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  `''`.cleanString.should.equal(``);
}

@("cleanString modifies empty HeapStringList without error")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  HeapStringList empty;
  cleanString(empty);
  assert(empty.length == 0, "empty list should remain empty");
}

@("cleanString removes double quotes from HeapStringList elements")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto pieces = parseList(`["1", "2"]`);
  cleanString(pieces);
  assert(pieces.length == 2, "should have 2 elements");
  assert(pieces[0][] == "1", "first element should be '1' without quotes");
  assert(pieces[1][] == "2", "second element should be '2' without quotes");
}
