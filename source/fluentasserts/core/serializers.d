module fluentasserts.core.serializers;

import std.array;
import std.string;
import std.algorithm;

version(unittest) import fluent.asserts;


///
string[] parseList(string value) @safe nothrow {
  if(value.length <= 2) {
    return [];
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