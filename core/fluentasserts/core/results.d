module fluentasserts.core.results;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;

interface ResultPrinter {
  void primary(string);
  void info(string);
  void danger(string);
  void success(string);

  void dangerReverse(string);
  void successReverse(string);
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
    const string message;
  }

  this(string message)
  {
    this.message = message;
  }

  override string toString()
  {
    return message;
  }

  void print(ResultPrinter printer)
  {
    printer.primary(toString ~ "\n");
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

class SourceResult : IResult
{
  private const
  {
    string file;
    size_t line;

    string code;
    string value;
  }

  this(string fileName = __FILE__, size_t line = __LINE__, size_t range = 6)
  {
    this.file = fileName;
    this.line = line;

    if (!fileName.exists)
    {
      return;
    }

    auto file = File(fileName);

    auto rawCode = file.byLine().map!(a => a.to!string).take(line + range).array;

    code = rawCode.enumerate(1).dropExactly(range < line ? line - range : 0)
      .map!(a => (a[0] == line ? ">" : " ") ~ rightJustifier(a[0].to!string, 5)
          .to!string ~ ": " ~ a[1]).take(range * 2 - 1).join("\n").to!string;

    value = evaluatedValue(rawCode);
  }

  string getValue()
  {
    return value;
  }

  override string toString()
  {
    auto separator = leftJustify("", 20, '-') ~ "\n";

    return separator ~ file ~ ":" ~ line.to!string ~ "\n" ~ separator ~ code ~ "\n" ~ separator;
  }

  void print(ResultPrinter printer) {
    printer.info(file ~ ":" ~ line.to!string ~ "\n");

    foreach (line; this.code.split("\n"))
    {
      auto index = line.indexOf(':') + 1;

      if (line[0] != '>')
      {
        printer.info(line[0 .. index]);
        printer.primary(line[index .. $] ~ " ");
      }
      else
      {
        printer.danger(line);
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

  private string getResult(const Diff d) pure {
    final switch(d.operation) {
        case Operation.DELETE:
          return "[-" ~ d.text ~ "]";
        case Operation.INSERT:
          return "[+" ~ d.text ~ "]";
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
    printer.primary("Diff:");

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

    printer.primary("\n");
  }
}

class ExpectedActualResult : IResult
{
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

  override string toString()
  {
    string result = "";

    if (expected != "")
    {
      result ~= "Expected:" ~ printValue(expected);
    }

    if (actual != "")
    {
      if (result.length > 0)
      {
        result ~= "\n";
      }

      result ~= "  Actual:" ~ printValue(actual);
    }

    return result;
  }

  void print(ResultPrinter printer)
  {
    printer.primary(toString ~ "\n");
  }

  private
  {
    pure string printValue(string value)
    {
      return value.split("\n").join("\\n\n        :");
    }
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
  result.toString.should.equal(`Expected:data
  Actual:data`);
}

@("ExpectedActual result should show one line of the expected and actual data")
unittest
{
  auto result = new ExpectedActualResult("data\ndata", "data\ndata");
  result.toString.should.equal(
      "Expected:data\\n\n" ~ "        :data\n" ~ "  Actual:data\\n\n" ~ "        :data");
}
