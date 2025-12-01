module fluentasserts.core.results;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.exception;
import std.typecons;

import dparse.lexer;
import dparse.parser;

public import fluentasserts.core.message;

@safe:

///
interface ResultPrinter {
  nothrow:
    void print(Message);
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

    void print(Message message) {
      import std.conv : to;
      try {
        buffer ~= "[" ~ message.type.to!string ~ ":" ~ message.text ~ "]";
      } catch(Exception) {
        buffer ~= "ERROR";
      }
    }

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

struct WhiteIntervals {
  size_t left;
  size_t right;
}

WhiteIntervals getWhiteIntervals(string text) {
  auto stripText = text.strip;

  if(stripText == "") {
    return WhiteIntervals(0, 0);
  }

  return WhiteIntervals(text.indexOf(stripText[0]), text.lastIndexOf(stripText[stripText.length - 1]));
}

void writeNoThrow(T)(T text) nothrow {
  try {
    write(text);
  } catch(Exception e) {
    assert(true, "Can't write to stdout!");
  }
}

/// This is the most simple implementation of a ResultPrinter.
/// All the plain data is printed to stdout
class DefaultResultPrinter : ResultPrinter {
  nothrow:

  void print(Message message) {

  }

  void primary(string text) {
    writeNoThrow(text);
  }

  void info(string text) {
    writeNoThrow(text);
  }

  void danger(string text) {
    writeNoThrow(text);
  }

  void success(string text) {
    writeNoThrow(text);
  }

  void dangerReverse(string text) {
    writeNoThrow(text);
  }

  void successReverse(string text) {
    writeNoThrow(text);
  }
}

interface IResult {
  string toString();
  void print(ResultPrinter);
}

class EvaluationResultInstance : IResult {

  EvaluationResult result;

  this(EvaluationResult result) nothrow {
    this.result = result;
  }

  override string toString() nothrow {
    return result.toString;
  }

  void print(ResultPrinter printer) nothrow {
    result.print(printer);
  }
}

class AssertResultInstance : IResult {

  AssertResult result;

  this(AssertResult result) nothrow {
    this.result = result;
  }

  override string toString() nothrow {
    string output;

    if(result.expected.length > 0) {
      output ~= "\n Expected:";
      if(result.negated) {
        output ~= "not ";
      }
      output ~= result.formatValue(result.expected);
    }

    if(result.actual.length > 0) {
      output ~= "\n   Actual:" ~ result.formatValue(result.actual);
    }

    if(result.diff.length > 0) {
      output ~= "\n\nDiff:\n";
      foreach(segment; result.diff) {
        output ~= segment.toString();
      }
    }

    if(result.extra.length > 0) {
      output ~= "\n    Extra:";
      foreach(i, item; result.extra) {
        if(i > 0) output ~= ",";
        output ~= result.formatValue(item);
      }
    }

    if(result.missing.length > 0) {
      output ~= "\n  Missing:";
      foreach(i, item; result.missing) {
        if(i > 0) output ~= ",";
        output ~= result.formatValue(item);
      }
    }

    return output;
  }

  void print(ResultPrinter printer) nothrow {
    if(result.expected.length > 0) {
      printer.info("\n Expected:");
      if(result.negated) {
        printer.info("not ");
      }
      printer.primary(result.formatValue(result.expected));
    }

    if(result.actual.length > 0) {
      printer.info("\n   Actual:");
      printer.danger(result.formatValue(result.actual));
    }

    if(result.diff.length > 0) {
      printer.info("\n\nDiff:\n");
      foreach(segment; result.diff) {
        final switch(segment.operation) {
          case DiffSegment.Operation.equal:
            printer.info(segment.toString());
            break;
          case DiffSegment.Operation.insert:
            printer.successReverse(segment.toString());
            break;
          case DiffSegment.Operation.delete_:
            printer.dangerReverse(segment.toString());
            break;
        }
      }
    }

    if(result.extra.length > 0) {
      printer.info("\n    Extra:");
      foreach(i, item; result.extra) {
        if(i > 0) printer.info(",");
        printer.danger(result.formatValue(item));
      }
    }

    if(result.missing.length > 0) {
      printer.info("\n  Missing:");
      foreach(i, item; result.missing) {
        if(i > 0) printer.info(",");
        printer.success(result.formatValue(item));
      }
    }
  }
}

/// Message result data stored as a struct for efficiency
struct MessageResultData {
  immutable(Message)[] messages;

  string toString() nothrow {
    string result;
    foreach(message; messages) {
      result ~= message.text;
    }
    return result;
  }

  void startWith(string message) @safe nothrow {
    immutable(Message)[] newMessages;

    newMessages ~= Message(Message.Type.info, message);
    newMessages ~= this.messages;

    this.messages = newMessages;
  }

  void add(bool isValue, string message) nothrow {
    this.messages ~= Message(isValue ? Message.Type.value : Message.Type.info, message
      .replace("\r", ResultGlyphs.carriageReturn)
      .replace("\n", ResultGlyphs.newline)
      .replace("\0", ResultGlyphs.nullChar)
      .replace("\t", ResultGlyphs.tab));
  }

  void add(Message message) nothrow {
    this.messages ~= message;
  }

  void addValue(string text) @safe nothrow {
    add(true, text);
  }

  void addText(string text) @safe nothrow {
    if(text == "throwAnyException") {
      text = "throw any exception";
    }

    this.messages ~= Message(Message.Type.info, text);
  }

  void prependText(string text) @safe nothrow  {
    this.messages = Message(Message.Type.info, text) ~ this.messages;
  }

  void prependValue(string text) @safe nothrow {
    this.messages = Message(Message.Type.value, text) ~ this.messages;
  }

  void print(ResultPrinter printer) nothrow {
    foreach(message; messages) {
      if(message.type == Message.Type.value) {
        printer.info(message.text);
      } else {
        printer.primary(message.text);
      }
    }
  }
}

/// Wrapper class for MessageResultData to implement IResult interface
class MessageResult : IResult {
  package MessageResultData data;

  this(string message) nothrow {
    data.add(false, message);
  }

  this() nothrow { }

  this(MessageResultData sourceData) nothrow {
    data = sourceData;
  }

  override string toString() {
    return data.toString();
  }

  void startWith(string message) @safe nothrow {
    data.startWith(message);
  }

  void add(bool isValue, string message) nothrow {
    data.add(isValue, message);
  }

  void add(Message message) nothrow {
    data.add(message);
  }

  void addValue(string text) @safe nothrow {
    data.addValue(text);
  }

  void addText(string text) @safe nothrow {
    data.addText(text);
  }

  void prependText(string text) @safe nothrow  {
    data.prependText(text);
  }

  void prependValue(string text) @safe nothrow {
    data.prependValue(text);
  }

  void print(ResultPrinter printer) {
    data.print(printer);
  }
}

version (unittest) {
  import fluentasserts.core.base;
}

@("Message result should return the message")
unittest
{
  auto result = new MessageResult("Message");
  result.toString.should.equal("Message");
}

@("Message result should replace the special chars")
unittest
{
  auto result = new MessageResult("\t \r\n");
  result.toString.should.equal(`¤ ←↲`);
}

@("Message result should replace the special chars with the custom glyphs")
unittest
{
  scope(exit) {
    ResultGlyphs.resetDefaults;
  }

  ResultGlyphs.tab = `\t`;
  ResultGlyphs.carriageReturn = `\r`;
  ResultGlyphs.newline = `\n`;

  auto result = new MessageResult("\t \r\n");
  result.toString.should.equal(`\t \r\n`);
}

@("Message result should return values as string")
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

  printer.buffer.should.equal(`[primary:¤ ←↲]`);
}

@("Message result should print values as info")
unittest
{
  auto result = new MessageResult("text");
  result.addValue("value");
  result.addText("text");

  auto printer = new MockPrinter;
  result.print(printer);

  printer.buffer.should.equal(`[primary:text][info:value][primary:text]`);
}

class DiffResult : IResult {
  import ddmp.diff;

  protected {
    string expected;
    string actual;
  }

  this(string expected, string actual)
  {
    this.expected = expected.replace("\0", ResultGlyphs.nullChar);
    this.actual = actual.replace("\0", ResultGlyphs.nullChar);
  }

  private string getResult(const Diff d) {
    final switch(d.operation) {
        case Operation.DELETE:
          return ResultGlyphs.diffBegin ~ ResultGlyphs.diffDelete ~ d.text.to!string ~ ResultGlyphs.diffEnd;
        case Operation.INSERT:
          return ResultGlyphs.diffBegin ~ ResultGlyphs.diffInsert ~ d.text.to!string ~ ResultGlyphs.diffEnd;
        case Operation.EQUAL:
          return d.text.to!string;
    }
  }

  override string toString() @trusted {
    return "Diff:\n" ~ diff_main(expected, actual).map!(a => getResult(a)).join;
  }

  void print(ResultPrinter printer) @trusted {
    auto result = diff_main(expected, actual);
    printer.info("Diff:");

    foreach(diff; result) {
      if(diff.operation == Operation.EQUAL) {
        printer.primary(diff.text.to!string);
      }

      if(diff.operation == Operation.INSERT) {
        printer.successReverse(diff.text.to!string);
      }

      if(diff.operation == Operation.DELETE) {
        printer.dangerReverse(diff.text.to!string);
      }
    }

    printer.primary("\n");
  }
}

@("DiffResult finds the differences")
unittest {
  auto diff = new DiffResult("abc", "asc");
  diff.toString.should.equal("Diff:\na[-b][+s]c");
}

@("DiffResult uses the custom glyphs")
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
    this.value = value.replace("\0", ResultGlyphs.nullChar);
    this.indent = indent;
  }

  bool hasValue() {
    return value != "";
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

  }

  private
  {
    struct Message {
      bool isSpecial;
      string text;
    }

    void printLine(string line, ResultPrinter printer) {
      Message[] messages;

      auto whiteIntervals = line.getWhiteIntervals;

      foreach(size_t index, ch; line) {
        bool showSpaces = index < whiteIntervals.left || index >= whiteIntervals.right;

        auto special = isSpecial(ch, showSpaces);

        if(messages.length == 0 || messages[messages.length - 1].isSpecial != special) {
          messages ~= Message(special, "");
        }

        messages[messages.length - 1].text ~= toVisible(ch, showSpaces);
      }

      foreach(message; messages) {
        if(message.isSpecial) {
          printer.info(message.text);
        } else {
          printer.primary(message.text);
        }
      }
    }

    bool isSpecial(T)(T ch, bool showSpaces) {
      if(ch == ' ' && showSpaces) {
        return true;
      }

      if(ch == '\r' || ch == '\t') {
        return true;
      }

      return false;
    }

    string toVisible(T)(T ch, bool showSpaces) {
      if(ch == ' ' && showSpaces) {
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

@("KeyResult does not display spaces between words with special chars")
unittest {
  auto result = new KeyResult!"key"(" row1  row2 ");
  auto printer = new MockPrinter();

  result.print(printer);
  printer.buffer.should.equal(`[info:      key:][info:᛫][primary:row1  row2][info:᛫]`);
}

@("KeyResult displays spaces with special chars on space lines")
unittest {
  auto result = new KeyResult!"key"("   ");
  auto printer = new MockPrinter();

  result.print(printer);
  printer.buffer.should.equal(`[info:      key:][info:᛫᛫᛫]`);
}

@("KeyResult displays no char for empty lines")
unittest {
  auto result = new KeyResult!"key"("");
  auto printer = new MockPrinter();

  result.print(printer);
  printer.buffer.should.equal(``);
}

@("KeyResult displays special characters with different contexts")
unittest {
  auto result = new KeyResult!"key"("row1\n \trow2");
  auto printer = new MockPrinter();

  result.print(printer);

  printer.buffer.should.equal(`[info:      key:][primary:row1][info:↲][primary:` ~ "\n" ~ `][info:         :][info:᛫¤][primary:row2]`);
}

@("KeyResult displays custom glyphs with different contexts")
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

  printer.buffer.should.equal(`[info:      key:][primary:row1][info:\n][primary:` ~ "\n" ~ `][info:         :][info: \t][primary:row2]`);
}

///
class ExpectedActualResult : IResult {
  protected {
    string title;
    KeyResult!"Expected" expected;
    KeyResult!"Actual" actual;
  }

  this(string title, string expected, string actual) nothrow @safe {
    this.title = title;
    this(expected, actual);
  }

  this(string expected, string actual) nothrow @safe {
    this.expected = new KeyResult!"Expected"(expected);
    this.actual = new KeyResult!"Actual"(actual);
  }

  override string toString() {
    auto line1 = expected.toString;
    auto line2 = actual.toString;
    string glue;
    string prefix;

    if(line1 != "" && line2 != "") {
      glue = "\n";
    }

    if(line1 != "" || line2 != "") {
      prefix = title == "" ? "\n" : ("\n" ~ title ~ "\n");
    }

    return prefix ~ line1 ~ glue ~ line2;
  }

  void print(ResultPrinter printer)
  {
    auto line1 = expected.toString;
    auto line2 = actual.toString;

    if(actual.hasValue || expected.hasValue) {
      printer.info(title == "" ? "\n" : ("\n" ~ title ~ "\n"));
    }

    expected.print(printer);
    if(actual.hasValue && expected.hasValue) {
      printer.primary("\n");
    }
    actual.print(printer);
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
  result.toString.should.equal(`
 Expected:data
   Actual:data`);
}

@("ExpectedActual result should show one line of the expected and actual data")
unittest
{
  auto result = new ExpectedActualResult("data\ndata", "data\ndata");
  result.toString.should.equal(`
 Expected:data\n
         :data
   Actual:data\n
         :data`);
}

/// A result that displays differences between ranges
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
    string glue;
    string prefix;

    if(line1 != "" || line2 != "") {
      prefix = "\n";
    }

    if(line1 != "" && line2 != "") {
      glue = "\n";
    }

    return prefix ~ line1 ~ glue ~ line2;
  }

  void print(ResultPrinter printer)
  {
    if(extra.hasValue || missing.hasValue) {
      printer.primary("\n");
    }

    extra.print(printer);
    if(extra.hasValue && missing.hasValue) {
      printer.primary("\n");
    }
    missing.print(printer);
  }
}


string toString(const(Token)[] tokens) {
  string result;

  foreach(token; tokens.filter!(a => str(a.type) != "comment")) {
    if(str(token.type) == "whitespace" && token.text == "") {
      result ~= "\n";
    } else {
     result ~= token.text == "" ? str(token.type) : token.text;
    }
  }

  return result;
}

auto getScope(const(Token)[] tokens, size_t line) nothrow {
  bool foundScope;
  bool foundAssert;
  size_t beginToken;
  size_t endToken = tokens.length;

  int paranthesisCount = 0;
  int scopeLevel;
  size_t[size_t] paranthesisLevels;

  foreach(i, token; tokens) {
    string type = str(token.type);

    if(type == "{") {
      paranthesisLevels[paranthesisCount] = i;
      paranthesisCount++;
    }

    if(type == "}") {
      paranthesisCount--;
    }

    if(line == token.line) {
      foundScope = true;
    }

    if(foundScope) {
      if(token.text == "should" || token.text == "Assert" || type == "assert" || type == ";") {
        foundAssert = true;
        scopeLevel = paranthesisCount;
      }

      if(type == "}" && paranthesisCount <= scopeLevel) {
        beginToken = paranthesisLevels[paranthesisCount];
        endToken = i + 1;

        break;
      }
    }
  }

  return const Tuple!(size_t, "begin", size_t, "end")(beginToken, endToken);
}

@("getScope returns the spec function and scope that contains a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 101);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].toString.strip.should.equal("it(\"should throw an exception if we request 2 android devices\", {
      ({
        auto result = [ device1.idup, device2.idup ].filterBy(RunOptions(\"\", \"android\", 2)).array;
      }).should.throwException!DeviceException.withMessage.equal(\"You requested 2 `androdid` devices, but there is only 1 healthy.\");
    }");
}

@("getScope returns a method scope and signature")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/class.d"), tokens);

  auto result = getScope(tokens, 10);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].toString.strip.should.equal("void bar() {
        assert(false);
    }");
}

@("getScope returns a method scope without assert")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/class.d"), tokens);

  auto result = getScope(tokens, 14);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);

  tokens[identifierStart .. result.end].toString.strip.should.equal("void bar2() {
        enforce(false);
    }");
}

size_t getFunctionEnd(const(Token)[] tokens, size_t start) {
  int paranthesisCount;
  size_t result = start;

  // iterate the parameters
  foreach(i, token; tokens[start .. $]) {
    string type = str(token.type);

    if(type == "(") {
      paranthesisCount++;
    }

    if(type == ")") {
      paranthesisCount--;
    }

    if(type == "{" && paranthesisCount == 0) {
      result = start + i;
      break;
    }

    if(type == ";" && paranthesisCount == 0) {
      return start + i;
    }
  }

  paranthesisCount = 0;
  // iterate the scope
  foreach(i, token; tokens[result .. $]) {
    string type = str(token.type);

    if(type == "{") {
      paranthesisCount++;
    }

    if(type == "}") {
      paranthesisCount--;

      if(paranthesisCount == 0) {
        result = result + i;
        break;
      }
    }
  }

  return result;
}

@("getFunctionEnd returns the end of a spec function with a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 101);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);
  auto functionEnd = getFunctionEnd(tokens, identifierStart);

  tokens[identifierStart .. functionEnd].toString.strip.should.equal("it(\"should throw an exception if we request 2 android devices\", {
      ({
        auto result = [ device1.idup, device2.idup ].filterBy(RunOptions(\"\", \"android\", 2)).array;
      }).should.throwException!DeviceException.withMessage.equal(\"You requested 2 `androdid` devices, but there is only 1 healthy.\");
    })");
}


@("getFunctionEnd returns the end of an unittest function with a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 81);
  auto identifierStart = getPreviousIdentifier(tokens, result.begin);
  auto functionEnd = getFunctionEnd(tokens, identifierStart) + 1;

  tokens[identifierStart .. functionEnd].toString.strip.should.equal("unittest {
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

}");
}

@("getScope returns tokens from a scope that contains a lambda")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getScope(tokens, 81);

  tokens[result.begin .. result.end].toString.strip.should.equal(`{
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;

}`);
}

size_t getPreviousIdentifier(const(Token)[] tokens, size_t startIndex) {
  enforce(startIndex > 0);
  enforce(startIndex < tokens.length);

  int paranthesisCount;
  bool foundIdentifier;

  foreach(i; 0..startIndex) {
    auto index = startIndex - i - 1;
    auto type = str(tokens[index].type);

    if(type == "(") {
      paranthesisCount--;
    }

    if(type == ")") {
      paranthesisCount++;
    }

    if(paranthesisCount < 0) {
      return getPreviousIdentifier(tokens, index - 1);
    }

    if(paranthesisCount != 0) {
      continue;
    }

    if(type == "unittest") {
      return index;
    }

    if(type == "{" || type == "}") {
      return index + 1;
    }

    if(type == ";") {
      return index + 1;
    }

    if(type == "=") {
      return index + 1;
    }

    if(type == ".") {
      foundIdentifier = false;
    }

    if(type == "identifier" && foundIdentifier) {
      foundIdentifier = true;
      continue;
    }

    if(foundIdentifier) {
      return index;
    }
  }

  return 0;
}

@("getPreviousIdentifier returns the previous unittest identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 81);

  auto result = getPreviousIdentifier(tokens, scopeResult.begin);

  tokens[result .. scopeResult.begin].toString.strip.should.equal(`unittest`);
}

@("getPreviousIdentifier returns the previous paranthesis identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 63);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`(5, (11))`);
}

@("getPreviousIdentifier returns the previous function call identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 75);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`found(4)`);
}

@("getPreviousIdentifier returns the previous map identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 85);

  auto end = scopeResult.end - 12;
  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`[1, 2, 3].map!"a"`);
}

size_t getAssertIndex(const(Token)[] tokens, size_t startLine) {
  auto assertTokens = tokens
    .enumerate
    .filter!(a => a[1].text == "Assert")
    .filter!(a => a[1].line <= startLine)
    .array;

  if(assertTokens.length == 0) {
    return 0;
  }

  return assertTokens[assertTokens.length - 1].index;
}

@("getAssertIndex returns the index of the Assert structure identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getAssertIndex(tokens, 55);

  tokens[result .. result + 4].toString.strip.should.equal(`Assert.equal(`);
}

auto getParameter(const(Token)[] tokens, size_t startToken) {
  size_t paranthesisCount;

  foreach(i; startToken..tokens.length) {
    string type = str(tokens[i].type);

    if(type == "(" || type == "[") {
      paranthesisCount++;
    }

    if(type == ")" || type == "]") {
      if(paranthesisCount == 0) {
        return i;
      }

      paranthesisCount--;
    }

    if(paranthesisCount > 0) {
      continue;
    }

    if(type == ",") {
      return i;
    }
  }


  return 0;
}

@("getParameter returns the first parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 57) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].toString.strip.should.equal(`(5, (11))`);
}

@("getParameter returns the first list parameter from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto begin = getAssertIndex(tokens, 89) + 4;
  auto end = getParameter(tokens, begin);
  tokens[begin .. end].toString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

@("getPreviousIdentifier returns the previous array identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 4);
  auto end = scopeResult.end - 13;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`[1, 2, 3]`);
}

@("getPreviousIdentifier returns the previous array of instances identifier from a list of tokens")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 90);
  auto end = scopeResult.end - 16;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`[ new Value(1), new Value(2) ]`);
}

size_t getShouldIndex(const(Token)[] tokens, size_t startLine) {
  auto shouldTokens = tokens
    .enumerate
    .filter!(a => a[1].text == "should")
    .filter!(a => a[1].line <= startLine)
    .array;

  if(shouldTokens.length == 0) {
    return 0;
  }

  return shouldTokens[shouldTokens.length - 1].index;
}

@("getShouldIndex returns the index of the should call")
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getShouldIndex(tokens, 4);

  auto token = tokens[result];
  token.line.should.equal(3);
  token.text.should.equal(`should`);
  str(token.type).text.should.equal(`identifier`);
}

/// Source result data stored as a struct for efficiency
struct SourceResultData {
  static private {
    const(Token)[][string] fileTokens;
  }

  string file;
  size_t line;
  const(Token)[] tokens;

  static SourceResultData create(string fileName, size_t line) nothrow @trusted {
    SourceResultData data;
    data.file = fileName;
    data.line = line;

    if (!fileName.exists) {
      return data;
    }

    try {
      updateFileTokens(fileName);
      auto result = getScope(fileTokens[fileName], line);

      auto begin = getPreviousIdentifier(fileTokens[fileName], result.begin);
      auto end = getFunctionEnd(fileTokens[fileName], begin) + 1;

      data.tokens = fileTokens[fileName][begin .. end];
    } catch (Throwable t) {
    }

    return data;
  }

  static void updateFileTokens(string fileName) {
    if(fileName !in fileTokens) {
      fileTokens[fileName] = [];
      splitMultilinetokens(fileToDTokens(fileName), fileTokens[fileName]);
    }
  }

  string getValue() {
    size_t begin;
    size_t end = getShouldIndex(tokens, line);

    if(end != 0) {
      begin = tokens.getPreviousIdentifier(end - 1);
      return tokens[begin .. end - 1].toString.strip;
    }

    auto beginAssert = getAssertIndex(tokens, line);

    if(beginAssert > 0) {
      begin = beginAssert + 4;
      end = getParameter(tokens, begin);
      return tokens[begin .. end].toString.strip;
    }

    return "";
  }

  string toString() nothrow {
    auto separator = leftJustify("", 20, '-');
    string result = "\n" ~ separator ~ "\n" ~ file ~ ":" ~ line.to!string ~ "\n" ~ separator;

    if(tokens.length == 0) {
      return result ~ "\n";
    }

    size_t currentLine = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach(token; tokens.filter!(token => token != tok!"whitespace")) {
      string prefix = "";

      foreach(lineNumber; currentLine..token.line) {
        if(lineNumber < line - 1 || afterErrorLine) {
          prefix ~= "\n" ~ rightJustify((lineNumber+1).to!string, 6, ' ') ~ ": ";
        } else {
          prefix ~= "\n>" ~ rightJustify((lineNumber+1).to!string, 5, ' ') ~ ": ";
        }
      }

      if(token.line != currentLine) {
        column = 1;
      }

      if(token.column > column) {
        prefix ~= ' '.repeat.take(token.column - column).array;
      }

      auto stringRepresentation = token.text == "" ? str(token.type) : token.text;
      auto lines = stringRepresentation.split("\n");

      result ~= prefix ~ lines[0];
      currentLine = token.line;
      column = token.column + stringRepresentation.length;

      if(token.line >= line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    return result;
  }

  immutable(Message)[] toMessages() nothrow {
    return [Message(Message.Type.info, toString())];
  }

  void print(ResultPrinter printer) {
    if(tokens.length == 0) {
      return;
    }

    printer.primary("\n");
    printer.info(file ~ ":" ~ line.to!string);

    size_t currentLine = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach(token; tokens.filter!(token => token != tok!"whitespace")) {
      foreach(lineNumber; currentLine..token.line) {
        printer.primary("\n");

        if(lineNumber < line - 1 || afterErrorLine) {
          printer.primary(rightJustify((lineNumber+1).to!string, 6, ' ') ~ ":");
        } else {
          printer.dangerReverse(">" ~ rightJustify((lineNumber+1).to!string, 5, ' ') ~ ":");
        }
      }

      if(token.line != currentLine) {
        column = 1;
      }

      if(token.column > column) {
        printer.primary(' '.repeat.take(token.column - column).array);
      }

      auto stringRepresentation = token.text == "" ? str(token.type) : token.text;

      if(token.text == "" && str(token.type) != "whitespace") {
        printer.info(str(token.type));
      } else if(str(token.type).indexOf("Literal") != -1) {
        printer.success(token.text);
      } else {
        printer.primary(token.text);
      }

      currentLine = token.line;
      column = token.column + stringRepresentation.length;

      if(token.line >= line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    printer.primary("\n");
  }
}

/// Wrapper class for SourceResultData to implement IResult interface
class SourceResult : IResult {
  private SourceResultData data;

  this(string fileName = __FILE__, size_t line = __LINE__, size_t range = 6) nothrow @trusted {
    data = SourceResultData.create(fileName, line);
  }

  this(SourceResultData sourceData) nothrow @trusted {
    data = sourceData;
  }

  @property string file() { return data.file; }
  @property size_t line() { return data.line; }

  static void updateFileTokens(string fileName) {
    SourceResultData.updateFileTokens(fileName);
  }

  string getValue() {
    return data.getValue();
  }

  override string toString() nothrow {
    return data.toString();
  }

  void print(ResultPrinter printer) {
    data.print(printer);
  }
}

@("TestException should read the code from the file")
unittest
{
  auto result = new SourceResult("test/values.d", 26);
  auto msg = result.toString;

  msg.should.equal("\n--------------------\ntest/values.d:26\n--------------------\n" ~
                   "    23: unittest {\n" ~
                   "    24:   /++/\n" ~
                   "    25: \n" ~
                   ">   26:   [1, 2, 3]\n" ~
                   ">   27:     .should\n" ~
                   ">   28:     .contain(4);\n" ~
                   "    29: }");
}

@("TestException should print the lines before multiline tokens")
unittest
{
  auto result = new SourceResult("test/values.d", 45);
  auto msg = result.toString;

  msg.should.equal("\n--------------------\ntest/values.d:45\n--------------------\n" ~
                   "    40: unittest {\n" ~
                   "    41:   /*\n" ~
                   "    42:   Multi line comment\n" ~
                   "    43:   */\n" ~
                   "    44: \n" ~
                   ">   45:   `multi\n" ~
                   ">   46:   line\n" ~
                   ">   47:   string`\n" ~
                   ">   48:     .should\n" ~
                   ">   49:     .contain(`multi\n" ~
                   ">   50:   line\n" ~
                   ">   51:   string`);\n" ~
                   "    52: }");
}

/// Converts a file to D tokens provided by libDParse.
/// All the whitespaces are ignored
const(Token)[] fileToDTokens(string fileName) nothrow @trusted {
  try {
    auto f = File(fileName);
    immutable auto fileSize = f.size();
    ubyte[] fileBytes = new ubyte[](fileSize.to!size_t);

    if(f.rawRead(fileBytes).length != fileSize) {
      return [];
    }

    StringCache cache = StringCache(StringCache.defaultBucketCount);

    LexerConfig config;
    config.stringBehavior = StringBehavior.source;
    config.fileName = fileName;
    config.commentBehavior = CommentBehavior.intern;

    auto lexer = DLexer(fileBytes, config, &cache);
    const(Token)[] tokens = lexer.array;

    return tokens.map!(token => const Token(token.type, token.text.idup, token.line, token.column, token.index)).array;
  } catch(Throwable) {
    return [];
  }
}

@("TestException should ignore missing files")
unittest
{
  auto result = new SourceResult("test/missing.txt", 10);
  auto msg = result.toString;

  msg.should.equal("\n" ~ `--------------------
test/missing.txt:10
--------------------` ~ "\n");
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

@("Source reporter should find the tested value from an assert utility")
unittest
{
  auto result = new SourceResult("test/values.d", 55);
  result.getValue.should.equal("5");

  result = new SourceResult("test/values.d", 56);
  result.getValue.should.equal("(5+1)");

  result = new SourceResult("test/values.d", 57);
  result.getValue.should.equal("(5, (11))");
}

@("Source reporter should get the value from multiple should asserts")
unittest
{
  auto result = new SourceResult("test/values.d", 61);
  result.getValue.should.equal("5");

  result = new SourceResult("test/values.d", 62);
  result.getValue.should.equal("(5+1)");

  result = new SourceResult("test/values.d", 63);
  result.getValue.should.equal("(5, (11))");
}

@("Source reporter should get the value after a scope")
unittest
{
  auto result = new SourceResult("test/values.d", 71);
  result.getValue.should.equal("found");
}

@("Source reporter should get a function call value")
unittest
{
  auto result = new SourceResult("test/values.d", 75);
  result.getValue.should.equal("found(4)");
}

@("Source reporter should parse nested lambdas")
unittest
{
  auto result = new SourceResult("test/values.d", 81);
  result.getValue.should.equal("({
    ({ }).should.beNull;
  })");
}

@("Source reporter prints the source code")
unittest
{
  auto result = new SourceResult("test/values.d", 36);
  auto printer = new MockPrinter();

  result.print(printer);


  auto lines = printer.buffer.split("[primary:\n]");

  lines[1].should.equal(`[info:test/values.d:36]`);
  lines[2].should.equal(`[primary:    31:][info:unittest][primary: ][info:{]`);
  lines[7].should.equal(`[dangerReverse:>   36:][primary:    ][info:.][primary:contain][info:(][success:4][info:)][info:;]`);
}

/// split multiline tokens in multiple single line tokens with the same type
void splitMultilinetokens(const(Token)[] tokens, ref const(Token)[] result) nothrow @trusted {

  try {
    foreach(token; tokens) {
      auto pieces = token.text.idup.split("\n");

      if(pieces.length <= 1) {
        result ~= const Token(token.type, token.text.dup, token.line, token.column, token.index);
      } else {
        size_t line = token.line;
        size_t column = token.column;

        foreach(textPiece; pieces) {
          result ~= const Token(token.type, textPiece, line, column, token.index);
          line++;
          column = 1;
        }
      }
    }
  } catch(Throwable) {}
}

/// A new line sepparator
class SeparatorResult : IResult {
  override string toString() {
    return "\n";
  }

  void print(ResultPrinter printer) {
    printer.primary("\n");
  }
}

class ListInfoResult : IResult {
  private {
    struct Item {
      string singular;
      string plural;
      string[] valueList;

      string key() {
        return valueList.length > 1 ? plural : singular;
      }

      MessageResult toMessage(size_t indentation = 0) {
        auto printableKey = rightJustify(key ~ ":", indentation, ' ');

        auto result = new MessageResult(printableKey);

        string glue;
        foreach(value; valueList) {
          result.addText(glue);
          result.addValue(value);
          glue = ",";
        }

        return result;
      }
    }

    Item[] items;
  }

  void add(string key, string value) {
    items ~= Item(key, "", [value]);
  }

  void add(string singular, string plural, string[] valueList) {
    items ~= Item(singular, plural, valueList);
  }

  private size_t indentation() {
    auto elements = items.filter!"a.valueList.length > 0";

    if(elements.empty) {
      return 0;
    }

    return elements.map!"a.key".map!"a.length".maxElement + 2;
  }

  override string toString() {
    auto indent = indentation;
    auto elements = items.filter!"a.valueList.length > 0";

    if(elements.empty) {
      return "";
    }

    return "\n" ~ elements.map!(a => a.toMessage(indent)).map!"a.toString".join("\n");
  }

  void print(ResultPrinter printer) {
    auto indent = indentation;
    auto elements = items.filter!"a.valueList.length > 0";

    if(elements.empty) {
      return;
    }

    foreach(item; elements) {
      printer.primary("\n");
      item.toMessage(indent).print(printer);
    }
  }
}

@("convert to string the added data to ListInfoResult")
unittest {
  auto result = new ListInfoResult();

  result.add("a", "1");
  result.add("ab", "2");
  result.add("abc", "3");

  result.toString.should.equal(`
   a:1
  ab:2
 abc:3`);
}

@("print the added data to ListInfoResult")
unittest {
  auto printer = new MockPrinter();
  auto result = new ListInfoResult();

  result.add("a", "1");
  result.add("ab", "2");
  result.add("abc", "3");

  result.print(printer);

  printer.buffer.should.equal(`[primary:
][primary:   a:][primary:][info:1][primary:
][primary:  ab:][primary:][info:2][primary:
][primary: abc:][primary:][info:3]`);
}


@("convert to string the added data lists to ListInfoResult")
unittest {
  auto result = new ListInfoResult();

  result.add("a", "as", ["1", "2","3"]);
  result.add("ab", "abs", ["2", "3"]);
  result.add("abc", "abcs", ["3"]);
  result.add("abcd", "abcds", []);

  result.toString.should.equal(`
  as:1,2,3
 abs:2,3
 abc:3`);
}

IResult[] toResults(Exception e) nothrow @trusted {
  try {
    return [ new MessageResult(e.message.to!string) ];
  } catch(Exception) {
    return [ new MessageResult("Unknown error!") ];
  }
}
