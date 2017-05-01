module fluentasserts.core.results;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.regex;
import std.exception;
import core.demangle;

interface IResult {
  string toString();
  void print();
}

class MessageResult: IResult {
  private {
    const string message;
  }

  this(string message) {
    this.message = message;
  }


  override string toString() {
    return message;
  }

  void print() {
    writeln(toString, "\n");
  }
}

version(unittest) {
  import fluentasserts.core.base;
}

@("Message result should return the message")
unittest {
  auto result = new MessageResult("Message");
  result.toString.should.equal("Message");
}

class SourceResult: IResult {
  private const {
    string file;
    size_t line;

    string code;
    string value;
  }

  this(string fileName = __FILE__, size_t line = __LINE__, size_t range = 6) {
    this.file = fileName;
    this.line = line;

    if(!fileName.exists) {
      return;
    }

    auto file = File(fileName);

    auto rawCode = file.byLine().map!(a => a.to!string).take(line + range).array;

    code = rawCode.enumerate(1).dropExactly(range < line ? line - range : 0)
        .map!(a => (a[0] == line ? ">" : " ") ~ rightJustifier(a[0].to!string, 5).to!string ~ ": " ~ a[1])
        .take(range * 2 - 1).join("\n")
        .to!string;

    value = evaluatedValue(rawCode);
  }

  string getValue() {
    return value;
  }

  override string toString() {
    auto separator = leftJustify("", 20, '-') ~ "\n";

    return separator ~
           file ~ ":" ~ line.to!string ~ "\n" ~
           separator ~
           code ~ "\n" ~
           separator;
  }

  void print() {
    version(Have_consoled) {
      import consoled;

      foreground = Color.blue;
      writeln(file, ":", line);
      resetColors();
      writeln;

      foreach(line; this.code.split("\n")) {
        auto index = line.indexOf(':') + 1;

        if(line[0] != '>') {
          foreground = Color.blue;
          write(line[0..index]);

          resetColors();
          writeln(line[index..$] ~ " ");
        } else {
          foreground = Color.white;
          background = Color.red;
          write(line ~ " ");
          resetColors();
          write(" \n");
        }
      }
    } else {
      writeln(toString);
    }

    writeln;
  }

  private {
    auto evaluatedValue(string[] rawCode) {
      string result = "";

      auto value = rawCode.take(line)
        .filter!(a => a.indexOf("//") == -1)
        .map!(a => a.strip)
        .join("");

      auto end = valueEndIndex(value);

      if(end > 0) {
        auto begin = valueBeginIndex(value[0..end]);

        if(begin > 0) {
          result = value[begin..end];
        }
      }

      return result;
    }

    auto valueBeginIndex(string value) {

      auto tokens = ["{", ";", "*/", "+/"];

      auto positions =
        tokens
          .map!(a => [value.lastIndexOf(a), a.length])
          .filter!(a => a[0] != -1)
          .map!(a => a[0] + a[1])
            .array;

      if(positions.length == 0) {
        return -1;
      }

      return positions.sort!("a > b").front;
    }

    auto valueEndIndex(string value) {
      return value.lastIndexOf(".should");
    }
  }
}

@("TestException should read the code from the file")
unittest
{
  auto result = new SourceResult("test/example.txt", 10);
  auto msg = result.toString;

  msg.should.contain("test/example.txt:10");
  msg.should.contain(">   10: line 10");
}

@("TestException should ignore missing files")
unittest
{
  auto result = new SourceResult("test/missing.txt", 10);
  auto msg = result.toString;

  msg.should.equal(`--------------------
test/missing.txt:10
--------------------

--------------------
`);
}

@("Source reporter should find the tested value on scope start")
unittest
{
  auto result = new SourceResult("test/values.d", 4);
  result.getValue.should.equal("[1, 2, 3]");
}

@("Source reporter should find the tested value after a statment")
unittest
{
  auto result = new SourceResult("test/values.d", 12);
  result.getValue.should.equal("[1, 2, 3]");
}

@("Source reporter should find the tested value after a */ comment")
unittest
{
  auto result = new SourceResult("test/values.d", 20);
  result.getValue.should.equal("[1, 2, 3]");
}

@("Source reporter should find the tested value after a +/ comment")
unittest
{
  auto result = new SourceResult("test/values.d", 28);
  result.getValue.should.equal("[1, 2, 3]");
}

@("Source reporter should find the tested value after a // comment")
unittest
{
  auto result = new SourceResult("test/values.d", 36);
  result.getValue.should.equal("[1, 2, 3]");
}

class ExpectedActualResult : IResult {

  private {
    string expected;
    string actual;
  }

  this(string expected, string actual) {
    this.expected = expected;
    this.actual = actual;
  }

  override string toString() {
    string result = "";

    if(expected != "") {
      result ~= "Expected:" ~ printValue(expected);
    }

    if(actual != "") {
      if(result.length > 0) {
        result ~= "\n";
      }

      result ~= "  Actual:" ~ printValue(actual);
    }

    return result;
  }

  void print() {
    writeln(toString, "\n");
  }

  private {
    pure string printValue(string value) {
      return value.split("\n").join("\\n\n        :");
    }
  }
}

@("ExpectedActual result should be empty when no data is provided")
unittest {
  auto result = new ExpectedActualResult("", "");
  result.toString.should.equal("");
}

@("ExpectedActual result should be empty when null data is provided")
unittest {
  auto result = new ExpectedActualResult(null, null);
  result.toString.should.equal("");
}

@("ExpectedActual result should show one line of the expected and actual data")
unittest {
  auto result = new ExpectedActualResult("data", "data");
  result.toString.should.equal(`Expected:data
  Actual:data`);
}

@("ExpectedActual result should show one line of the expected and actual data")
unittest {
  auto result = new ExpectedActualResult("data\ndata", "data\ndata");
  result.toString.should.equal("Expected:data\\n\n" ~
                               "        :data\n" ~
                               "  Actual:data\\n\n" ~
                               "        :data");
}

class StackResult: IResult {
  Frame[] frames;

  this(Throwable.TraceInfo t) {


    foreach(line; t) {

      auto frame = line.to!string.toFrame;
      frame.name = demangle(frame.name).to!string;
      frames ~= frame;
    }
  }

  private {
    auto getFrames() {
      return frames
        .until!(a => a.name.indexOf("generated") != -1);
    }
  }

  override {
    string toString() {
      string result = "Stack trace:\n-------------------\n...\n";

      foreach(frame; getFrames) {
        result ~= leftJustifier(frame.index.to!string, 4).to!string ~ frame.address ~ " " ~ frame.name ~ "\n";
      }

      return result ~ "...";
    }

    void print() {
      version(Have_consoled) {
        import consoled;

        writeln("Stack trace:\n-------------------\n...\n");

        foreach(frame; getFrames) {
          foreground = Color.blue;
          write(leftJustifier(frame.index.to!string, 4));
          write(frame.address ~ " ");
          resetColors();
          writeln(frame.name);
        }
        writeln("...");
      } else {
        writeln(toString);
      }
    }
  }
}

@("The stack result should display the stack in a readable form")
unittest
{
  Throwable exception;

  try {
    assert(false, "random message");
  } catch(Throwable t) {
    exception = t;
  }

  auto result = new StackResult(exception.info).toString;

  result.should.startWith("Stack trace:\n-------------------\n...");
  result.should.endWith("\n...");
}

struct Frame {
  int index = -1;
  string moduleName;
  string address;
  string name;
  string offset;
  string file;
  int line = -1;
}


immutable static {
  string index       = `(?P<index>[0-9]+)`;
  string moduleName  = `(?P<module>\S+)`;
  string address     = `(?P<address>0x[0-9a-fA-F]+)`;
  string name        = `(?P<name>.+)`;
  string offset      = `(?P<offset>(0x[0-9A-Za-z]+)|([0-9]+))`;
  string file        = `(?P<file>.+)`;
  string linePattern = `(?P<line>[0-9]+)`;
}

Frame toDarwinFrame(string line) {
  Frame frame;

  auto darwinPattern = index ~ `(\s+)` ~
                       moduleName ~ `(\s+)` ~
                       address ~ `(\s+)` ~
                       name ~ `\s\+\s` ~
                       offset;

  auto matched = matchFirst(line, darwinPattern);

  frame.index = matched["index"].to!int;
  frame.moduleName = matched["module"];
  frame.address = matched["address"];
  frame.name = matched["name"];
  frame.offset = matched["offset"];

  return frame;
}

Frame toWindows1Frame(string line) {
  Frame frame;

  auto matched = matchFirst(line, address ~ `(\s+)in(\s+)` ~ name ~ `(\s+)at(\s+)`~ file ~ `\(` ~ linePattern ~ `\)`);// ~ );

  frame.address = matched["address"];
  frame.name = matched["name"];
  frame.file = matched["file"];
  frame.line = matched["line"].to!int;


  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");
  enforce(frame.file != "", "file not found");

  return frame;
}

Frame toWindows2Frame(string line) {
  Frame frame;

  auto matched = matchFirst(line, address ~ `(\s+)in(\s+)` ~ name);
  frame.address = matched["address"];
  frame.name = matched["name"];

  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");

  return frame;
}


Frame toGLibCFrame(string line) {
  Frame frame;

  auto matched = matchFirst(line, moduleName ~ `\(` ~ name ~ `\)\s+\[` ~ address ~ `\]`);

  frame.address = matched["address"];
  frame.name = matched["name"];
  frame.moduleName = matched["module"];

  auto plusSign = frame.name.indexOf("+");

  if(plusSign != -1) {
    frame.offset = frame.name[plusSign+1..$];
    frame.name = frame.name[0..plusSign];
  }

  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");
  enforce(frame.moduleName != "", "module not found");

  return frame;
}

Frame toNetBsdFrame(string line) {
  Frame frame;

  auto matched = matchFirst(line, address ~ `\s+<` ~ name ~ `\+` ~ offset ~ `>\s+at\s+` ~ moduleName);

  frame.address = matched["address"];
  frame.name = matched["name"];
  frame.moduleName = matched["module"];
  frame.offset = matched["offset"];

  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");
  enforce(frame.moduleName != "", "module not found");
  enforce(frame.offset != "", "offset not found");

  return frame;
}

Frame toFrame(string line) {
  Frame frame;

  try {
    return line.toDarwinFrame;
  } catch (Exception e) {}

  try {
    return line.toWindows1Frame;
  } catch (Exception e) {}

  try {
    return line.toWindows2Frame;
  } catch (Exception e) {}

  try {
    return line.toGLibCFrame;
  } catch (Exception e) {}

  try {
    return line.toNetBsdFrame;
  } catch (Exception e) {}

  return frame;
}

@("Get frame info from Darwin platform format")
unittest {
  auto line = "1  ???fluent-asserts    0x00abcdef000000 D6module4funcAFZv + 0";

  auto frame = line.toFrame;
  frame.index.should.equal(1);
  frame.moduleName.should.equal("???fluent-asserts");
  frame.address.should.equal("0x00abcdef000000");
  frame.name.should.equal("D6module4funcAFZv");
  frame.offset.should.equal("0");
}

@("Get frame info from windows platform format without path")
unittest {
  auto line = "0x779CAB5A in RtlInitializeExceptionChain";

  auto frame = line.toFrame;
  frame.index.should.equal(-1);
  frame.moduleName.should.equal("");
  frame.address.should.equal("0x779CAB5A");
  frame.name.should.equal("RtlInitializeExceptionChain");
  frame.offset.should.equal("");
}

@("Get frame info from windows platform format with path")
unittest {
  auto line = `0x00402669 in void app.__unittestL82_8() at D:\tidynumbers\source\app.d(84)`;

  auto frame = line.toFrame;
  frame.index.should.equal(-1);
  frame.moduleName.should.equal("");
  frame.address.should.equal("0x00402669");
  frame.name.should.equal("void app.__unittestL82_8()");
  frame.file.should.equal(`D:\tidynumbers\source\app.d`);
  frame.line.should.equal(84);
  frame.offset.should.equal("");
}

@("Get frame info from CRuntime_Glibc format without offset")
unittest {
  auto line = `module(_D6module4funcAFZv) [0x00000000]`;

  auto frame = line.toFrame;

  frame.moduleName.should.equal("module");
  frame.name.should.equal("_D6module4funcAFZv");
  frame.address.should.equal("0x00000000");
  frame.index.should.equal(-1);
  frame.offset.should.equal("");
}

@("Get frame info from CRuntime_Glibc format with offset")
unittest {
  auto line = `module(_D6module4funcAFZv+0x78) [0x00000000]`;

  auto frame = line.toFrame;

  frame.moduleName.should.equal("module");
  frame.name.should.equal("_D6module4funcAFZv");
  frame.address.should.equal("0x00000000");
  frame.index.should.equal(-1);
  frame.offset.should.equal("0x78");
}

@("Get frame info from NetBSD format")
unittest {
  auto line = `0x00000000 <_D6module4funcAFZv+0x78> at module`;

  auto frame = line.toFrame;

  frame.moduleName.should.equal("module");
  frame.name.should.equal("_D6module4funcAFZv");
  frame.address.should.equal("0x00000000");
  frame.index.should.equal(-1);
  frame.offset.should.equal("0x78");
}
