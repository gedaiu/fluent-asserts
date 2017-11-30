module fluentasserts.core.results;

import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.exception;
import std.typecons;

struct ResultGlyphs {
  static {
    string tab;
    string carriageReturn;
    string newline;
    string space;
    string nullChar;

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
      ResultGlyphs.nullChar = `␀`;
    } else {
      ResultGlyphs.tab = `¤`;
      ResultGlyphs.carriageReturn = `←`;
      ResultGlyphs.newline = `↲`;
      ResultGlyphs.space = `᛫`;
      ResultGlyphs.nullChar = `\0`;
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
      .replace("\0", ResultGlyphs.nullChar)
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
  ResultGlyphs.carriageReturn  = `\r`;
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

class DiffResult : IResult {
  import ddmp.diff;

  protected
  {
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
    this.value = value.replace("\0", ResultGlyphs.nullChar);
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

/// KeyResult should not dispaly spaces between words with special chars
unittest {
  auto result = new KeyResult!"key"(" row1  row2 ");
  auto printer = new MockPrinter();

  result.print(printer);
  printer.buffer.should.equal(`[info:      key:][info:᛫][primary:row1  row2][info:᛫][primary:` ~ "\n" ~ `]`);
}

/// KeyResult should dispaly spaces with special chars on space lines
unittest {
  auto result = new KeyResult!"key"("   ");
  auto printer = new MockPrinter();

  result.print(printer);
  printer.buffer.should.equal(`[info:      key:][info:᛫᛫᛫][primary:` ~ "\n" ~ `]`);
}

/// KeyResult should display no char for empty lines
unittest {
  auto result = new KeyResult!"key"("");
  auto printer = new MockPrinter();

  result.print(printer);
  printer.buffer.should.equal(``);
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

import dparse.ast;
import dparse.lexer;
import dparse.parser;

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
  bool found;
  size_t beginToken;
  size_t endToken = tokens.length;
  int paranthesisCount = 0;

  foreach(i, token; tokens) {
    string type = str(token.type);

    if(!found && paranthesisCount == 0 && type == "{") {
      beginToken = i;
    }

    if(type == "{") {
      paranthesisCount++;
    }

    if(type == "}") {
      paranthesisCount--;
    }

    if(line == token.line) {
      found = true;
    }

    if(found && type == "}" && paranthesisCount == 0) {
      endToken = i + 1;
      break;
    }
  }

  return const Tuple!(size_t, "begin", size_t, "end")(beginToken, endToken);
}

/// Get tokens from a scope that contains a lambda
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
  writeln("===================");
  tokens.toString.writeln;

  enforce(startIndex > 0);
  enforce(startIndex < tokens.length);

  size_t paranthesisCount;
  bool foundIdentifier;

  foreach(i; 0..startIndex) {
    auto index = startIndex - i - 1;
    3.writeln("index: ", index, " len:", tokens.length);
    auto type = str(tokens[index].type);

    4.writeln(" ", type, "?", tokens[index].text, "?");
    if(type == "(") {
      paranthesisCount--;
    }

    if(type == ")") {
      paranthesisCount++;
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

/// Get the the previous unittest identifier from a list of tokens
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 81);

  auto result = getPreviousIdentifier(tokens, scopeResult.begin);

  writeln(result, " ", scopeResult.begin);
  tokens[result .. scopeResult.begin].toString.writeln("===>");

  tokens[result .. scopeResult.begin].toString.strip.should.equal(`unittest`);
}

/// Get the the previous paranthesis identifier from a list of tokens
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 63);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`(5, (11))`);
}

/// Get the the previous function call identifier from a list of tokens
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 75);

  auto end = scopeResult.end - 11;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`found(4)`);
}

/// Get the the previous map!"" identifier from a list of tokens
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 85);

  auto end = scopeResult.end - 12;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[scopeResult.begin .. end].toString.writeln("???????");

  tokens[result .. end].toString.strip.should.equal(`[1, 2, 3].map!"a"`);
}

/// Get the the previous array identifier from a list of tokens
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto scopeResult = getScope(tokens, 4);
  auto end = scopeResult.end - 13;

  auto result = getPreviousIdentifier(tokens, end);

  tokens[result .. end].toString.strip.should.equal(`[1, 2, 3]`);
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

/// Get the index of the should call
unittest {
  const(Token)[] tokens = [];
  splitMultilinetokens(fileToDTokens("test/values.d"), tokens);

  auto result = getShouldIndex(tokens, 4);

  auto token = tokens[result];
  token.line.should.equal(3);
  token.text.should.equal(`should`);
  str(token.type).text.should.equal(`identifier`);
}

/// An alternative to SourceResult that uses
// DParse to get the source code
class SourceResult : IResult
{
  static private {
    const(Token)[][string] fileTokens;
  }

  private const
  {
    string file;
    size_t line;

    Token[] tokens;
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
      updateFileTokens(fileName);

      auto result = getScope(fileTokens[fileName], line);
      auto begin = result.begin;//getPreviousIdentifier(fileTokens[fileName], result.begin);

      this.tokens = fileTokens[fileName][begin .. result.end];
    } catch (Throwable t) {
    }
  }

  static void updateFileTokens(string fileName) {
    if(fileName !in fileTokens) {
      fileTokens[fileName] = [];
      splitMultilinetokens(fileToDTokens(fileName), fileTokens[fileName]);
    }
  }

  string getValue() {
    size_t startIndex = 0;
    size_t possibleStartIndex = 0;
    size_t endIndex = 0;

    size_t lastStartIndex = 0;
    size_t lastEndIndex = 0;

    int paranthesisCount = 0;

    auto end = getShouldIndex(tokens, line);
    writeln("end: ", end);

    if(end == 0) {
      return "";
    }

    auto begin = tokens.getPreviousIdentifier(end - 1);

    return tokens[begin .. end - 1].toString.strip;
  }

  override string toString() nothrow
  {
    auto separator = leftJustify("", 20, '-');
    string result = separator ~ "\n" ~ file ~ ":" ~ line.to!string ~ "\n" ~ separator;

    if(tokens.length == 0) {
      return result;
    }

    size_t line = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach(token; this.tokens.filter!(token => token != tok!"whitespace")) {
      string prefix = "";

      foreach(lineNumber; line..token.line) {
        if(lineNumber < this.line -1 || afterErrorLine) {
          prefix ~= "\n" ~ rightJustify((lineNumber+1).to!string, 6, ' ') ~ ": ";
        } else {
          prefix ~= "\n>" ~ rightJustify((lineNumber+1).to!string, 5, ' ') ~ ": ";
        }
      }

      if(token.line != line) {
        column = 1;
      }

      if(token.column > column) {
        prefix ~= ' '.repeat.take(token.column - column).array;
      }

      auto stringRepresentation = token.text == "" ? str(token.type) : token.text;

      auto lines = stringRepresentation.split("\n");

      result ~= prefix ~ lines[0];
      line = token.line;
      column = token.column + stringRepresentation.length;

      if(token.line >= this.line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    return result;
  }

  void print(ResultPrinter printer)
  {
    if(tokens.length == 0) {
      return;
    }

    printer.info(file ~ ":" ~ line.to!string);

    size_t line = tokens[0].line - 1;
    size_t column = 1;
    bool afterErrorLine = false;

    foreach(token; this.tokens.filter!(token => token != tok!"whitespace")) {
      foreach(lineNumber; line..token.line) {
        printer.primary("\n");

        if(lineNumber < this.line -1 || afterErrorLine) {
          printer.primary(rightJustify((lineNumber+1).to!string, 6, ' ') ~ ":");
        } else {
          printer.dangerReverse(">" ~ rightJustify((lineNumber+1).to!string, 5, ' ') ~ ":");
        }
      }

      if(token.line != line) {
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

      line = token.line;
      column = token.column + stringRepresentation.length;

      if(token.line >= this.line && str(token.type) == ";") {
        afterErrorLine = true;
      }
    }

    printer.primary("\n\n");
  }
}

@("TestException should read the code from the file")
unittest
{
  auto result = new SourceResult("test/values.d", 26);
  auto msg = result.toString;

  msg.should.equal("--------------------\ntest/values.d:26\n--------------------\n" ~
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

  msg.should.equal("--------------------\ntest/values.d:45\n--------------------\n" ~
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
const(Token)[] fileToDTokens(string fileName) nothrow {
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

  msg.should.equal(`--------------------
test/missing.txt:10
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

/// Source reporter should print the source code
unittest
{
  auto result = new SourceResult("test/values.d", 36);
  auto printer = new MockPrinter();

  result.print(printer);

  auto lines = printer.buffer.split("[primary:\n]");

  lines[0].should.equal(`[info:test/values.d:36]`);
  lines[1].should.equal(`[primary:    31:][info:unittest][primary: ][info:{]`);
  lines[6].should.equal(`[dangerReverse:>   36:][primary:    ][info:.][primary:contain][info:(][success:4][info:)][info:;]`);
}

/// split multiline tokens in multiple single line tokens with the same type
void splitMultilinetokens(const(Token)[] tokens, ref const(Token)[] result) nothrow {

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