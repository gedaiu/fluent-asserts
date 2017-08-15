module fluentasserts.core.results;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;

struct ResultGlyphs {
  static {
    string tab;
    string carriageReturn;
    string newline;
    string space;

    string sourceIndicator;
    string sourceLineSeparator;

    string diffBegin;
    string diffEnd;
    string diffInsert;
    string diffDelete;
  }

  static resetDefaults() {
    version(windows) {
      ResultGlyphs.tab = `\t`;
      ResultGlyphs.carriageReturn = `\r`;
      ResultGlyphs.newline = `\n`;
      ResultGlyphs.space = ` `;
    } else {
      ResultGlyphs.tab = `¤`;
      ResultGlyphs.carriageReturn = `←`;
      ResultGlyphs.newline = `↲`;
      ResultGlyphs.space = `᛫`;
    }

    ResultGlyphs.sourceIndicator = ">";
    ResultGlyphs.sourceLineSeparator = ":";

    ResultGlyphs.diffBegin = "[";
    ResultGlyphs.diffEnd = "]";
    ResultGlyphs.diffInsert = "+";
    ResultGlyphs.diffDelete = "-";
  }
}

static this() {
  ResultGlyphs.resetDefaults;
}

interface ResultPrinter {
  void primary(string);
  void info(string);
  void danger(string);
  void success(string);

  void dangerReverse(string);
  void successReverse(string);
}

version(unittest) {
  class MockPrinter : ResultPrinter {
    string buffer;

    void primary(string val) {
      buffer ~= "[primary:" ~ val ~ "]";
    }

    void info(string val) {
      buffer ~= "[info:" ~ val ~ "]";
    }

    void danger(string val) {
      buffer ~= "[danger:" ~ val ~ "]";
    }

    void success(string val) {
      buffer ~= "[success:" ~ val ~ "]";
    }

    void dangerReverse(string val) {
      buffer ~= "[dangerReverse:" ~ val ~ "]";
    }

    void successReverse(string val) {
      buffer ~= "[successReverse:" ~ val ~ "]";
    }
  }
}

class DefaultResultPrinter : ResultPrinter {
  void primary(string text) {
    write(text);
  }

  void info(string text) {
    write(text);
  }

  void danger(string text) {
    write(text);
  }

  void success(string text) {
    write(text);
  }

  void dangerReverse(string text) {
    write(text);
  }

  void successReverse(string text) {
    write(text);
  }
}

interface IResult
{
  string toString();
  void print(ResultPrinter);
}

class MessageResult : IResult
{
  private
  {
    struct Message {
      bool isValue;
      string text;
    }

    Message[] messages;
  }

  this(string message) nothrow
  {
    add(false, message);
  }

  override string toString()
  {
    return messages.map!(a => a.text).join("").to!string;
  }

  void add(bool isValue, string message) nothrow {
    this.messages ~= Message(isValue, message
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\t", ResultGlyphs.tab));
  }

  void addValue(string text) {
    add(true, text);
  }

  void addText(string text) {
    this.messages ~= Message(false, text);
  }

  void prependText(string text) {
    this.messages = Message(false, text) ~ this.messages;
  }

  void print(ResultPrinter printer)
  {
    foreach(message; messages) {
      if(message.isValue) {
        printer.info(message.text);
      } else {
        printer.primary(message.text);
      }
    }

    printer.primary("\n\n");
  }
}

version (unittest)
{
  import fluentasserts.core.base;
}

@("Message result should return the message")
unittest
{
  auto result = new MessageResult("Message");
  result.toString.should.equal("Message");
}

@("Message result should replace the spacial chars")
unittest
{
  auto result = new MessageResult("\t \r\n");
  result.toString.should.equal(`¤ ←↲`);
}

@("Message result should replace the spacial chars with the custom glyphs")
unittest
{
  scope(exit) {
    ResultGlyphs.resetDefaults;
  }

  ResultGlyphs.tab = `\t`;
  ResultGlyphs.carriageReturn  = `\r`;
  ResultGlyphs.newline = `\n`;

  auto result = new MessageResult("\t \r\n");
  result.toString.should.equal(`\t \r\n`);
}

@("Message result should reurn values as string")
unittest
{
  auto result = new MessageResult("text");
  result.addValue("value");
  result.addText("text");

  result.toString.should.equal(`textvaluetext`);
}

@("Message result should print a string as primary")
unittest
{
  auto result = new MessageResult("\t \r\n");
  auto printer = new MockPrinter;
  result.print(printer);

  printer.buffer.should.equal(`[primary:¤ ←↲]` ~ "[primary:\n\n]");
}

@("Message result should print values as info")
unittest
{
  auto result = new MessageResult("text");
  result.addValue("value");
  result.addText("text");

  auto printer = new MockPrinter;
  result.print(printer);

  printer.buffer.should.equal(`[primary:text][info:value][primary:text]` ~ "[primary:\n\n]");
}

class SourceResult : IResult
{
  private const
  {
    string file;
    size_t line;

    string code;
    string value;
  }

  this(string fileName = __FILE__, size_t line = __LINE__, size_t range = 6) nothrow
  {
    this.file = fileName;
    this.line = line;

    if (!fileName.exists)
    {
      return;
    }

    try {
      auto file = File(fileName);

      auto rawCode = file.byLine().map!(a => a.to!string).take(line + range).array;

      code = rawCode.enumerate(1).dropExactly(range < line ? line - range : 0)
        .map!(a => (a[0] == line ? ResultGlyphs.sourceIndicator : " ") ~ rightJustifier(a[0].to!string, 5)
            .to!string ~ ResultGlyphs.sourceLineSeparator ~ " " ~ a[1]).take(range * 2 - 1).join("\n").to!string;

      value = evaluatedValue(rawCode);
    } catch(Throwable t) {}
  }

  string getValue()
  {
    return value;
  }

  override string toString() nothrow
  {
    auto separator = leftJustify("", 20, '-');

    return separator ~ "\n" ~ file ~ ":" ~ line.to!string ~ "\n" ~ separator ~ "\n" ~ code ~ "\n" ~ separator;
  }

  void print(ResultPrinter printer) {
    printer.info(file ~ ":" ~ line.to!string);
    printer.primary("\n");

    foreach (line; this.code.split("\n"))
    {
      auto index = line.indexOf(ResultGlyphs.sourceLineSeparator) + 1;

      if (line.indexOf(ResultGlyphs.sourceIndicator) != 0)
      {
        printer.info(line[0 .. index]);
        printer.primary(line[index .. $] ~ " ");
      }
      else
      {
        printer.dangerReverse(line);
      }

      printer.primary("\n");
    }

    printer.primary("\n");
  }

  private
  {
    auto evaluatedValue(string[] rawCode)
    {
      string result = "";

      auto value = rawCode.take(line).filter!(a => a.indexOf("//") == -1)
        .map!(a => a.strip).join("");

      auto end = valueEndIndex(value);

      if (end > 0)
      {
        auto begin = valueBeginIndex(value[0 .. end]);

        if (begin > 0)
        {
          result = value[begin .. end];
        }
      }

      return result;
    }

    auto valueBeginIndex(string value)
    {
      auto tokens = ["{", ";", "*/", "+/"];

      auto positions = tokens.map!(a => [value.lastIndexOf(a), a.length]).filter!(a => a[0] != -1)
        .map!(a => a[0] + a[1]).array;

      if (positions.length == 0)
      {
        return -1;
      }

      return positions.sort!("a > b").front;
    }

    auto valueEndIndex(string value)
    {
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

@("TestException should use a custom line indicator")
unittest
{
  scope(exit) {
    ResultGlyphs.resetDefaults;
  }

  ResultGlyphs.sourceIndicator = "*";
  ResultGlyphs.sourceLineSeparator = "|";

  auto result = new SourceResult("test/example.txt", 10);
  auto msg = result.toString;

  msg.should.contain("test/example.txt:10");
  msg.should.contain("*   10| line 10");
}

@("TestException should ignore missing files")
unittest
{
  auto result = new SourceResult("test/missing.txt", 10);
  auto msg = result.toString;

  msg.should.equal(`--------------------
test/missing.txt:10
--------------------

--------------------`);
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

/// Source reporter should print the source code
unittest
{
  auto result = new SourceResult("test/values.d", 36);
  auto printer = new MockPrinter();

  result.print(printer);

  auto lines = printer.buffer.split("[primary:\n]");

  lines[0].should.equal(`[info:test/values.d:36]`);
  lines[1].should.equal(`[info:    31:][primary: unittest { ]`);
  lines[6].should.equal(`[dangerReverse:>   36:     .contain(4);]`);
}

class DiffResult : IResult {
  import ddmp.diff;

  protected
  {
    string expected;
    string actual;
  }

  this(string expected, string actual)
  {
    this.expected = expected;
    this.actual = actual;
  }

  private string getResult(const Diff d) {
    final switch(d.operation) {
        case Operation.DELETE:
          return ResultGlyphs.diffBegin ~ ResultGlyphs.diffDelete ~ d.text ~ ResultGlyphs.diffEnd;
        case Operation.INSERT:
          return ResultGlyphs.diffBegin ~ ResultGlyphs.diffInsert ~ d.text ~ ResultGlyphs.diffEnd;
        case Operation.EQUAL:
          return d.text;
    }
  }

  override string toString()
  {
    return "Diff:\n" ~ diff_main(expected, actual).map!(a => getResult(a)).join("");
  }

  void print(ResultPrinter printer) {
    auto result = diff_main(expected, actual);
    printer.info("Diff:");

    foreach(diff; result) {
      if(diff.operation == Operation.EQUAL) {
        printer.primary(diff.text);
      }

      if(diff.operation == Operation.INSERT) {
        printer.successReverse(diff.text);
      }

      if(diff.operation == Operation.DELETE) {
        printer.dangerReverse(diff.text);
      }

    }

    printer.primary("\n\n");
  }
}

/// DiffResult should find the differences
unittest {
  auto diff = new DiffResult("abc", "asc");
  diff.toString.should.equal("Diff:\na[-b][+s]c");
}


/// DiffResult should use the custom glyphs
unittest {
  scope(exit) {
    ResultGlyphs.resetDefaults;
  }

  ResultGlyphs.diffBegin = "{";
  ResultGlyphs.diffEnd = "}";
  ResultGlyphs.diffInsert = "!";
  ResultGlyphs.diffDelete = "?";

  auto diff = new DiffResult("abc", "asc");
  diff.toString.should.equal("Diff:\na{?b}{!s}c");
}

class KeyResult(string key) : IResult {

  private immutable {
    string value;
    size_t indent;
  }

  this(string value, size_t indent = 10) {
    this.value = value;
    this.indent = indent;
  }

  override string toString()
  {
    if(value == "") {
      return "";
    }

    return rightJustify(key ~ ":", indent, ' ') ~ printableValue;
  }

  void print(ResultPrinter printer)
  {
    if(value == "") {
      return;
    }

    printer.info(rightJustify(key ~ ":", indent, ' '));
    auto lines = value.split("\n");

    auto spaces = rightJustify(":", indent, ' ');

    int index;
    foreach(line; lines) {
      if(index > 0) {
        printer.info(ResultGlyphs.newline);
        printer.primary("\n");
        printer.info(spaces);
      }

      printLine(line, printer);

      index++;
    }

    printer.primary("\n");
  }

  private
  {
    struct Message {
      bool isSpecial;
      string text;
    }

    void printLine(string line, ResultPrinter printer) {
      Message[] messages;

      foreach(ch; line) {
        auto special = isSpecial(ch);

        if(messages.length == 0 || messages[messages.length - 1].isSpecial != special) {
          messages ~= Message(special, "");
        }

        messages[messages.length - 1].text ~= toVisible(ch);
      }

      foreach(message; messages) {
        if(message.isSpecial) {
          printer.info(message.text);
        } else {
          printer.primary(message.text);
        }
      }
    }

    bool isSpecial(T)(T ch) {
      if(ch == ' ' || ch == '\r' || ch == '\t') {
        return true;
      }

      return false;
    }

    string toVisible(T)(T ch) {
      if(ch == ' ') {
        return ResultGlyphs.space;
      }

      if(ch == '\r') {
        return ResultGlyphs.carriageReturn;
      }

      if(ch == '\t') {
        return ResultGlyphs.tab;
      }

      return ch.to!string;
    }

    pure string printableValue()
    {
      return value.split("\n").join("\\n\n" ~ rightJustify(":", indent, ' '));
    }
  }
}

/// KeyResult should display special characters with different contexts
unittest {
  auto result = new KeyResult!"key"("row1\n \trow2");
  auto printer = new MockPrinter();

  result.print(printer);

  printer.buffer.should.equal(`[info:      key:][primary:row1][info:↲][primary:` ~ "\n" ~ `][info:         :][info:᛫¤][primary:row2][primary:` ~ "\n" ~ `]`);
}

/// KeyResult should display custom glyphs with different contexts
unittest {
  scope(exit) {
    ResultGlyphs.resetDefaults;
  }

  ResultGlyphs.newline = `\n`;
  ResultGlyphs.tab = `\t`;
  ResultGlyphs.space = ` `;

  auto result = new KeyResult!"key"("row1\n \trow2");
  auto printer = new MockPrinter();

  result.print(printer);

  printer.buffer.should.equal(`[info:      key:][primary:row1][info:\n][primary:` ~ "\n" ~ `][info:         :][info: \t][primary:row2][primary:` ~ "\n" ~ `]`);
}

class ExpectedActualResult : IResult
{
  protected
  {
    KeyResult!"Expected" expected;
    KeyResult!"Actual" actual;
  }

  this(string expected, string actual)
  {
    this.expected = new KeyResult!"Expected"(expected);
    this.actual = new KeyResult!"Actual"(actual);
  }

  override string toString()
  {
    auto line1 = expected.toString;
    auto line2 = actual.toString;

    return line1 != "" ? line1 ~ "\n" ~ line2 : line2;
  }

  void print(ResultPrinter printer)
  {
    expected.print(printer);
    actual.print(printer);
    printer.primary("\n");
  }
}

@("ExpectedActual result should be empty when no data is provided")
unittest
{
  auto result = new ExpectedActualResult("", "");
  result.toString.should.equal("");
}

@("ExpectedActual result should be empty when null data is provided")
unittest
{
  auto result = new ExpectedActualResult(null, null);
  result.toString.should.equal("");
}

@("ExpectedActual result should show one line of the expected and actual data")
unittest
{
  auto result = new ExpectedActualResult("data", "data");
  result.toString.should.equal(` Expected:data
   Actual:data`);
}

@("ExpectedActual result should show one line of the expected and actual data")
unittest
{
  auto result = new ExpectedActualResult("data\ndata", "data\ndata");
  result.toString.should.equal(
` Expected:data\n
         :data
   Actual:data\n
         :data`);
}

class ExtraMissingResult : IResult
{
  protected
  {
    KeyResult!"Extra" extra;
    KeyResult!"Missing" missing;
  }

  this(string extra, string missing)
  {
    this.extra = new KeyResult!"Extra"(extra);
    this.missing = new KeyResult!"Missing"(missing);
  }

  override string toString()
  {
    auto line1 = extra.toString;
    auto line2 = missing.toString;

    return line1 != "" ? line1 ~ "\n" ~ line2 : line2;
  }

  void print(ResultPrinter printer)
  {
    extra.print(printer);
    missing.print(printer);
    printer.primary("\n");
  }
}