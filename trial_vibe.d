version = is_trial_embeded;
/++
  A module containing utilities for presenting information to the user

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.algorithm;
import std.string;

/// The default writer is initialized at the test run initialization with the right
/// class, depending on the hosts capabilities.
ReportWriter defaultWriter;

/// The writer interface is used to present information to the user.
interface ReportWriter
{

  /// The information type.
  /// Convey meaning through color with a handful of emphasis utility classes.
  enum Context
  {
    /// Some important information
    active,

    /// Less important information
    inactive,

    ///
    success,

    /// Something that the user should notice
    info,

    /// Something that the user should be aware of
    warning,

    /// Something that the user must notice
    danger,

    ///
    _default
  }

  /// Go back a few lines
  void goTo(int);

  /// Write a string
  void write(string, Context = Context.active);

  /// Write a string with reversed colors
  void writeReverse(string, Context = Context.active);

  /// Write a string and go to a new line
  void writeln(string, Context = Context.active);

  /// Show the cursor from user
  void showCursor();

  /// Hide the cursor from user
  void hideCursor();

  /// Get how many characters you can print on a line
  uint width();
}

/// The console writer outputs data to the standard output. It does not
/// support colors and cursor moving.
/// This is the default writer if arsd.terminal is not present.
class ConsoleWriter : ReportWriter
{

  /// not supported
  void goTo(int)
  {
  }

  ///
  void write(string text, Context)
  {
    std.stdio.write(text);
  }

  ///
  void writeReverse(string text, Context)
  {
    std.stdio.write(text);
  }

  ///
  void writeln(string text, Context)
  {
    std.stdio.writeln(text);
  }

  /// not supported
  void showCursor()
  {
  }

  /// not supported
  void hideCursor()
  {
  }

  /// returns 80
  uint width()
  {
    return 80;
  }
}


shared static this()
{
  version (windows)
  {
    import core.sys.windows.windows;

    SetConsoleCP(65001);
    SetConsoleOutputCP(65001);
  }

  defaultWriter = new ColorConsoleWriter;
}


/// This writer uses arsd.terminal and it's used if you add this dependency to your project
/// It supports all the features and you should use it if you want to get the best experience
/// from this project
class ColorConsoleWriter : ReportWriter
{
  private
  {
    int[string] cues;
    Terminal terminal;

    int lines = 0;
    bool movedToBottom = false;
    Context currentContext = Context._default;
    bool isReversed = false;
  }

  this()
  {
    this.terminal = Terminal(ConsoleOutputType.linear);
    this.terminal._suppressDestruction = true;

    lines = this.terminal.cursorY;
  }

  void setColor(Context context)
  {
    if (!isReversed && context == currentContext)
    {
      return;
    }

    isReversed = false;
    currentContext = context;

    switch (context)
    {
    case Context.active:
      terminal.color(Color.white | Bright, Color.DEFAULT);
      break;

    case Context.inactive:
      terminal.color(Color.black | Bright, Color.DEFAULT);
      break;

    case Context.success:
      terminal.color(Color.green | Bright, Color.DEFAULT);
      break;

    case Context.info:
      terminal.color(Color.cyan, Color.DEFAULT);
      break;

    case Context.warning:
      terminal.color(Color.yellow, Color.DEFAULT);
      break;

    case Context.danger:
      terminal.color(Color.red, Color.DEFAULT);
      break;

    default:
      terminal.reset();
    }
  }

  void setColorReverse(Context context)
  {
    if (!isReversed && context == currentContext)
    {
      return;
    }

    currentContext = context;
    isReversed = true;

    switch (context)
    {
    case Context.active:
      terminal.color(Color.DEFAULT, Color.white | Bright);
      break;

    case Context.inactive:
      terminal.color(Color.DEFAULT, Color.black | Bright);
      break;

    case Context.success:
      terminal.color(Color.DEFAULT, Color.green | Bright);
      break;

    case Context.info:
      terminal.color(Color.DEFAULT, Color.cyan);
      break;

    case Context.warning:
      terminal.color(Color.DEFAULT, Color.yellow);
      break;

    case Context.danger:
      terminal.color(Color.DEFAULT, Color.red);
      break;

    default:
      terminal.reset();
    }
  }

  void resetColor()
  {
    setColor(Context._default);
  }

  /// Go up `y` lines
  void goTo(int y)
  {
    if (!movedToBottom)
    {
      movedToBottom = true;
      terminal.moveTo(0, terminal.height - 1);
    }
    terminal.moveTo(0, terminal.cursorY - y, ForceOption.alwaysSend);
  }

  /// writes a string
  void write(string text, Context context)
  {
    lines += text.count!(a => a == '\n');

    setColor(context);

    terminal.write(text);
    terminal.flush;
    resetColor;
    terminal.flush;
  }

  /// writes a string with reversed colors
  void writeReverse(string text, Context context)
  {
    lines += text.count!(a => a == '\n');

    setColorReverse(context);

    terminal.write(text);
    resetColor;
    terminal.flush;
  }

  /// writes a string and go to a new line
  void writeln(string text, Context context)
  {
    this.write(text ~ "\n", context);
  }

  /// show the terminal cursor
  void showCursor()
  {
    terminal.showCursor;
  }

  /// hide the terminal cursor
  void hideCursor()
  {
    terminal.hideCursor;
  }

  /// returns the terminal width
  uint width()
  {
    return terminal.width;
  }
}

/// You can use this writer if you don't want to keep the data in memmory
/// It's useful for unit testing. It supports line navigation, with no color
/// The context info might be added in the future, once a good format is found.
class BufferedWriter : ReportWriter
{

  /// The buffer used to write the data
  string buffer = "";

  private
  {
    size_t line = 0;
    size_t charPos = 0;
    bool replace;

    string[] screen;
  }

  /// go uo y lines
  void goTo(int y)
  {
    line = line - y;
    charPos = 0;
  }

  /// returns 80
  uint width()
  {
    return 80;
  }

  ///
  void write(string text, Context)
  {
    auto lines = text.count!(a => a == '\n');
    auto pieces = buffer.split("\n");

    auto newLines = text.split("\n");

    for (auto i = line; i < line + newLines.length; i++)
    {
      if (i != line)
      {
        charPos = 0;
      }

      while (i >= screen.length)
      {
        screen ~= "";
      }

      auto newLine = newLines[i - line];

      if (charPos + newLine.length >= screen[i].length)
      {
        screen[i] = screen[i][0 .. charPos] ~ newLine;
      }
      else
      {
        screen[i] = screen[i][0 .. charPos] ~ newLine ~ screen[i][charPos + newLine.length .. $];
      }
      charPos = charPos + newLine.length;
    }

    buffer = screen.join("\n");
    screen = buffer.split("\n");
    line += lines;
  }

  ///
  void writeReverse(string text, Context c)
  {
    write(text, c);
  }

  ///
  void writeln(string text, Context c)
  {
    write(text ~ '\n', c);
  }

  /// does nothing
  void showCursor()
  {
  }

  /// does nothing
  void hideCursor()
  {
  }
}









/++
  A module containing the ResultReporter

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/12x1mkxfmsj1j0f7qqwarkiyw.js" id="asciicast-12x1mkxfmsj1j0f7qqwarkiyw" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;


version (Have_fluent_asserts_core)
{
  import fluentasserts.core.base;
  import fluentasserts.core.results;
}

/// A structure containing the glyphs used for the result reporter
struct ResultGlyphs {
  version(Windows) {
    ///
    string error = "x";
  } else {
    ///
    string error = "✖";
  }
}

///
string resultGlyphsToCode(ResultGlyphs glyphs) {
  return "ResultGlyphs(`" ~ glyphs.error ~ "`)";
}


/// The "Result" reporter will print an overview of your test run
class ResultReporter : ILifecycleListener, ITestCaseLifecycleListener,
  ISuiteLifecycleListener, IStepLifecycleListener
{
  private
  {
    ResultGlyphs glyphs;

    int suites;
    int tests;
    int failedTests = 0;

    SysTime beginTime;
    ReportWriter writer;

    Throwable[] exceptions;
    string[] failedTestNames;

    string currentSuite;
  }

  this()
  {
    writer = defaultWriter;
  }

  this(ResultGlyphs glyphs)
  {
    writer = defaultWriter;
    this.glyphs = glyphs;
  }

  this(ReportWriter writer)
  {
    this.writer = writer;
  }

  void begin(ref SuiteResult suite)
  {
    suites++;
    currentSuite = suite.name;
  }

  void end(ref SuiteResult suite)
  {
  }

  void update()
  {
  }

  void begin(string suite, ref TestResult test)
  {
    tests++;
  }

  void end(string suite, ref TestResult test)
  {
    if (test.status != TestResult.Status.failure)
    {
      return;
    }

    exceptions ~= test.throwable;
    failedTestNames ~= currentSuite ~ " " ~ test.name;

    failedTests++;
  }

  void begin(string suite, string test, ref StepResult step)
  {
  }

  void end(string suite, string test, ref StepResult step)
  {
  }

  void begin(ulong)
  {
    beginTime = Clock.currTime;
  }

  void end(SuiteResult[] results)
  {
    auto diff = Clock.currTime - beginTime;

    writer.writeln("");
    writer.writeln("");

    if (tests == 0)
    {
      reportNoTest;
    }

    if (tests == 1)
    {
      reportOneTestResult;
    }

    if (tests > 1)
    {
      reportTestsResult;
    }

    writer.writeln("");

    reportExceptions;
  }

  private
  {
    void reportNoTest()
    {
      writer.write("There are no tests to run.");
    }

    void reportOneTestResult()
    {
      auto timeDiff = Clock.currTime - beginTime;

      if (failedTests > 0)
      {
        writer.write(glyphs.error ~ " The test failed in " ~ timeDiff.to!string ~ ":",
            ReportWriter.Context.danger);
        return;
      }

      writer.write("The test succeeded in " ~ timeDiff.to!string ~ "!", ReportWriter.Context.info);
    }

    void reportTestsResult()
    {
      string suiteText = suites == 1 ? "1 suite" : suites.to!string ~ " suites";
      auto timeDiff = Clock.currTime - beginTime;
      writer.write("Executed " ~ tests.to!string ~ " tests in " ~ suiteText ~ " in " ~ timeDiff.to!string ~ ".\n",
          ReportWriter.Context.info);
    }

    void reportExceptions()
    {
      foreach (size_t i, t; exceptions)
      {
        writer.writeln("");
        writer.writeln(i.to!string ~ ") " ~ failedTestNames[i] ~ ":", ReportWriter.Context.danger);

        version (Have_fluent_asserts_core)
        {
          TestException e = cast(TestException) t;

          if (e is null)
          {
            writer.writeln(t.to!string);
          }
          else
          {
            e.print(new TrialResultPrinter(defaultWriter));
          }
        }
        else
        {
          writer.writeln(t.to!string);
        }

        writer.writeln("");
      }
    }
  }
}

version (Have_fluent_asserts_core) {
  class TrialResultPrinter : ResultPrinter {
    ReportWriter writer;

    this(ReportWriter writer) {
      this.writer = writer;
    }

    void primary(string text) {
      writer.write(text, ReportWriter.Context._default);
      writer.write("");
    }

    void info(string text) {
      writer.write(text, ReportWriter.Context.info);
      writer.write("");
    }

    void danger(string text) {
      writer.write(text, ReportWriter.Context.danger);
      writer.write("");
    }

    void success(string text) {
      writer.write(text, ReportWriter.Context.success);
      writer.write("");
    }

    void dangerReverse(string text) {
      writer.writeReverse(text, ReportWriter.Context.danger);
      writer.write("");
    }

    void successReverse(string text) {
      writer.writeReverse(text, ReportWriter.Context.success);
      writer.write("");
    }
  }
}





/++
  A module containing the StatsReporter

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.algorithm;
import std.string;
import std.conv;
import std.exception;
import std.array;
import std.datetime;
import std.stdio;
import std.file;


struct Stat
{
  string name;
  SysTime begin;
  SysTime end;
  TestResult.Status status = TestResult.Status.unknown;
}

class StatStorage
{
  Stat[] values;
}

Stat find(StatStorage storage, const(string) name)
{
  auto res = storage.values.filter!(a => a.name == name);

  if (res.empty)
  {
    return Stat("", SysTime.min, SysTime.min);
  }

  return res.front;
}

/// The stats reporter creates a csv file with the duration and the result of all your steps and tests.
/// It's usefull to use it with other reporters, like spec progress.
class StatsReporter : ILifecycleListener, ITestCaseLifecycleListener,
  ISuiteLifecycleListener, IStepLifecycleListener
{
  private
  {
    StatStorage storage;
    string[][string] path;
  }

  this(StatStorage storage)
  {
    this.storage = storage;
  }

  this()
  {
    this.storage = new StatStorage;
  }

  private
  {
    auto lastItem(string key)
    {
      enforce(path[key].length > 0, "There is no defined path");
      return path[key][path.length - 1];
    }
  }

  void update()
  {
  }

  void begin(ref SuiteResult suite)
  {
  }

  void end(ref SuiteResult suite)
  {
    storage.values ~= Stat(suite.name, suite.begin, Clock.currTime);
  }

  void begin(string suite, ref TestResult test)
  {
  }

  void end(string suite, ref TestResult test)
  {
    storage.values ~= Stat(suite ~ "." ~ test.name, test.begin, Clock.currTime, test.status);
  }

  void begin(string suite, string test, ref StepResult step)
  {
    string key = suite ~ "." ~ test;
    path[key] ~= step.name;
  }

  void end(string suite, string test, ref StepResult step)
  {
    string key = suite ~ "." ~ test;

    enforce(lastItem(key) == step.name, "Invalid step name");
    storage.values ~= Stat(key ~ "." ~ path[key].join('.'), step.begin, Clock.currTime);
    path[key] = path[key][0 .. $ - 1];
  }

  void begin(ulong)
  {
  }

  void end(SuiteResult[])
  {
    auto f = File("trial-stats.csv", "w"); // open for writing
    f.write(storage.toCsv);

    auto attachment = const Attachment("stats", "trial-stats.csv", "text/csv");
    LifeCycleListeners.instance.attach(attachment);
  }
}





string toCsv(const(StatStorage) storage)
{
  return storage.values.map!(a => [a.name, a.begin.toISOExtString,
      a.end.toISOExtString, a.status.to!string]).map!(a => a.join(',')).join('\n');
}


StatStorage toStatStorage(const(string) data)
{
  auto stat = new StatStorage;

  stat.values = data.split('\n').map!(a => a.split(',')).map!(a => Stat(a[0],
      SysTime.fromISOExtString(a[1]), SysTime.fromISOExtString(a[2]),
      a[3].to!(TestResult.Status))).array;

  return stat;
}


StatStorage statsFromFile(string fileName)
{
  if (!fileName.exists)
  {
    return new StatStorage();
  }

  return fileName.readText.toStatStorage;
}
/++
  A module containing the DotMatrixReporter

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/aorvsrruse34n2xym8y7885m1.js" id="asciicast-aorvsrruse34n2xym8y7885m1" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;


///
struct DotMatrixGlyphs {
  string success = ".";
  string failure = "!";
  string unknown = "?";
}

///
string dotMatrixGlyphsToCode(DotMatrixGlyphs glyphs) {
  return "DotMatrixGlyphs(`"~ glyphs.success ~"`,`"~ glyphs.failure ~"`,`"~ glyphs.unknown ~"`)";
}

/// The dot matrix reporter is simply a series of characters which represent test cases.
/// Failures highlight in red exclamation marks (!).
/// Good if you prefer minimal output.
class DotMatrixReporter : ITestCaseLifecycleListener
{
  private {
    ReportWriter writer;
    DotMatrixGlyphs glyphs;
  }

  this(DotMatrixGlyphs glyphs)
  {
    writer = defaultWriter;
    this.glyphs = glyphs;
  }

  this(ReportWriter writer)
  {
    this.writer = writer;
  }

  void begin(string suite, ref TestResult test)
  {
  }

  void end(string suite, ref TestResult test)
  {
    switch (test.status)
    {
    case TestResult.Status.success:
      writer.write(glyphs.success, ReportWriter.Context.inactive);
      break;

    case TestResult.Status.failure:
      writer.write(glyphs.failure, ReportWriter.Context.danger);
      break;

    default:
      writer.write(glyphs.unknown, ReportWriter.Context.warning);
    }
  }
}



/++
  A module containing the HtmlReporter

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;
import std.file;


/// The "html" reporter outputs a hierarchical HTML body representation of your tests.
class HtmlReporter : ILifecycleListener
{
  string header = `<!DOCTYPE html>
  <html>
  <head>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
    <meta charset="UTF-8">
    <title>Test Result</title>
  </head>
  <body>`;

  string footer = `</body></html>`;

  private
  {
    bool success = true;
  }

  void begin(ulong)
  {
  }

  void update()
  {
  }

  void end(SuiteResult[] results)
  {
    string content = header;

    string escapeHtml(string text)
    {
      return text.replace("<", "&lt;").replace(">", "&gt;");
    }

    string duration(T)(T item) pure
    {
      return ` <span class="duration">` ~ (item.end - item.begin).to!string ~ `</span> `;
    }

    string testStatus(T)(T item)
    {
      if (item.status == TestResult.Status.success)
      {
        return `<span class="label label-success">` ~ item.status.to!string ~ `</span>`;
      }

      if (item.status == TestResult.Status.failure)
      {
        return `<span class="label label-danger">` ~ item.status.to!string ~ `</span>`;
      }

      return `<span class="label label-info">` ~ item.status.to!string ~ `</span>`;
    }

    content ~= `<div class="container-fluid">`;

    string details;
    double passes = 0;
    double failures = 0;
    double other = 0;
    Duration totalDuration = Duration.zero;

    foreach (result; results)
    {
      details ~= "\n<h1>" ~ escapeHtml(result.name) ~ "<small>" ~ duration(
          result) ~ "</small></h1>\n";
      totalDuration += result.end - result.begin;

      foreach (test; result.tests)
      {
        details ~= `<div class="row">`;
        details ~= `<div class="col-sm-4"><strong class='test-name'>` ~ escapeHtml(
            test.name) ~ `</strong></div>`;
        details ~= `<div class="col-sm-8">` ~ testStatus(
            test) ~ ` <span class="label label-default">` ~ duration(test) ~ `</span></div>`;
        details ~= `</div>`;

        if (test.throwable !is null)
        {
          details ~= `<pre>` ~ escapeHtml(test.throwable.to!string) ~ `</pre>`;
        }

        if (test.status == TestResult.Status.success)
        {
          passes++;
        }
        else if (test.status == TestResult.Status.failure)
        {
          failures++;
        }
        else
        {
          other++;
        }
      }
    }

    content ~= `<p>passes: <strong>` ~ passes.to!string ~ `</strong></p>`;
    content ~= `<p>failures: <strong>` ~ failures.to!string ~ `</strong></p>`;
    content ~= `<p>other: <strong>` ~ other.to!string ~ `</strong></p>`;
    content ~= `<p>duration: <strong>` ~ totalDuration.to!string ~ `</strong></p>`;

    auto passPercent = ((passes / (passes + failures + other)) * 100);
    auto failurePercent = ((failures / (passes + failures + other)) * 100);
    auto otherPercent = ((other / (passes + failures + other)) * 100);

    content ~= `<div class="progress">
      <div class="progress-bar progress-bar-success" style="width: ` ~ passPercent.to!string
      ~ `%;"></div>
      <div class="progress-bar progress-bar-danger" style="width: `
      ~ failurePercent.to!string ~ `%;"></div>
      <div class="progress-bar" style="width: `
      ~ otherPercent.to!string ~ `%;"></div>
    </div>`;

    content ~= details ~ "\n</div>" ~ footer;

    std.file.write("trial-result.html", content);
  }
}



/++
  A module containing the AllureReporter

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;
import std.file;
import std.path;
import std.uuid;
import std.range;


private string escape(string data) {
  string escapedData = data.dup;

  escapedData = escapedData.replace(`&`, `&amp;`);
  escapedData = escapedData.replace(`"`, `&quot;`);
  escapedData = escapedData.replace(`'`, `&apos;`);
  escapedData = escapedData.replace(`<`, `&lt;`);
  escapedData = escapedData.replace(`>`, `&gt;`);

  return escapedData;
}

/// The Allure reporter creates a xml containing the test results, the steps
/// and the attachments. http://allure.qatools.ru/
class AllureReporter : ILifecycleListener
{
  void begin(ulong testCount) {
    if(exists("allure")) {
      std.file.rmdirRecurse("allure");
    }
  }

  void update() {}

  void end(SuiteResult[] result)
  {
    if(!exists("allure")) {
      "allure".mkdir;
    }

    foreach(item; result) {
      string uuid = randomUUID.toString;
      string xml = AllureSuiteXml(item, uuid).toString;

      std.file.write("allure/" ~ uuid ~ "-testsuite.xml", xml);
    }
  }
}

struct AllureSuiteXml {
  /// The suite result
  SuiteResult result;

  /// The suite id
  string uuid;

  /// The allure version
  const string allureVersion = "1.5.2";

  /// Converts the suiteResult to a xml string
  string toString() {
    auto epoch = SysTime.fromUnixTime(0);
    string tests = result.tests.map!(a => AllureTestXml(a, uuid).toString).array.join("\n");

    if(tests != "") {
      tests = "\n" ~ tests;
    }

    auto xml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns2:test-suite start="` ~ (result.begin - epoch).total!"msecs".to!string ~ `" stop="` ~ (result.end - epoch).total!"msecs".to!string ~ `" version="` ~ this.allureVersion ~ `" xmlns:ns2="urn:model.allure.qatools.yandex.ru">
    <name>` ~ result.name.escape ~ `</name>
    <title>` ~ result.name.escape ~ `</title>
    <test-cases>`
     ~ tests ~ `
    </test-cases>
`;

    if(result.attachments.length > 0) {
      xml ~= "    <attachments>\n";
      xml ~= result.attachments.map!(a => AllureAttachmentXml(a, 6, uuid)).map!(a => a.toString).array.join('\n') ~ "\n";
      xml ~= "    </attachments>\n";
    }

    xml ~= `    <labels>
        <label name="framework" value="Trial"/>
        <label name="language" value="D"/>
    </labels>
</ns2:test-suite>`;

    return xml;
  }
}





/// AllureSuiteXml should add the attachments


struct AllureTestXml {
  ///
  TestResult result;

  ///
  string uuid;

  /// Converts a test result to allure status
  string allureStatus() {
    switch(result.status) {
      case TestResult.Status.created:
        return "canceled";

      case TestResult.Status.failure:
        return "failed";

      case TestResult.Status.skip:
        return "canceled";

      case TestResult.Status.success:
        return "passed";

      default:
        return "unknown";
    }
  }

  /// Return the string representation of the test
  string toString() {
    auto epoch = SysTime.fromUnixTime(0);
    auto start = (result.begin - epoch).total!"msecs";
    auto stop = (result.end - epoch).total!"msecs";

    string xml = `        <test-case start="` ~ start.to!string ~ `" stop="` ~ stop.to!string ~ `" status="` ~ allureStatus ~ `">` ~ "\n";
    xml ~= `            <name>` ~ result.name.escape ~ `</name>` ~ "\n";

    if(result.labels.length > 0) {
      xml ~= "            <labels>\n";

      foreach(label; result.labels) {
        xml ~= "              <label name=\"" ~ label.name ~ "\" value=\"" ~ label.value ~ "\"/>\n";
      }

      xml ~= "            </labels>\n";
    }

    if(result.throwable !is null) {
      xml ~= `            <failure>
                <message>` ~ result.throwable.msg.escape ~ `</message>
                <stack-trace>` ~ result.throwable.to!string.escape ~ `</stack-trace>
            </failure>` ~ "\n";
    }

    if(result.steps.length > 0) {
      xml ~= "            <steps>\n";
      xml ~= result.steps.map!(a => AllureStepXml(a, 14, uuid)).map!(a => a.toString).array.join('\n') ~ "\n";
      xml ~= "            </steps>\n";
    }

    if(result.attachments.length > 0) {
      xml ~= "            <attachments>\n";
      xml ~= result.attachments.map!(a => AllureAttachmentXml(a, 14, uuid)).map!(a => a.toString).array.join('\n') ~ "\n";
      xml ~= "            </attachments>\n";
    }

    xml ~= `        </test-case>`;

    return xml;
  }
}



/// AllureTestXml should transform a test with steps


/// AllureTestXml should transform a test with labels


/// AllureTestXml should add the attachments


struct AllureStepXml {
  private {
    StepResult step;
    size_t indent;
    string uuid;
  }

  this(StepResult step, size_t indent, string uuid) {
    this.step = step;
    this.indent = indent;
    this.uuid = uuid;
  }

  /// Return the string representation of the step
  string toString() {
    auto epoch = SysTime.fromUnixTime(0);
    const spaces = "  " ~ (" ".repeat(indent).array.join());
    string result = spaces ~ `<step start="` ~ (step.begin - epoch).total!"msecs".to!string ~ `" stop="` ~ (step.end - epoch).total!"msecs".to!string ~ `" status="passed">` ~ "\n" ~
    spaces ~ `  <name>` ~ step.name.escape ~ `</name>` ~ "\n";

    if(step.steps.length > 0) {
      result ~= spaces ~ "  <steps>\n";
      result ~= step.steps.map!(a => AllureStepXml(a, indent + 6, uuid)).map!(a => a.to!string).array.join('\n') ~ "\n";
      result ~= spaces ~ "  </steps>\n";
    }

    if(step.attachments.length > 0) {
      result ~= spaces ~ "  <attachments>\n";
      result ~= step.attachments.map!(a => AllureAttachmentXml(a, indent + 6, uuid)).map!(a => a.to!string).array.join('\n') ~ "\n";
      result ~= spaces ~ "  </attachments>\n";
    }

    result ~= spaces ~ `</step>`;

    return result;
  }
}

/// AllureStepXml should transform a step


/// AllureStepXml should transform nested steps


/// AllureStepXml should add the attachments


/// Allure representation of an atachment.
/// It will copy the file to the allure folder with an unique name
struct AllureAttachmentXml {

  private const {
    Attachment attachment;
    size_t indent;
  }

  @disable this();

  /// Init the struct and copy the atachment to the allure folder
  this(Attachment attachment, size_t indent, string uuid) {
    this.indent = indent;

    auto destination = buildPath(getcwd, "allure");

    if(!exists(buildPath(destination, uuid))) {
      buildPath(destination, uuid).mkdirRecurse;
    }

    ulong index;

    string allureFile;

    do {
      allureFile = buildPath(destination, uuid, attachment.name ~ "." ~ index.to!string ~ "." ~ baseName(attachment.file));
      index++;
    } while(allureFile.exists);

    std.file.copy(attachment.file, allureFile);
    this.attachment = Attachment(attachment.name, allureFile.asRelativePath(destination).array, attachment.mime);
  }

  /// convert the attachment to string
  string toString() {
    return (" ".repeat(indent).array.join()) ~ "<attachment title=\"" ~ attachment.name ~
      "\" source=\"" ~ attachment.file ~
      "\" type=\"" ~ attachment.mime ~ "\" />";
  }
}

/// Allure attachments should be copied to a folder containing the suite name


/// Allure attachments should avoid name collisions

/++
  A module containing the LandingReporter

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/ar2qel0uzunpjmfzkg7xtvsa1.js" id="asciicast-ar2qel0uzunpjmfzkg7xtvsa1" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;


///
struct LandingGlyphs {
  string plane = "✈";
  string margin = "━";
  string lane = "⋅";
}

///
string landingGlyphsToCode(LandingGlyphs glyphs) {
  return "LandingGlyphs(`"~ glyphs.plane ~"`,`"~ glyphs.margin ~"`,`"~ glyphs.lane ~"`)";
}

/// The Landing Strip (landing) reporter is a gimmicky test reporter simulating a plane landing unicode ftw
class LandingReporter : ITestCaseLifecycleListener, ILifecycleListener
{
  private
  {
    ReportWriter writer;
    LandingGlyphs glyphs;

    ulong testCount;
    ulong currentTest;
    bool success = true;
  }

  this(LandingGlyphs glyphs)
  {
    writer = defaultWriter;
    this.glyphs = glyphs;
  }

  this(ReportWriter writer)
  {
    this.writer = writer;
  }

  void begin(ulong testCount)
  {
    this.testCount = testCount;
    writer.writeln("\n\n");
    drawLane;
  }

  void update()
  {

  }

  void end(SuiteResult[])
  {

  }

  void begin(string suite, ref TestResult test)
  {
  }

  void end(string suite, ref TestResult test)
  {
    currentTest++;
    success = success && test.status == TestResult.Status.success;
    drawLane;
  }

  private void drawLane()
  {
    size_t size = (writer.width / 4) * 3;
    size_t position = ((cast(double) currentTest / cast(double) testCount) * size).to!size_t;

    writer.goTo(3);
    writer.writeln(glyphs.margin.replicate(size), ReportWriter.Context.inactive);

    if (currentTest < testCount)
    {
      writer.write(glyphs.lane.replicate(position), ReportWriter.Context.inactive);
      writer.write(glyphs.plane, success ? ReportWriter.Context.active : ReportWriter.Context.danger);
      writer.writeln(glyphs.lane.replicate(size - position - 1), ReportWriter.Context.inactive);
    }
    else
    {
      writer.write(glyphs.lane.replicate(size), ReportWriter.Context.inactive);
      writer.writeln(glyphs.plane, success ? ReportWriter.Context.active : ReportWriter.Context.danger);
    }

    writer.writeln(glyphs.margin.replicate(size), ReportWriter.Context.inactive);
  }
}


/++
  A module containing the ListReporter

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/b4u0o9vba18dquzdgwif7anl5.js" id="asciicast-b4u0o9vba18dquzdgwif7anl5" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;


/// The list reporter outputs a simple specifications list as test cases pass or
/// fail
class ListReporter : SpecReporter
{
  this(SpecGlyphs glyphs)
  {
    super(glyphs);
  }

  this(ReportWriter writer)
  {
    super(writer);
  }

  override
  {
    void begin(string suite, ref TestResult)
    {

    }

    void end(string suite, ref TestResult test)
    {
      if(test.status == TestResult.Status.success) {
        write!(Type.success)("", 1);
        write!(Type.none)(suite ~ " " ~ test.name ~ "\n");
      } else {
        write!(Type.failure)(suite ~ " " ~ test.name ~ "\n", 1);
        failedTests++;
      }
    }
  }
}



/++
  A module containing the ProgressReporter

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/a3aspcv8cw5l04l59xw9vbtqa.js" id="asciicast-a3aspcv8cw5l04l59xw9vbtqa" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;


///
struct ProgressGlyphs {
  version(Windows) {
    string empty = ".";
    string fill = "#";
  } else {
    string empty = "░";
    string fill = "▓";
  }
}

///
string progressGlyphsToCode(ProgressGlyphs glyphs) {
  return "ProgressGlyphs(`" ~ glyphs.empty ~ "`,`" ~ glyphs.fill ~ "`)";
}

/// The “progress” reporter implements a simple progress-bar
class ProgressReporter : ITestCaseLifecycleListener, ILifecycleListener
{
  private
  {
    ReportWriter writer;
    ProgressGlyphs glyphs;

    ulong testCount;
    ulong currentTest;
    bool success = true;
  }
  this(ProgressGlyphs glyphs)
  {
    writer = defaultWriter;
    this.glyphs = glyphs;
  }

  this(ReportWriter writer)
  {
    this.writer = writer;
  }

  void begin(ulong testCount)
  {
    this.testCount = testCount;
    writer.writeln("");
    draw;
  }

  void update()
  {

  }

  void end(SuiteResult[])
  {

  }

  void begin(string suite, ref TestResult test)
  {
  }

  void end(string suite, ref TestResult test)
  {
    currentTest++;
    success = success && test.status == TestResult.Status.success;
    draw;
  }

  private void draw()
  {
    int size = min((writer.width / 4) * 3, testCount);
    size_t position = ((cast(double) currentTest / cast(double) testCount) * size).to!size_t;

    writer.goTo(1);

    writer.write(currentTest.to!string ~ "/" ~ testCount.to!string ~ " ",
        success ? ReportWriter.Context.active : ReportWriter.Context.danger);

    writer.write(glyphs.fill.replicate(position), ReportWriter.Context.active);
    writer.writeln(glyphs.empty.replicate(size - position), ReportWriter.Context.inactive);
  }
}


/++
  A module containing the SpecProgressReporter

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.algorithm;


/// A flavour of the "spec" reporter that show the progress of long tests. This works well with the
/// parallel runner. If you are using the stats reporters, you will see a countdown for how long
/// you need to wait until the test is finished.
class SpecProgressReporter : SpecReporter, ISuiteLifecycleListener, ILifecycleListener {
  private {
    alias UpdateFunction = void delegate(CueInfo info);

    struct CueInfo {
      string id;
      string name;
      long duration;
      SysTime begin;
    }

    size_t oldTextLength;
    StatStorage storage;
    string[] path;

    CueInfo[] cues;
  }

  this(StatStorage storage) {
    super();
    this.storage = storage;
    writer.writeln("");
  }

  this(ReportWriter writer, StatStorage storage) {
    super(writer);
    this.storage = storage;
    writer.writeln("");
  }

  void clearProgress() {
    writer.goTo(1);
    writer.write("\n" ~ " ".replicate(oldTextLength));
    writer.goTo(1);
    oldTextLength = 0;
  }

  void begin(ulong) {}
  void end(SuiteResult[]) {}
  void update() {
    writer.hideCursor;
    auto now = Clock.currTime;
    auto progress = cues.map!(cue => "*[" ~ (cue.duration - (now - cue.begin).total!"seconds").to!string ~ "s]" ~ cue.name).join(" ").to!string;

    auto spaces = "";

    if(oldTextLength > progress.length) {
      spaces = " ".replicate(oldTextLength - progress.length);
    }

    writer.goTo(1);
    writer.write("\n" ~ progress ~ spaces ~ " ");

    oldTextLength = progress.length;
    writer.showCursor;
  }

  void removeCue(string id) {
    cues = cues.filter!(a => a.id != id).array;
  }

  void begin(ref SuiteResult suite) {
    auto stat = storage.find(suite.name);
    auto duration = (stat.end - stat.begin).total!"seconds";

    cues ~= CueInfo(suite.name, suite.name, duration, Clock.currTime);
    update;
  }

  void end(ref SuiteResult suite) {
    removeCue(suite.name);
    update;
  }

  override {
    void begin(string suite, ref TestResult test) {
      super.begin(suite, test);

      auto stat = storage.find(suite ~ "." ~ test.name);
      auto duration = (stat.end - stat.begin).total!"seconds";

      cues ~= CueInfo(suite ~ "." ~ test.name, test.name, duration, Clock.currTime);
      update;
    }

    void end(string suite, ref TestResult test) {
      clearProgress;
      super.end(suite, test);
      removeCue(suite ~ "." ~ test.name);
      writer.writeln("");
      update;
    }
  }
}



/++
  A module containing the SpecStepsReporter

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/bsk6do8t4zay9k9vznvh8yn71.js" id="asciicast-bsk6do8t4zay9k9vznvh8yn71" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/


/// A structure containing the glyphs used for the spec steps reporter
struct SpecStepsGlyphs {
  version(Windows) {
    ///
    string testBegin = "/";

    ///
    string testEnd = "\\";

    ///
    string step = "|";
  } else {
    ///
    string testBegin = "┌";

    ///
    string testEnd = "└";

    ///
    string step = "│";
  }
}

///
string specStepsGlyphsToCode(SpecStepsGlyphs glyphs) {
  return "SpecStepsGlyphs(`" ~ glyphs.testBegin ~ "`, `" ~ glyphs.testEnd ~ "`, `" ~ glyphs.step ~ "`)";
}

/// A flavour of the "spec" reporter that show the tests and the steps of your tests.
class SpecStepsReporter : SpecReporter, ISuiteLifecycleListener, IStepLifecycleListener
{
  private {
    size_t indents;
    size_t stepIndents;

    SpecStepsGlyphs glyphs;
  }


  this(SpecStepsGlyphs glyphs)
  {
    super();
    this.glyphs = glyphs;
  }

  this(ReportWriter writer)
  {
    super(writer);
  }

  void begin(ref SuiteResult suite)
  {
    indents = printSuite(suite.name);
  }

  void end(ref SuiteResult) { }

  override
  {
    void begin(string suite, ref TestResult test)
    {
      stepIndents = 0;
      write!(Type.none)(glyphs.testBegin ~ " " ~ test.name ~ "\n", indents);
    }

    void end(string suite, ref TestResult test)
    {
      write!(Type.none)(glyphs.testEnd ~ " ", indents);

      if(test.status == TestResult.Status.success) {
        write!(Type.success)("Success\n", 0);
      } else if(test.status == TestResult.Status.failure) {
        write!(Type.failure)("Failure\n", 0);
        failedTests++;
      } else {
        write!(Type.none)("Unknown\n", 0);
      }
    }
  }

  void begin(string suite, string test, ref StepResult s)
  {
    stepIndents++;
    write!(Type.none)(glyphs.step, indents);
    write!(Type.none)(" " ~ s.name ~ "\n", stepIndents);

  }

  void end(string suite, string test, ref StepResult)
  {
    stepIndents--;
  }
}



/++
  A module containing the SpecReporter

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/9z1tolgn7x55v41i3mm3wlkum.js" id="asciicast-9z1tolgn7x55v41i3mm3wlkum" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;


/// A structure containing the glyphs used for the spec reporter
struct SpecGlyphs {
  version(Windows) {
    ///
    string ok = "+";
  } else {
    ///
    string ok = "✓";
  }
}

///
string specGlyphsToCode(SpecGlyphs glyphs) {
  return "SpecGlyphs(`" ~ glyphs.ok ~ "`)";
}

/// This is the default reporter. The "spec" reporter outputs a hierarchical view nested just as the test cases are.
class SpecReporter : ITestCaseLifecycleListener
{
  enum Type
  {
    none,
    success,
    step,
    failure,
    testBegin,
    testEnd,
    emptyLine
  }

  protected
  {
    int failedTests = 0;
    string lastSuiteName;

    ReportWriter writer;
  }

  private
  {
    SpecGlyphs glyphs;
  }

  this()
  {
    writer = defaultWriter;
  }

  this(SpecGlyphs glyphs)
  {
    writer = defaultWriter;
    this.glyphs = glyphs;
  }

  this(ReportWriter writer)
  {
    this.writer = writer;
  }

  private
  {
    string indentation(size_t cnt) pure
    {
      return "  ".replicate(cnt);
    }
  }

  void write(Type t)(string text = "", size_t spaces = 0)
  {
    writer.write(indentation(spaces));

    switch (t)
    {
    case Type.emptyLine:
      writer.writeln("");
      break;

    case Type.success:
      writer.write(glyphs.ok, ReportWriter.Context.success);
      writer.write(" " ~ text, ReportWriter.Context.inactive);
      break;

    case Type.failure:
      writer.write(failedTests.to!string ~ ") " ~ text,
          ReportWriter.Context.danger);
      break;

    default:
      writer.write(text);
    }
  }

  void begin(string suite, ref TestResult test)
  {
  }

  protected auto printSuite(string suite) {
    size_t indents = 1;

    auto oldPieces = lastSuiteName.split(".");
    auto pieces = suite.split(".");
    lastSuiteName = suite;

    auto prefix = oldPieces.commonPrefix(pieces).array.length;

    write!(Type.emptyLine)();
    indents += prefix;

    foreach (piece; pieces[prefix .. $])
    {
      write!(Type.none)(piece, indents);
      write!(Type.emptyLine)();
      indents++;
    }

    return indents;
  }

  void end(string suite, ref TestResult test)
  {
    size_t indents = 1;

    if (suite != lastSuiteName)
    {
      indents = printSuite(suite);
    }
    else
    {
      indents = suite.count('.') + 2;
    }

    if (test.status == TestResult.Status.success)
    {
      write!(Type.success)(test.name, indents);
    }

    if (test.status == TestResult.Status.failure)
    {
      write!(Type.failure)(test.name, indents);
      failedTests++;
    }

    write!(Type.emptyLine);

    indents--;
  }
}






/++
  A module containing the XUnitReporter

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.algorithm;
import std.file;
import std.path;
import std.uuid;
import std.range;


private string escapeXUnit(string data) {
  string escapedData = data.dup;

  escapedData = escapedData.replace(`&`, `&amp;`);
  escapedData = escapedData.replace(`"`, `&quot;`);
  escapedData = escapedData.replace(`'`, `&apos;`);
  escapedData = escapedData.replace(`<`, `&lt;`);
  escapedData = escapedData.replace(`>`, `&gt;`);

  return escapedData;
}

/// The XUnit reporter creates a xml containing the test results
class XUnitReporter : ILifecycleListener
{
  void begin(ulong testCount) {
    if(exists("allure")) {
      std.file.rmdirRecurse("allure");
    }
  }

  void update() {}

  void end(SuiteResult[] result)
  {
    if(!exists("xunit")) {
      "xunit".mkdir;
    }

    foreach(item; result) {
      string uuid = randomUUID.toString;
      string xml = `<?xml version="1.0" encoding="UTF-8"?>` ~ "\n"~ `<testsuites>` ~ "\n" ~ XUnitSuiteXml(item, uuid).toString ~ "\n</testsuites>\n";

      std.file.write("xunit/" ~ item.name ~ ".xml", xml);
    }
  }
}

struct XUnitSuiteXml {
  /// The suite result
  SuiteResult result;

  /// The suite id
  string uuid;

  /// Converts the suiteResult to a xml string
  string toString() {
    auto epoch = SysTime.fromUnixTime(0);
    string tests = result.tests.map!(a => XUnitTestXml(a, uuid).toString).array.join("\n");


    auto failures = result.tests.filter!(a => a.status == TestResult.Status.failure).count;
    auto skipped = result.tests.filter!(a => a.status == TestResult.Status.skip).count;
    auto errors = result.tests.filter!(a =>
      a.status != TestResult.Status.success &&
      a.status != TestResult.Status.skip &&
      a.status != TestResult.Status.failure).count;

    if(tests != "") {
      tests = "\n" ~ tests;
    }

    auto xml = `  <testsuite name="` ~ result.name ~ `" errors="` ~ errors.to!string ~ `" skipped="` ~ skipped.to!string ~ `" tests="` ~ result.tests.length.to!string ~ `" failures="` ~ failures.to!string ~ `" time="0" timestamp="` ~ result.begin.toISOExtString ~ `">`
     ~ tests ~ `
  </testsuite>`;

    return xml;
  }
}


/// XUnitTestXml should transform a suite with a success test


/// XUnitTestXml should transform a suite with a failed test


/// XUnitTestXml should transform a suite with a skipped test



/// XUnitTestXml should transform a suite with a unknown test


/// XUnitTestXml should transform an empty suite


struct XUnitTestXml {
  ///
  TestResult result;

  ///
  string uuid;

  /// Return the string representation of the test
  string toString() {
    auto time = (result.end -result.begin).total!"msecs";
    string xml = `      <testcase name="` ~ result.name.escapeXUnit ~ `">` ~ "\n";

    if(result.status == TestResult.Status.failure) {
      if(result.throwable !is null) {
        auto lines = result.throwable.msg.split("\n") ~ "no message";

        xml ~= `      <failure message="` ~ lines[0].escapeXUnit ~ `">` ~ result.throwable.to!string.escapeXUnit ~ `</failure>` ~ "\n";
      } else {
        xml ~= `      <failure/>` ~ "\n";
      }
    } else if(result.status == TestResult.Status.skip) {
      xml ~= `      <skipped/>` ~ "\n";
    } else if(result.status != TestResult.Status.success) {
        xml ~= `      <error message="unknown status">` ~ result.status.to!string.escapeXUnit ~ `</error>` ~ "\n";
    }

    xml ~= `      </testcase>`;

    return xml;
  }
}

/// XUnitTestXml should transform a success test


/// XUnitTestXml should transform a failing test

/++
  A module containing the TAP13 reporter https://testanything.org/

  This is an example of how this reporter looks
  <script type="text/javascript" src="https://asciinema.org/a/135734.js" id="asciicast-135734" async></script>

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.conv;
import std.string;
import std.algorithm;

version(Have_fluent_asserts_core) {
  import fluentasserts.core.base;
  import fluentasserts.core.results;
}


/// This reporter will print the results using thr Test anything protocol version 13
class TapReporter : ILifecycleListener, ITestCaseLifecycleListener
{
  private {
    ReportWriter writer;
  }

  ///
  this()
  {
    writer = defaultWriter;
  }

  ///
  this(ReportWriter writer)
  {
    this.writer = writer;
  }

  ///
  void begin(ulong testCount) {
    writer.writeln("TAP version 13", ReportWriter.Context._default);
    writer.writeln("1.." ~ testCount.to!string, ReportWriter.Context._default);
  }

  ///
  void update() { }

  ///
  void end(SuiteResult[]) { }

  ///
  void begin(string, ref TestResult)
  {
  }

  ///
  void end(string suite, ref TestResult test)
  {
    if(test.status == TestResult.Status.success) {
      writer.writeln("ok - " ~ suite ~ "." ~ test.name, ReportWriter.Context._default);
    } else {
      writer.writeln("not ok - " ~ suite ~ "." ~ test.name, ReportWriter.Context._default);

      version(Have_fluent_asserts_core) {
        if(test.throwable !is null) {
          if(cast(TestException) test.throwable !is null) {
            printTestException(test);
          } else {
            printThrowable(test);
          }

          writer.writeln("");
        }
      } else {
        printThrowable(test);
      }
    }
  }


  version(Have_fluent_asserts_core) {
    private void printTestException(ref TestResult test) {
      auto diagnostic = test.throwable.msg.split("\n").map!(a => "# " ~ a).join("\n");

      auto msg = test.throwable.msg.split("\n")[0];

      writer.writeln(diagnostic, ReportWriter.Context._default);
      writer.writeln("  ---", ReportWriter.Context._default);
      writer.writeln("  message: '" ~ msg ~ "'", ReportWriter.Context._default);
      writer.writeln("  severity: " ~ test.status.to!string, ReportWriter.Context._default);
      writer.writeln("  location:", ReportWriter.Context._default);
      writer.writeln("    fileName: '" ~ test.throwable.file.replace("'", "\'") ~ "'", ReportWriter.Context._default);
      writer.writeln("    line: " ~ test.throwable.line.to!string, ReportWriter.Context._default);
    }
  }

  private void printThrowable(ref TestResult test) {
    writer.writeln("  ---", ReportWriter.Context._default);
    writer.writeln("  message: '" ~ test.throwable.msg ~ "'", ReportWriter.Context._default);
    writer.writeln("  severity: " ~ test.status.to!string, ReportWriter.Context._default);
    writer.writeln("  location:", ReportWriter.Context._default);
    writer.writeln("    fileName: '" ~ test.throwable.file.replace("'", "\'") ~ "'", ReportWriter.Context._default);
    writer.writeln("    line: " ~ test.throwable.line.to!string, ReportWriter.Context._default);
  }
}


/// it should print "The Plan" at the beginning


/// it should print a sucess test


/// it should print a failing test with a basic throwable


/// it should not print the YAML if the throwable is missing


/// it should print the results of a TestException
/++
  A module containing the Visual Trial reporter used to send data to the
  Visual Studio Code plugin

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.conv;
import std.string;
import std.algorithm;

version(Have_fluent_asserts_core) {
  import fluentasserts.core.base;
  import fluentasserts.core.results;
}


/// This reporter will print the results using thr Test anything protocol version 13
class VisualTrialReporter : ILifecycleListener, ITestCaseLifecycleListener
{
  private {
    ReportWriter writer;
  }

  ///
  this()
  {
    writer = defaultWriter;
  }

  ///
  this(ReportWriter writer)
  {
    this.writer = writer;
  }

  ///
  void begin(ulong testCount) {
    writer.writeln("", ReportWriter.Context._default);
    writer.writeln("", ReportWriter.Context._default);
  }

  ///
  void update() { }

  ///
  void end(SuiteResult[]) { }

  ///
  void begin(string suite, ref TestResult result)
  {
    writer.writeln("BEGIN TEST;", ReportWriter.Context._default);
    writer.writeln("suite:" ~ suite, ReportWriter.Context._default);
    writer.writeln("test:" ~ result.name, ReportWriter.Context._default);
    writer.writeln("file:" ~ result.fileName, ReportWriter.Context._default);
    writer.writeln("line:" ~ result.line.to!string, ReportWriter.Context._default);
    writer.writeln("labels:[" ~ result.labels.map!(a => a.toString).join(", ") ~ "]", ReportWriter.Context._default);
  }

  ///
  void end(string suite, ref TestResult test)
  {
    writer.writeln("status:" ~ test.status.to!string, ReportWriter.Context._default);

    if(test.status != TestResult.Status.success) {
      if(test.throwable !is null) {
        writer.writeln("errorFile:" ~ test.throwable.file, ReportWriter.Context._default);
        writer.writeln("errorLine:" ~ test.throwable.line.to!string, ReportWriter.Context._default);
        writer.writeln("message:" ~ test.throwable.msg.split("\n")[0], ReportWriter.Context._default);
        writer.write("error:", ReportWriter.Context._default);
        writer.writeln(test.throwable.toString, ReportWriter.Context._default);
      }
    }

    writer.writeln("END TEST;", ReportWriter.Context._default);
  }
}


/// it should print "The Plan" at the beginning


/// it should print the test location



/// it should print a sucess test


/// it should print a failing test with a basic throwable


/// it should not print the YAML if the throwable is missing


/// it should print the results of a TestException
/++
  The main runner logic. You can find here some LifeCycle logic and test runner
  initalization

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.algorithm;
import std.datetime;
import std.range;
import std.traits;
import std.string;
import std.conv;


/// setup the LifeCycle collection
void setupLifecycle(Settings settings) {
  LifeCycleListeners.instance = new LifeCycleListeners;
  settings.reporters.map!(a => a.toLower).each!(a => addReporter(a, settings));

  if(settings.runInParallel) {
    LifeCycleListeners.instance.add(new ParallelExecutor(settings.maxThreads));
  } else {
    LifeCycleListeners.instance.add(new DefaultExecutor);
  }
}

/// Adds an embeded reporter listener to the LifeCycle listeners collection
void addReporter(string name, Settings settings) {

    switch(name) {
      case "spec":
        LifeCycleListeners.instance.add(new SpecReporter(settings.glyphs.spec));
        break;

      case "spec-progress":
        auto storage = statsFromFile("trial-stats.csv");
        LifeCycleListeners.instance.add(new SpecProgressReporter(storage));
        break;

      case "spec-steps":
        LifeCycleListeners.instance.add(new SpecStepsReporter(settings.glyphs.specSteps));
        break;

      case "dot-matrix":
        LifeCycleListeners.instance.add(new DotMatrixReporter(settings.glyphs.dotMatrix));
        break;

      case "landing":
        LifeCycleListeners.instance.add(new LandingReporter(settings.glyphs.landing));
        break;

      case "list":
        LifeCycleListeners.instance.add(new ListReporter(settings.glyphs.spec));
        break;

      case "progress":
        LifeCycleListeners.instance.add(new ProgressReporter(settings.glyphs.progress));
        break;

      case "html":
        LifeCycleListeners.instance.add(new HtmlReporter);
        break;

      case "allure":
        LifeCycleListeners.instance.add(new AllureReporter);
        break;

      case "xunit":
        LifeCycleListeners.instance.add(new XUnitReporter);
        break;

      case "result":
        LifeCycleListeners.instance.add(new ResultReporter(settings.glyphs.result));
        break;

      case "stats":
        LifeCycleListeners.instance.add(new StatsReporter);
        break;

      case "tap":
        LifeCycleListeners.instance.add(new TapReporter);
        break;

      case "visualtrial":
        LifeCycleListeners.instance.add(new VisualTrialReporter);
        break;

      default:
        writeln("There is no `" ~ name ~"` reporter");
    }
}

/// Returns an associative array of the detected tests,
/// where the key is the suite name and the value is the TestCase
const(TestCase)[][string] describeTests() {
  return describeTests(LifeCycleListeners.instance.getTestCases);
}

/// Returns an associative array of the detected tests,
/// where the key is the suite name and the value is the TestCase
const(TestCase)[][string] describeTests(const(TestCase)[] tests) {
  const(TestCase)[][string] groupedTests;

  foreach(test; tests) {
    groupedTests[test.suiteName] ~= test;
  }

  return groupedTests;
}

///
string toJSONHierarchy(T)(const(T)[][string] items) {
  struct Node {
    Node[string] nodes;
    const(T)[] values;

    void add(string[] path, const(T)[] values) {
      if(path.length == 0) {
        this.values = values;
        return;
      }

      if(path[0] !in nodes) {
        nodes[path[0]] = Node();
      }

      nodes[path[0]].add(path[1..$], values);
    }

    string toString(int spaces = 2) {
      string prefix = leftJustify("", spaces);
      string endPrefix = leftJustify("", spaces - 2);

      if(nodes.length == 0) {
        return "[\n" ~ values
          .map!(a => a.toString)
          .map!(a => prefix ~ a)
          .join(",\n") ~ "\n" ~ endPrefix ~ "]";
      }

      return "{\n" ~ nodes
            .byKeyValue
            .map!(a => `"` ~ a.key ~ `": ` ~ a.value.toString(spaces + 2))
            .map!(a => prefix ~ a)
            .join(",\n") ~ "\n" ~ endPrefix ~ "}";
    }
  }

  Node root;

  foreach(key; items.keys) {
    root.add(key.split("."), items[key]);
  }

  return root.toString;
}

/// convert an assoc array to JSON hierarchy


/// describeTests should return the tests cases serialised in json format


/// Runs the tests and returns the results
auto runTests(const(TestCase)[] tests, string testName = "") {
  setupSegmentationHandler!true();

  const(TestCase)[] filteredTests = tests;

  if(testName != "") {
    filteredTests = tests.filter!(a => a.name.indexOf(testName) != -1).array;
  }

  LifeCycleListeners.instance.begin(filteredTests.length);

  SuiteResult[] results = LifeCycleListeners.instance.beginExecution(filteredTests);

  foreach(test; filteredTests) {
    results ~= LifeCycleListeners.instance.execute(test);
  }

  results ~= LifeCycleListeners.instance.endExecution;
  LifeCycleListeners.instance.end(results);

  return results;
}

/// ditto
auto runTests(string testName = "") {
  return runTests(LifeCycleListeners.instance.getTestCases, testName);
}

/// Check if a suite result list is a success
bool isSuccess(SuiteResult[] results) {
  return results.map!(a => a.tests).joiner.map!(a => a.status).all!(a => a == TestResult.Status.success);
}


/// It should return true for an empty result


/// It should return true if all the tests succeded


/// It should return false if one the tests failed


/// The lifecycle listeners collections. You must use this instance in order
/// to extend the runner. You can have as many listeners as you want. The only restriction
/// is for ITestExecutor, which has no sense to have more than one instance for a run
class LifeCycleListeners {

  /// The global instange.
  static LifeCycleListeners instance;

  private {
    ISuiteLifecycleListener[] suiteListeners;
    ITestCaseLifecycleListener[] testListeners;
    IStepLifecycleListener[] stepListeners;
    ILifecycleListener[] lifecycleListeners;
    ITestDiscovery[] testDiscoveryListeners;
    IAttachmentListener[] attachmentListeners;
    ITestExecutor executor;

    string currentTest;
  }

  @property {
    /// Return an unique name for the current running test. If there is no test running it
    /// will return an empty string
    string runningTest() const nothrow {
      return currentTest;
    }
  }

  ///
  TestCase[] getTestCases() {
    return testDiscoveryListeners.map!(a => a.getTestCases).join;
  }

  /// Add a listener to the collection
  void add(T)(T listener) {
    static if(!is(CommonType!(ISuiteLifecycleListener, T) == void)) {
      suiteListeners ~= cast(ISuiteLifecycleListener) listener;
      suiteListeners = suiteListeners.filter!(a => a !is null).array;
    }

    static if(!is(CommonType!(ITestCaseLifecycleListener, T) == void)) {
      testListeners ~= cast(ITestCaseLifecycleListener) listener;
      testListeners = testListeners.filter!(a => a !is null).array;
    }

    static if(!is(CommonType!(IStepLifecycleListener, T) == void)) {
      stepListeners ~= cast(IStepLifecycleListener) listener;
      stepListeners = stepListeners.filter!(a => a !is null).array;
    }

    static if(!is(CommonType!(ILifecycleListener, T) == void)) {
      lifecycleListeners ~= cast(ILifecycleListener) listener;
      lifecycleListeners = lifecycleListeners.filter!(a => a !is null).array;
    }

    static if(!is(CommonType!(ITestExecutor, T) == void)) {
      executor = cast(ITestExecutor) listener;
    }

    static if(!is(CommonType!(ITestDiscovery, T) == void)) {
      testDiscoveryListeners ~= cast(ITestDiscovery) listener;
      testDiscoveryListeners = testDiscoveryListeners.filter!(a => a !is null).array;
    }

    static if(!is(CommonType!(IAttachmentListener, T) == void)) {
      attachmentListeners ~= cast(IAttachmentListener) listener;
      attachmentListeners = attachmentListeners.filter!(a => a !is null).array;
    }
  }

  /// Send the attachment to all listeners
  void attach(ref const Attachment attachment) {
    attachmentListeners.each!(a => a.attach(attachment));
  }

  /// Send the update event to all listeners
  void update() {
    lifecycleListeners.each!"a.update";
  }

  /// Send the begin run event to all listeners
  void begin(ulong testCount) {
    lifecycleListeners.each!(a => a.begin(testCount));
  }

  /// Send the end runer event to all listeners
  void end(SuiteResult[] result) {
    lifecycleListeners.each!(a => a.end(result));
  }

  /// Send the begin suite event to all listeners
  void begin(ref SuiteResult suite) {
    suiteListeners.each!(a => a.begin(suite));
  }

  /// Send the end suite event to all listeners
  void end(ref SuiteResult suite) {
    suiteListeners.each!(a => a.end(suite));
  }

  /// Send the begin test event to all listeners
  void begin(string suite, ref TestResult test) {
    currentTest = suite ~ "." ~ test.name;
    testListeners.each!(a => a.begin(suite, test));
  }

  /// Send the end test event to all listeners
  void end(string suite, ref TestResult test) {
    currentTest = "";
    testListeners.each!(a => a.end(suite, test));
  }

  /// Send the begin step event to all listeners
  void begin(string suite, string test, ref StepResult step) {
    currentTest = suite ~ "." ~ test ~ "." ~ step.name;
    stepListeners.each!(a => a.begin(suite, test, step));
  }

  /// Send the end step event to all listeners
  void end(string suite, string test, ref StepResult step) {
    currentTest = "";
    stepListeners.each!(a => a.end(suite, test, step));
  }

  /// Send the execute test to the executor listener
  SuiteResult[] execute(ref const(TestCase) func) {
    return executor.execute(func);
  }

  /// Send the begin execution with the test case list to the executor listener
  SuiteResult[] beginExecution(ref const(TestCase)[] tests) {
    return executor.beginExecution(tests);
  }

  /// Send the end execution the executor listener
  SuiteResult[] endExecution() {
    return executor.endExecution();
  }
}

/// It should return the name of this test


void setupSegmentationHandler(bool testRunner)()
{
  import core.runtime;

  // backtrace
  version( CRuntime_Glibc )
    import core.sys.linux.execinfo;
  else version( OSX )
    import core.sys.darwin.execinfo;
  else version( FreeBSD )
    import core.sys.freebsd.execinfo;
  else version( NetBSD )
    import core.sys.netbsd.execinfo;
  else version( Windows )
    import core.sys.windows.stacktrace;
  else version( Solaris )
    import core.sys.solaris.execinfo;

  static if( __traits( compiles, backtrace ) )
  {
    import core.sys.posix.signal; // segv handler

    static extern (C) void
SegvHandler(int signum, siginfo_t* info, void* ptr ) nothrow
    {
      import core.stdc.stdio;

      core.stdc.stdio.printf("\n\n");

      static if(testRunner) {
        if(signum == SIGSEGV) {
          core.stdc.stdio.printf("Got a Segmentation Fault running ");
        }

        if(signum == SIGBUS) {
          core.stdc.stdio.printf("Got a bus error running ");
        }


        if(LifeCycleListeners.instance.runningTest != "") {
          core.stdc.stdio.printf("%s\n\n", LifeCycleListeners.instance.runningTest.ptr);
        } else {
          core.stdc.stdio.printf("some setup step. This is probably a Trial bug. Please create an issue on github.\n\n");
        }
      } else {
        if(signum == SIGSEGV) {
          core.stdc.stdio.printf("Got a Segmentation Fault! ");
        }

        if(signum == SIGBUS) {
          core.stdc.stdio.printf("Got a bus error! ");
        }

        core.stdc.stdio.printf(" This is probably a Trial bug. Please create an issue on github.\n\n");
      }

      static enum MAXFRAMES = 128;
      void*[MAXFRAMES]  callstack;
      int               numframes;

      numframes = backtrace( callstack.ptr, MAXFRAMES );
      backtrace_symbols_fd( callstack.ptr, numframes, 2);
    }

    sigaction_t action = void;
    (cast(byte*) &action)[0 .. action.sizeof] = 0;
    sigfillset( &action.sa_mask ); // block other signals
    action.sa_flags = SA_SIGINFO | SA_RESETHAND;
    action.sa_sigaction = &
SegvHandler;
    sigaction( SIGSEGV, &action, null );
    sigaction( SIGBUS, &action, null );
  }
}/++
  A module containing the interfaces used for extending the test runner

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.datetime;
import std.algorithm;
import std.array;
import std.functional;
import std.conv;

/// Alias to a Test Case function type
alias TestCaseDelegate = void delegate() @system;
alias TestCaseFunction = void function() @system;

/// A Listener for the main test events
interface ILifecycleListener
{
  /// This method is trigered when before the test start
  void begin(ulong testCount);

  /**
   This method is triggered when you can perform some updates.
   The frequency varries by the test executor that you choose
   */
  void update();

  /// This method is trigered when your tests are ended
  void end(SuiteResult[]);
}

/// A listener that provides test cases to be executed
interface ITestDiscovery {
  TestCase[] getTestCases();
}

/**
A Listener that can run tests. During the test execution can be used only one
instance of this listance. After all the tests were executed the result of all
three methods are concatenated and passed to `ILifecycleListener.end(SuiteResult[])`
*/
interface ITestExecutor
{
  /// Called before all tests were discovered and they are ready to be executed
  SuiteResult[] beginExecution(ref const(TestCase)[]);

  /// Run a particullary test case
  SuiteResult[] execute(ref const(TestCase));

  /// Called when there is no more test to be executed
  SuiteResult[] endExecution();
}

/// A Listener for the suite events
interface ISuiteLifecycleListener
{
  /// Called before a suite execution
  void begin(ref SuiteResult);

  /// Called after a suite execution
  void end(ref SuiteResult);
}

/// A Listener for handling attachments
interface IAttachmentListener
{
  /// Called when an attachment is ready
  void attach(ref const Attachment);
}

/// A Listener for the test case events
interface ITestCaseLifecycleListener
{
  /// Called before a test execution
  void begin(string suite, ref TestResult);

  // Called after a test execution
  void end(string suite, ref TestResult);
}

/// A Listener for the step events
interface IStepLifecycleListener
{
  /// Called before a step begins
  void begin(string suite, string test, ref StepResult);

  /// Called after a step ended
  void end(string suite, string test, ref StepResult);
}

/// A struct representing a label for test results
struct Label {
  /// The label name
  string name;

  /// The label value
  string value;

  /// Convert the struct to a JSON string
  string toString() inout {
    return `{ "name": "` ~ name.escapeJson ~ `", "value": "` ~ value.escapeJson ~ `" }`;
  }
}

/// Label string representation should be in Json format


/// A struct representing an attachment for test steps
struct Attachment {
  /// The attachment name
  string name;

  /// The absolute path to the attachment
  string file;

  /// The file mime path
  string mime;

  /// Add a file to the current test or step
  static void fromFile(const string name, const string path, const string mime) {

    auto a = const Attachment(name, path, name);

    if(LifeCycleListeners.instance !is null) {
      LifeCycleListeners.instance.attach(a);
    }
  }
}

/// Represents a line of code in a certain file.
struct SourceLocation {
  ///
  string fileName;

  ///
  size_t line;

  /// Converts the structure to a JSON string
  string toString() inout {
    return `{ "fileName": "` ~ fileName.escapeJson ~ `", "line": ` ~ line.to!string ~ ` }`;
  }
}


/// SourceLocation string representation should be a JSON string


private string escapeJson(string value) {
  return value.replace(`"`, `\"`);
}

/// A test case that will be executed
struct TestCase
{
  /**
  The test case suite name. It can contain `.` which is treated as a
  separator for nested suites
  */
  string suiteName;

  /// The test name
  string name;

  /**
   The function that must be executed to check if the test passes or not.
   In case of failure, an exception is thrown.
  */
  TestCaseDelegate func;

  /**
    A list of labels that will be added to the final report
  */
  Label[] labels;

  /// The test location
  SourceLocation location;

  ///
  this(const TestCase testCase) {
    suiteName = testCase.suiteName.dup;
    name = testCase.name.dup;
    func = testCase.func;
    location = testCase.location;

    foreach(key, val; testCase.labels) {
      labels[key] = val;
    }
  }

  ///
  this(string suiteName, string name, TestCaseFunction func, Label[] labels = []) {
    this(suiteName, name, func.toDelegate, labels);
  }

  ///
  this(string suiteName, string name, TestCaseDelegate func, Label[] labels = []) {
    this.suiteName = suiteName;
    this.name = name;
    this.func = func;
    this.labels = labels;
  }

  string toString() const {
    string jsonRepresentation = "{ ";

    jsonRepresentation ~= `"suiteName": "` ~ suiteName.escapeJson ~ `", `;
    jsonRepresentation ~= `"name": "` ~ name.escapeJson ~ `", `;
    jsonRepresentation ~= `"labels": [ ` ~ labels.map!(a => a.toString).join(", ") ~ ` ], `;
    jsonRepresentation ~= `"location": ` ~ location.toString;

    return jsonRepresentation ~ " }";
  }
}

/// TestCase string representation should be a JSON string


///
TestResult toTestResult(const TestCase testCase) {
  auto testResult = new TestResult(testCase.name.dup);

  testResult.begin = Clock.currTime;
  testResult.end = testResult.begin;
  testResult.labels = testCase.labels.dup;
  testResult.fileName = testCase.location.fileName;
  testResult.line = testCase.location.line;

  return testResult;
}

/// A suite result
struct SuiteResult
{
  /**
  The suite name. It can contain `.` which is treated as a
  separator for nested suites
  */
  string name;

  /// when the suite started
  SysTime begin;

  /// when the suite ended
  SysTime end;

  /// the tests executed for the current suite
  TestResult[] tests;

  /// The list of attached files
  Attachment[] attachments;

  ///
  @disable
  this();

  ///
  this(string name) {
    this.name = name;
    begin = SysTime.fromUnixTime(0);
    end = SysTime.fromUnixTime(0);
  }

  ///
  this(string name, SysTime begin, SysTime end) {
    this.name = name;
    this.begin = begin;
    this.end = end;
  }

  ///
  this(string name, SysTime begin, SysTime end, TestResult[] tests) {
    this.name = name;
    this.begin = begin;
    this.end = end;
    this.tests = tests;
  }
}

/// A step result
class StepResult
{
  /// The step name
  string name;

  /// When the step started
  SysTime begin;

  /// When the step ended
  SysTime end;

  /// The list of the child steps
  StepResult[] steps;

  /// The list of attached files
  Attachment[] attachments;

  this() {
    begin = SysTime.min;
    end = SysTime.min;
  }
}

/// A test result
class TestResult : StepResult
{
  /// The states that a test can have.
  enum Status
  {
    ///
    created,
    ///
    failure,
    ///
    skip,
    ///
    started,
    ///
    success,
    ///
    unknown
  }

  /// The file that contains this test
  string fileName;

  /// The line where this test starts
  size_t line;

  /// Represents the test status
  Status status = Status.created;

  /**
    A list of labels that will be added to the final report
  */
  Label[] labels;

  /**
   The reason why a test has failed. This value must be set only if the tests has the
   `failure` state
   */
  Throwable throwable;

  /// Convenience constructor that sets the test name
  this(string name)
  {
    this.name = name;
    super();
  }
}


/// Convert a test case to test result








/// Attribute that marks the test as flaky. Different reporters will interpret this information
/// in different ways.
struct Flaky {

  /// Returns the labels that set the test a flaky
  static Label[] labels() {
    return [Label("status_details", "flaky")];
  }
}

/// Attribute that links an issue to a test. Some test reporters can display links, so the value can be also
/// a link.
struct Issue {

  private string name;

  /// Returns the labels that set the issue label
  Label[] labels() {
    return [ Label("issue", name) ];
  }
}

/// Attribute that sets the feaure label
struct Feature {
  private string name;

  /// Returns the labels that set the feature label
  Label[] labels() {
    return [ Label("feature", name) ];
  }
}

/// Attribute that sets the story label
struct Story {
  private string name;

  /// Returns the labels that set the feature label
  Label[] labels() {
    return [ Label("story", name) ];
  }
}

/// Attach the readme file
/++
  A module containing the parallel test runner

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/


import std.datetime;
import std.exception;
import std.algorithm;
import std.array;
import core.thread;

/// The Lifecycle listener used to send data from the tests threads to
/// the main thread
class ThreadLifeCycleListener : LifeCycleListeners {
  static string currentTest;

  override {
    void begin(string suite, string test, ref StepResult step) {
      ThreadProxy.instance.beginStep(currentTest, step.name, step.begin);
    }

    void end(string suite, string test, ref StepResult step) {
      ThreadProxy.instance.endStep(currentTest, step.name, step.end);
    }

    void end(string, ref TestResult test) {
      assert(false, "You can not call `end` outside of the main thread");
    }

    void begin(string, ref TestResult test) {
      assert(false, "You can not call `begin` outside of the main thread");
    }

    void add(T)(T listener) {
      assert(false, "You can not call `add` outside of the main thread");
    }

    void begin(ulong) {
      assert(false, "You can not call `begin` outside of the main thread");
    }

    void end(SuiteResult[] result) {
      assert(false, "You can not call `end` outside of the main thread");
    }

    void begin(ref SuiteResult suite) {
      assert(false, "You can not call `begin` outside of the main thread");
    }

    void end(ref SuiteResult suite) {
      assert(false, "You can not call `end` outside of the main thread");
    }

    SuiteResult[] execute(ref const(TestCase)) {
      assert(false, "You can not call `execute` outside of the main thread");
    }

    SuiteResult[] beginExecution(ref const(TestCase)[]) {
      assert(false, "You can not call `beginExecution` outside of the main thread");
    }

    SuiteResult[] endExecution() {
      assert(false, "You can not call `endExecution` outside of the main thread");
    }
  }
}

static ~this() {
  if(ThreadLifeCycleListener.currentTest != "") {
    ThreadProxy.instance.end(ThreadLifeCycleListener.currentTest);
  }
}

private {
  import core.atomic;

  struct StepAction {
    enum Type {
      begin,
      end
    }

    string test;
    string name;
    SysTime time;
    Type type;
  }

  synchronized class ThreadProxy {
    private shared static ThreadProxy _instance = new shared ThreadProxy;

    shared {
      private {
        string[] beginTests;
        string[] endTests;
        StepAction[] steps;
        Throwable[string] failures;
        ulong testCount;
      }

      static {
        shared(ThreadProxy) instance() {
          return _instance;
        }
      }

      void reset() {
        beginTests = [];
        endTests = [];
        steps = [];

        failures.clear;
        failures.rehash;

        testCount = 0;
      }

      void begin(string name) {
        beginTests ~= name;
      }

      void end(string name) {
        core.atomic.atomicOp!"+="(this.testCount, 1);
        endTests ~= name;
      }

      auto getTestCount() {
        return testCount;
      }

      void beginStep(shared(string) testName, string stepName, SysTime begin) {
        steps ~= StepAction(testName, stepName, begin, StepAction.Type.begin);
      }

      void endStep(shared(string) testName, string stepName, SysTime end) {
        steps ~= StepAction(testName, stepName, end, StepAction.Type.end);
      }

      void setFailure(string key, shared(Throwable) t) {
        failures[key] = t;
      }

      auto getStatus() {
        struct Status {
          string[] begin;
          StepAction[] steps;
          string[] end;
          Throwable[string] failures;
          ulong testCount;
        }

        auto status = shared Status(beginTests.dup, steps.dup, endTests.dup, failures, testCount);

        beginTests = [];
        steps = [];
        endTests = [];

        return status;
      }
    }
  }
}

private void testThreadSetup(string testName) {
  ThreadLifeCycleListener.currentTest = testName;
  LifeCycleListeners.instance = new ThreadLifeCycleListener;
  ThreadProxy.instance.begin(testName);
}

/// The parallel executors runs tests in a sepparate thread
class ParallelExecutor : ITestExecutor {
  struct SuiteStats {
    SuiteResult result;

    ulong testsFinished;
    bool isDone;
  }

  this(uint maxTestCount = 0) {
    this.maxTestCount = maxTestCount;

    if(this.maxTestCount <= 0) {
      import core.cpuid : threadsPerCPU;
      this.maxTestCount = threadsPerCPU;
    }
  }

  private {
    ulong testCount;
    uint maxTestCount;
    string currentSuite = "";

    SuiteStats[string] suiteStats;
    TestCase[string] testCases;

    StepResult[][string] stepStack;

    void addSuiteResult(string name) {
      suiteStats[name].result.begin = Clock.currTime;
      suiteStats[name].result.end = Clock.currTime;

      LifeCycleListeners.instance.begin(suiteStats[name].result);
    }

    void endSuiteResult(string name) {
      suiteStats[name].result.end = Clock.currTime;
      suiteStats[name].isDone = true;

      LifeCycleListeners.instance.end(suiteStats[name].result);
    }

    void addTestResult(string key) {
      auto testCase = testCases[key];

      if(currentSuite != testCase.suiteName) {
        addSuiteResult(testCase.suiteName);
        currentSuite = testCase.suiteName;
      }

      auto testResult = suiteStats[testCase.suiteName]
        .result
        .tests
        .filter!(a => a.name == testCase.name)
          .front;

      testResult.begin = Clock.currTime;
      testResult.end = Clock.currTime;
      testResult.status = TestResult.Status.started;

      LifeCycleListeners.instance.begin(testCase.suiteName, testResult);
      stepStack[key] = [ testResult ];
    }

    void endTestResult(string key, Throwable t) {
      auto testCase = testCases[key];

      auto testResult = suiteStats[testCase.suiteName]
        .result
        .tests
        .filter!(a => a.name == testCase.name)
          .front;

      testResult.end = Clock.currTime;
      testResult.status = t is null ? TestResult.Status.success : TestResult.Status.failure;
      testResult.throwable = t;

      suiteStats[testCases[key].suiteName].testsFinished++;

      LifeCycleListeners.instance.end(testCases[key].suiteName, testResult);
      stepStack.remove(key);
    }

    void addStep(string key, string name, SysTime time) {
      auto step = new StepResult;
      step.name = name;
      step.begin = time;
      step.end = time;

      stepStack[key][stepStack[key].length - 1].steps ~= step;
      stepStack[key] ~= step;

      LifeCycleListeners.instance.begin(testCases[key].suiteName, testCases[key].name, step);
    }

    void endStep(string key, string name, SysTime time) {
      auto step = stepStack[key][stepStack[key].length - 1];

      enforce(step.name == name, "unexpected step name");
      step.end = time;
      stepStack[key] ~= stepStack[key][0..$-1];

      LifeCycleListeners.instance.end(testCases[key].suiteName, testCases[key].name, step);
    }

    auto processEvents() {
      LifeCycleListeners.instance.update;

      auto status = ThreadProxy.instance.getStatus;

      foreach(beginKey; status.begin) {
        addTestResult(beginKey);
      }

      foreach(step; status.steps) {
        if(step.type == StepAction.Type.begin) {
          addStep(step.test, step.name, step.time);
        }

        if(step.type == StepAction.Type.end) {
          endStep(step.test, step.name, step.time);
        }
      }

      foreach(endKey; status.end) {
        Throwable failure = null;

        if(endKey in status.failures) {
          failure = cast() status.failures[endKey];
        }

        endTestResult(endKey, failure);
      }

      foreach(ref index, ref stat; suiteStats.values) {
        if(!stat.isDone && stat.result.tests.length == stat.testsFinished) {
          endSuiteResult(stat.result.name);
        }
      }

      return status.testCount;
    }

    void wait() {
      ulong executedTestCount;

      do {
        LifeCycleListeners.instance.update();
        executedTestCount = processEvents;
        Thread.sleep(1.msecs);
      } while(executedTestCount < testCount);
    }
  }

  SuiteResult[] execute(ref const(TestCase) testCase) {
    import std.parallelism;

    SuiteResult[] result;

    auto key = testCase.suiteName ~ "|" ~ testCase.name;
    testCases[key] = TestCase(testCase);

    testCount++;

    task({
      testThreadSetup(key);

      try {
        testCase.func();
      } catch(Throwable t) {
        ThreadProxy.instance.setFailure(key, cast(shared)t);
      }
    }).executeInNewThread();

    auto runningTests = testCount - ThreadProxy.instance.getTestCount;

    while(maxTestCount <= runningTests && runningTests > 0) {
      processEvents;
      runningTests = testCount - ThreadProxy.instance.getTestCount;
    }

    return result;
  }

  SuiteResult[] beginExecution(ref const(TestCase)[] tests) {
    foreach(test; tests) {
      auto const suite = test.suiteName;
      if(suite !in suiteStats) {
        suiteStats[suite] = SuiteStats(SuiteResult(suite));
      }

      suiteStats[suite].result.tests ~= new TestResult(test.name);
    }

    ThreadProxy.instance.reset();
    return [];
  }

  SuiteResult[] endExecution() {
    wait;

    foreach(stat; suiteStats.values) {
      if(!stat.isDone) {
        endSuiteResult(stat.result.name);
      }
    }

    SuiteResult[] results;

    foreach(stat; suiteStats) {
      results ~= stat.result;
    }

    return results;
  }
}






/++
  A module containing the single threaded runner

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.datetime;

/**
The default test executor runs test in sequential order in a single thread
*/
class DefaultExecutor : ITestExecutor, IStepLifecycleListener, IAttachmentListener
{
  private
  {
    SuiteResult suiteResult;
    TestResult testResult;
    StepResult currentStep;
    StepResult[] stepStack;
  }

  this() {
    suiteResult = SuiteResult("unknown");
  }

  /// Called when an attachment is ready
  void attach(ref const Attachment attachment) {
    if(currentStep is null) {
      suiteResult.attachments ~= Attachment(attachment.name, attachment.file, attachment.mime);
      return;
    }

    currentStep.attachments ~= Attachment(attachment.name, attachment.file, attachment.mime);
  }

  /// Add the step result and update the other listeners on every step
  void begin(string suite, string test, ref StepResult step)
  {
    currentStep.steps ~= step;
    stepStack ~= currentStep;
    currentStep = step;
    LifeCycleListeners.instance.update();
  }

  /// Update the other listeners on every step
  void end(string suite, string test, ref StepResult step)
  {
    currentStep = stepStack[stepStack.length - 1];
    stepStack = stepStack[0 .. $ - 1];
    LifeCycleListeners.instance.update();
  }

  /// It does nothing
  SuiteResult[] beginExecution(ref const(TestCase)[])
  {
    return [];
  }

  /// Return the result for the last executed suite
  SuiteResult[] endExecution()
  {
    if (suiteResult.begin == SysTime.fromUnixTime(0))
    {
      return [];
    }

    LifeCycleListeners.instance.update();
    LifeCycleListeners.instance.end(suiteResult);
    return [suiteResult];
  }

  private
  {
    void createTestResult(const(TestCase) testCase)
    {
      testResult = testCase.toTestResult;
      testResult.status = TestResult.Status.started;
      currentStep = testResult;

      stepStack = [];

      Step.suite = testCase.suiteName;
      Step.test = testCase.name;

      LifeCycleListeners.instance.begin(testCase.suiteName, testResult);

      try
      {
        testCase.func();
        testResult.status = TestResult.Status.success;
      }
      catch (Throwable t)
      {
        testResult.status = TestResult.Status.failure;
        testResult.throwable = t.toTestException;
      }

      testResult.end = Clock.currTime;

      LifeCycleListeners.instance.end(testCase.suiteName, testResult);
    }
  }

  /// Execute a test case
  SuiteResult[] execute(ref const(TestCase) testCase)
  {
    SuiteResult[] result;
    LifeCycleListeners.instance.update();

    if (suiteResult.name != testCase.suiteName)
    {
      if (suiteResult.begin != SysTime.fromUnixTime(0))
      {
        suiteResult.end = Clock.currTime;
        LifeCycleListeners.instance.end(suiteResult);
        result = [suiteResult];
      }

      suiteResult = SuiteResult(testCase.suiteName, Clock.currTime, Clock.currTime);
      LifeCycleListeners.instance.begin(suiteResult);
    }

    createTestResult(testCase);
    suiteResult.tests ~= testResult;
    currentStep = null;
    LifeCycleListeners.instance.update();

    return result;
  }
}
/++
  A module containing the default test discovery logic

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.stdio;
import std.string;
import std.traits;
import std.conv;
import std.array;
import std.file;
import std.algorithm;
import std.range;
import std.typecons;


enum CommentType {
	none,
	begin,
	end,
	comment
}

CommentType commentType(T)(T line) {
	if(line.length < 2) {
		return CommentType.none;
	}

	if(line[0..2] == "//") {
		return CommentType.comment;
	}

	if(line[0..2] == "/+" || line[0..2] == "/*") {
		return CommentType.begin;
	}

	if(line.indexOf("+/") != -1 || line.indexOf("*/") != -1) {
		return CommentType.end;
	}

	return CommentType.none;
}


struct Comment {
	ulong line;
	string value;
}

Comment[] commentGroupToString(T)(T[] group) {
	if(group.front[1] == CommentType.comment) {
		auto slice = group.until!(a => a[1] != CommentType.comment).array;

		string value = slice
			.map!(a => a[2].stripLeft('/').array.to!string)
			.map!(a => a.strip)
			.join(' ')
			.array.to!string;

		return [ Comment(slice[slice.length - 1][0], value) ];
	}

	if(group.front[1] == CommentType.begin) {
		auto ch = group.front[2][1];
		auto index = 0;

		auto newGroup = group
		.map!(a => Tuple!(int, CommentType, immutable(char), string)(a[0], a[1], a[2].length > 2 ? a[2][1] : ' ', a[2])).array;

		foreach(item; newGroup) {
			index++;
			if(item[1] == CommentType.end && item[2] == ch) {
				break;
			}
		}

		auto slice = group
			.map!(a => Tuple!(int, CommentType, immutable(char), string)(a[0], a[1], a[2].length > 2 ? a[2][1] : ' ', a[2]))
			.take(index);

		string value = slice
			.map!(a => a[3].strip)
			.map!(a => a.stripLeft('/').stripLeft(ch).array.to!string)
			.map!(a => a.strip)
			.join(' ')
			.until(ch ~ "/")
			.array
			.stripRight('/')
			.stripRight(ch)
			.strip
			.to!string;

		return [ Comment(slice[slice.length - 1][0], value) ];
	}

	return [];
}

string getComment(const Comment[] comments, const ulong line, const string defaultValue) pure {
	auto r = comments.filter!(a => (line - a.line) < 3);

	return r.empty ? defaultValue : r.front.value;
}

bool connects(T)(T a, T b) {
	auto items = a[0] < b[0] ? [a, b] : [b, a];

	if(items[1][0] - items[0][0] != 1) {
		return false;
	}

	if(a[1] == b[1]) {
		return true;
	}

	if(items[0][1] != CommentType.end && items[1][1] != CommentType.begin) {
		return true;
	}

	return false;
}


auto compressComments(string code)
{
	Comment[] result;

	auto lines = code
		.splitter("\n")
		.map!(a => a.strip)
		.enumerate(1)
		.map!(a => Tuple!(int, CommentType, string)(a[0], a[1].commentType, a[1]))
		.filter!(a => a[2] != "")
			.array;

	auto tmp = [ lines[0] ];
	auto prev = lines[0];

	foreach(line; lines[1..$]) {
		if(tmp.length == 0 || line.connects(tmp[tmp.length - 1])) {
			tmp ~= line;
		} else {
			result ~= tmp.commentGroupToString;
			tmp = [ line ];
		}
	}

	if(tmp.length > 0) {
		result ~= tmp.commentGroupToString;
	}

	return result;
}

/// The default test discovery looks for unit test sections and groups them by module
class UnitTestDiscovery : ITestDiscovery {
	TestCase[string][string] testCases;

	TestCase[] getTestCases() {
		return testCases.values.map!(a => a.values).joiner.array;
	}

	void addModule(string file, string moduleName)()
	{
		mixin("import " ~ moduleName ~ ";");
		mixin("discover!(`" ~ file ~ "`, `" ~ moduleName ~ "`, " ~ moduleName ~ ")();");
	}

	private {
		string testName(alias test)(ref Comment[] comments) {
			string defaultName = test.stringof.to!string;
			string name = defaultName;

			foreach (attr; __traits(getAttributes, test)) {
				static if (is(typeof(attr) == string)) {
					name = attr;
				}
			}

			enum key = "__un" ~ "ittestL";
			enum len = key.length;

			if(name == defaultName && name.indexOf(key) == 0) {
				try {
					auto postFix = name[len..$];
					auto idx = postFix.indexOf("_");
					if(idx != -1) {
						auto line = postFix[0..idx].to!long;
						name = comments.getComment(line, defaultName);
					}
				} catch(Exception e) { }
			}

			return name;
		}

		SourceLocation testSourceLocation(alias test)(string fileName) {
			string name = test.stringof.to!string;

			enum key = "__un" ~ "ittestL";
			enum len = key.length;
			size_t line;

			try {
				auto postFix = name[len..$];
				auto idx = postFix.indexOf("_");

				if(idx != -1) {
					line = postFix[0..idx].to!size_t;
				}
			} catch(Exception e) {
				return SourceLocation();
			}

			return SourceLocation(fileName, line);
		}

		Label[] testLabels(alias test)() {
			Label[] labels;

			foreach (attr; __traits(getAttributes, test)) {
				static if (__traits(hasMember, attr, "labels")) {
					labels ~= attr.labels;
				}
			}

			return labels;
		}

		auto addTestCases(string file, alias moduleName, composite...)() if (composite.length == 1 && isUnitTestContainer!(composite))
		{
			Comment[] comments = file.readText.compressComments;

			foreach (test; __traits(getUnitTests, composite)) {
				auto testCase = TestCase(moduleName, testName!(test)(comments), {
					test();
				}, testLabels!(test));

				testCase.location = testSourceLocation!test(file);

				testCases[moduleName][test.mangleof] = testCase;
			}
		}

		void discover(string file, alias moduleName, composite...)() if (composite.length == 1 && isUnitTestContainer!(composite))
		{
			addTestCases!(file, moduleName, composite);

			static if (isUnitTestContainer!composite) {
				foreach (member; __traits(allMembers, composite)) {
					static if (
						__traits(compiles, __traits(getMember, composite, member)) &&
						isSingleField!(__traits(getMember, composite, member)) &&
						isUnitTestContainer!(__traits(getMember, composite, member)) &&
						!isModule!(__traits(getMember, composite, member))
						)
					{
						if (__traits(getMember, composite, member).mangleof !in testCases)
						{
							discover!(file, moduleName, __traits(getMember, composite, member))();
						}
					}
				}
			}
		}
	}
}

private template isUnitTestContainer(DECL...)
	if (DECL.length == 1)
{
	static if (!isAccessible!DECL) {
		enum isUnitTestContainer = false;
	} else static if (is(FunctionTypeOf!(DECL[0]))) {
		enum isUnitTestContainer = false;
	} else static if (is(DECL[0]) && !isAggregateType!(DECL[0])) {
		enum isUnitTestContainer = false;
	} else static if (isPackage!(DECL[0])) {
		enum isUnitTestContainer = false;
	} else static if (isModule!(DECL[0])) {
		enum isUnitTestContainer = DECL[0].stringof != "module object";
	} else static if (!__traits(compiles, fullyQualifiedName!(DECL[0]))) {
		enum isUnitTestContainer = false;
	} else static if (!is(typeof(__traits(allMembers, DECL[0])))) {
		enum isUnitTestContainer = false;
	} else {
		enum isUnitTestContainer = true;
	}
}

private template isModule(DECL...)
	if (DECL.length == 1)
{
	static if (is(DECL[0])) enum isModule = false;
	else static if (is(typeof(DECL[0])) && !is(typeof(DECL[0]) == void)) enum isModule = false;
	else static if (!is(typeof(DECL[0].stringof))) enum isModule = false;
	else static if (is(FunctionTypeOf!(DECL[0]))) enum isModule = false;
	else enum isModule = DECL[0].stringof.startsWith("module ");
}

private template isPackage(DECL...)
	if (DECL.length == 1)
{
	static if (is(DECL[0])) enum isPackage = false;
	else static if (is(typeof(DECL[0])) && !is(typeof(DECL[0]) == void)) enum isPackage = false;
	else static if (!is(typeof(DECL[0].stringof))) enum isPackage = false;
	else static if (is(FunctionTypeOf!(DECL[0]))) enum isPackage = false;
	else enum isPackage = DECL[0].stringof.startsWith("package ");
}

private template isAccessible(DECL...)
	if (DECL.length == 1)
{
	enum isAccessible = __traits(compiles, testTempl!(DECL[0])());
}

private template isSingleField(DECL...)
{
	enum isSingleField = DECL.length == 1;
}

private void testTempl(X...)()
	if (X.length == 1)
{
	static if (is(X[0])) {
		auto x = X[0].init;
	} else {
		auto x = X[0].stringof;
	}
}


/// It should find this test


/// It should find this flaky test
@Flaky


/// It should find the line of this test


/// It should find this test with issues attributes
@Issue("1") @Issue("2")


import std.algorithm;
import std.string;
import std.range;
import std.file;
import std.stdio;
import std.conv;

/// Get the module name of a DLang source file
string getModuleName(string fileName) {
	if(!exists(fileName)) {
		return "";
	}

	if(isDir(fileName)) {
		return "";
	}

	auto file = File(fileName);

	auto moduleLine = file.byLine()
		.map!(a => a.to!string)
		.filter!(a => a.startsWith("module"));

	if(moduleLine.empty) {
		return "";
	}

	return moduleLine.front.split(' ')[1].split(";")[0];
}/++
  A module containing the discovery logic for spec tests

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.algorithm;
import std.stdio;
import std.array;
import std.traits;


alias SetupFunction = void delegate() @safe;

private string[] suitePath;
private ulong[string] testsPerSuite;
private TestCase[] testCases;
private SetupFunction[] beforeList;
private SetupFunction[] afterList;

/// Define a Spec test suite
void describe(T)(string name, T description)
{
  if(suitePath.length == 0) {
    suitePath = [ moduleName!description ];
  }

  auto beforeListIndex = beforeList.length;
  auto afterListIndex = afterList.length;

  suitePath ~= name;

  description();

  beforeList = beforeList[0..beforeListIndex];
  afterList = afterList[0..afterListIndex];

  suitePath = suitePath[0 .. $-1];
}

/// Define a function that will be ran before all the tests
void before(T)(T setup) {
  bool wasRun;
  beforeList ~= {
    if(!wasRun) {
      setup();
      wasRun = true;
    }
  };
}

/// Define a function that will be ran before each test
void beforeEach(T)(T setup) {
  beforeList ~= {
    setup();
  };
}

/// Define a function that will be ran after each test
void afterEach(T)(T setup) {
  afterList ~= {
    setup();
  };
}

/// Define a function that will be ran after all the tests were ran
void after(T)(T setup) {
  string suiteName = suitePath.join(".");
  long executedTests;
  bool wasRun;

  afterList ~= {
    if(wasRun) {
      return;
    }

    executedTests++;

    if(testsPerSuite[suiteName] < executedTests) {
      setup();
      wasRun = true;
    }
  };
}

private void updateTestCounter(string[] path, long value) {
  string tmp;
  string glue;

  foreach(key; path) {
    tmp ~= glue ~ key;
    glue = ".";

    testsPerSuite[tmp] += value;
  }
}

/// Define a Spec
void it(T)(string name, T test, string file = __FILE__, size_t line = __LINE__)
{
  auto before = beforeList.dup;
  auto after = afterList.dup;
  auto path = suitePath.dup;

  reverse(after);

  updateTestCounter(path, 1);

  auto testCase = TestCase(suitePath.join("."), name, ({
    before.each!"a()";
    test();

    updateTestCounter(path, -1);
    after.each!"a()";
  }));

  testCase.location = SourceLocation(file, line);

  testCases ~= testCase;
}

/// The main spec container
template Spec(alias definition)
{
  shared static this() {
    definition();
  }
}

/// The default test discovery looks for unit test sections and groups them by module
class SpecTestDiscovery : ITestDiscovery
{
  /// Returns all the Specs as TestCase structure
  TestCase[] getTestCases() {
    return testCases;
  }


  /// It does nothing...
  void addModule(string file, string moduleName)() {}
}


/// It should find the spec suite


/// It should find nested spec suites


/// It should execute the spec before all hooks


/// It should execute the spec after all hooks


/// It should execute the spec before hooks


/// It should execute the spec after hooks


/++
  A module containing the discovery logic for classes annodated with @Test

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.meta;
import std.traits;
import std.uni;
import std.conv;
import std.string;
import std.algorithm;
import std.random;


/// A structure that stores data about the setup events(methods)
struct SetupEvent {
  string name;

  TestSetupAttribute setup;
  TestCaseFunction func;
}

private {
  SetupEvent[][string] setupMethods;
  Object[string] testClassInstances;
  size_t[string] testMethodCount;
  size_t[string] testMethodExecuted;
}

private void methodDone(string ModuleName, string ClassName)() {
  enum key = ModuleName ~ "." ~ ClassName;

  testMethodExecuted[key]++;

  if(testMethodExecuted[key] >= testMethodCount[key]) {
    if(key in setupMethods) {
      foreach(setupMethod; setupMethods[key].filter!(a => a.setup.afterAll)) {
        setupMethod.func();
      }
    }

    testClassInstances.remove(key);
  }
}

private auto getTestClassInstance(string ModuleName, string ClassName)() {
  enum key = ModuleName ~ "." ~ ClassName;

  if(key !in testClassInstances) {
    mixin(`import ` ~ ModuleName ~ `;`);
    mixin(`auto instance = new ` ~ ClassName ~ `();`);

    testClassInstances[key] = instance;
    testMethodExecuted[key] = 0;

    if(key in setupMethods) {
      foreach(setupMethod; setupMethods[key].filter!(a => a.setup.beforeAll)) {
        setupMethod.func();
      }
    }
  }

  mixin(`return cast(` ~ key ~ `) testClassInstances[key];`);
}

/// The default test discovery looks for unit test sections and groups them by module
class TestClassDiscovery : ITestDiscovery {
  private TestCase[] list;

  /// Returns all the test cases that were found in the modules
  /// added with `addModule`
  TestCase[] getTestCases() {
    return list;
  }

  /// Add tests from a certain module
  void addModule(string file, string moduleName)()
  {
    discover!moduleName;
  }

  private {
    void discover(string ModuleName)() {
      mixin("import " ~ ModuleName ~ ";");
      enum classList = classMembers!(ModuleName);

      foreach(className; classList) {
        mixin("alias CurrentClass = " ~ ModuleName ~ "." ~ className ~ ";");

        enum members = __traits(allMembers, CurrentClass);

        foreach(member; members) {
          static if(isSetupMember!(ModuleName, className, member)) {
            enum setup = getSetup!(ModuleName, className, member);
            enum key = ModuleName ~ "." ~ className;

            auto exists = key in setupMethods && !setupMethods[key].filter!(a => a.name == member).empty;

            if(!exists) {
              setupMethods[key] ~= SetupEvent(member, setup, ({
                mixin(`auto instance = new ` ~ className ~ `();`);
                mixin(`instance.` ~ member ~ `;`);
              }));
            }
          }
        }
      }

      foreach(className; classList) {
        enum key = ModuleName ~ "." ~ className;
        mixin("alias CurrentClass = " ~ key ~ ";");

        enum members = __traits(allMembers, CurrentClass);
        testMethodCount[key] = 0;

        foreach(member; members) {
          static if(isTestMember!(ModuleName, className, member)) {
            testMethodCount[key]++;
            string testName = getTestName!(ModuleName, className, member);

            auto testCase = TestCase(ModuleName ~ "." ~ className, testName, ({
              auto instance = getTestClassInstance!(ModuleName, className);

              enum key = ModuleName ~ "." ~ className;

              if(key in setupMethods) {
                foreach(setupMethod; setupMethods[key].filter!(a => a.setup.beforeEach)) {
                  setupMethod.func();
                }
              }

              mixin(`instance.` ~ member ~ `;`);

              if(key in setupMethods) {
                foreach(setupMethod; setupMethods[key].filter!(a => a.setup.afterEach)) {
                  setupMethod.func();
                }
              }

              methodDone!(ModuleName, className);
            }), [ ]);

            testCase.location = getTestLocation!(ModuleName, className, member);

            list ~= testCase;
          }
        }
      }
    }
  }
}

///
string getTestName(string ModuleName, string className, string member)() {
  mixin("import " ~ ModuleName ~ ";");
  mixin("enum attributes = __traits(getAttributes, " ~ ModuleName ~ "." ~ className ~ "." ~ member ~ ");");

  enum testAttributes = testAttributes!attributes;

  string name;

  foreach(attribute; attributes) {
    static if(is(typeof(attribute) == string)) {
      name = attribute;
    }
  }

  if(name.length == 0) {
    return member.camelToSentence;
  } else {
    return name;
  }
}


///
SourceLocation getTestLocation(string ModuleName, string className, string member)() {
  mixin("import " ~ ModuleName ~ ";");
  mixin("enum attributes = __traits(getAttributes, " ~ ModuleName ~ "." ~ className ~ "." ~ member ~ ");");

  enum testAttributes = testAttributes!attributes;

  return SourceLocation(testAttributes[0].file, testAttributes[0].line);
}

///
auto getSetup(string ModuleName, string className, string member)() {
  mixin("import " ~ ModuleName ~ ";");
  mixin("enum attributes = __traits(getAttributes, " ~ ModuleName ~ "." ~ className ~ "." ~ member ~ ");");

  return setupAttributes!attributes[0];
}

/// Converts a string from camel notation to a readable sentence
string camelToSentence(const string name) pure {
  string sentence;

  foreach(ch; name) {
    if(ch.toUpper == ch) {
      sentence ~= " " ~ ch.toLower.to!string;
    } else {
      sentence ~= ch;
    }
  }

  return sentence.capitalize;
}

///
bool isTestMember(string ModuleName, string className, string member)() {
  mixin("import " ~ ModuleName ~ ";");
  mixin("enum attributes = __traits(getAttributes, " ~ ModuleName ~ "." ~ className ~ "." ~ member ~ ");");

  return testAttributes!attributes.length > 0;
}

///
bool isSetupMember(string ModuleName, string className, string member)() {
  mixin("import " ~ ModuleName ~ ";");
  mixin("enum attributes = __traits(getAttributes, " ~ ModuleName ~ "." ~ className ~ "." ~ member ~ ");");

  return setupAttributes!attributes.length > 0;
}

///
template isClass(string name)
{
  mixin("
    static if (is(" ~ name ~ " == class))
      enum bool isClass = true;
    else
      enum bool isClass = false;");
}

///
template isTestAttribute(alias Attribute)
{

  static if(!is(CommonType!(Attribute, TestAttribute) == void)) {
    enum bool isTestAttribute = true;
  } else {
    enum bool isTestAttribute = false;
  }
}

///
template isRightParameter(string parameterName) {
  template isRightParameter(alias Attribute) {
    enum isRightParameter = Attribute.parameterName == parameterName;
  }
}

///
template isSetupAttribute(alias Attribute)
{
  static if(!is(CommonType!(Attribute, TestSetupAttribute) == void)) {
    enum bool isSetupAttribute = true;
  } else {
    enum bool isSetupAttribute = false;
  }
}

///
template isValueProvider(alias Attribute) {
  static if(__traits(hasMember, Attribute, "provide") && __traits(hasMember, Attribute, "parameterName")) {
    enum bool isValueProvider = true;
  } else {
    enum bool isValueProvider = false;
  }
}

///
template extractClasses(string moduleName, members...)
{
  alias Filter!(isClass,members) extractClasses;
}

///
template extractValueProviders(Elements...)
{
  alias Filter!(isValueProvider, Elements) extractValueProviders;
}

///
template testAttributes(attributes...)
{
  alias Filter!(isTestAttribute, attributes) testAttributes;
}

///
template setupAttributes(attributes...)
{
  alias Filter!(isSetupAttribute, attributes) setupAttributes;
}

///
template classMembers(string moduleName)
{
  mixin("alias extractClasses!(moduleName, __traits(allMembers, " ~ moduleName ~ ")) classMembers;");
}


/// It should find the Test Suite class


/// It should execute tests from a Test Suite class


/// It should execute the before and after methods tests from a Test Suite class


private string generateRandomParameters(alias T, int index)() pure nothrow {
  alias paramTypes = Parameters!T;
  enum params = ParameterIdentifierTuple!T;
  alias providers = Filter!(isRightParameter!(params[index].stringof[1..$-1]), extractValueProviders!(__traits(getAttributes, T)));

  enum provider = "Filter!(isRightParameter!(" ~ params[index].stringof ~ "), extractValueProviders!(__traits(getAttributes, T)))";

  static if(providers.length > 0) {
    immutable string definition = "auto param_" ~ params[index] ~ " = " ~ provider ~ "[0]().provide; ";
  } else {
    immutable string definition = "auto param_" ~ params[index] ~ " = uniform!" ~ paramTypes[index].stringof ~ "(); ";
  }

  static if(index == 0) {
    return definition;
  } else {
    return definition ~ generateRandomParameters!(T, index-1);
  }
}

private string generateMethodParameters(alias T, int size)() {
  enum params = ParameterIdentifierTuple!T;

  static if(size == 0) {
    return "";
  } else static if(size == 1) {
    return "param_" ~ params[0];
  } else {
    return generateMethodParameters!(T, size - 1) ~ ", param_" ~ params[size - 1];
  }
}

/// Call a method using the right data provders
void methodCaller(alias T, U)(U func) {
  enum parameterCount = arity!T;

  mixin(generateRandomParameters!(T, parameterCount - 1));
  mixin("func(" ~ generateMethodParameters!(T, parameterCount) ~ ");");
}

/// methodCaller should call the method with random numeric values


struct ValueProvider(string name, alias T) {
  immutable static string parameterName = name;

  auto provide() {
    return T();
  }
}

auto For(string name, alias T)() {
  return ValueProvider!(name, T)();
}


/// methodCaller should call the method with custom random generators
/++
  Settings parser and structures

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/
import std.conv;


version(Have_dub) {
  import dub.internal.vibecompat.data.serialization;
}
///
mixin template SettingsFields()
{
  /*
  bool colors;
  bool sort;
  bool bail;*/

  /** The reporter list that will be added by the runner at startup
   * You can use here only the embeded reporters.
   * If you want to use a custom reporter you can use `static this` constructor
   *
   * Examples:
   * ------------------------
   * static this
   * {
   *    LifeCycleListeners.instance.add(myCustomReporter);
   * }
   * ------------------------
   */
  string[] reporters = ["spec", "result"];

  /// The test discovery classes that you want to use
  string[] testDiscovery = ["trial.discovery.unit.UnitTestDiscovery"];

  /// The default executor is `SingleRunner`. If you want to use the
  /// `ParallelExecutor` set this flag true.
  bool runInParallel = false;

  /// The number of threads tha you want to use
  /// `0` means the number of cores that your processor has
  uint maxThreads = 0;

  ///
  GlyphSettings glyphs;
}

/// A structure representing the `trial.json` file
struct Settings
{
  version(Have_dub) {
    @optional {
      mixin SettingsFields;
    }
  } else {
    mixin SettingsFields;
  }
}

mixin template GlyphSettingsFields()
{
  ///
  SpecGlyphs spec;

  ///
  SpecStepsGlyphs specSteps;

  ///
  ResultGlyphs result;

  ///
  DotMatrixGlyphs dotMatrix;

  ///
  LandingGlyphs landing;

  ///
  ProgressGlyphs progress;
}

/// The gliph settings
struct GlyphSettings {
  version(Have_dub) {
    @optional {
      mixin GlyphSettingsFields;
    }
  } else {
    mixin GlyphSettingsFields;
  }
}

/// Converts the settings object to DLang code. It's used by the generator
string toCode(Settings settings)
{
  return "Settings(" ~
    settings.reporters.to!string ~ ", " ~
    settings.testDiscovery.to!string ~ ", " ~
    settings.runInParallel.to!string ~ ", " ~
    settings.maxThreads.to!string ~ ", " ~
    settings.glyphs.toCode ~
    ")";
}

/// Converts the GlyphSettings object to DLang code. It's used by the generator
string toCode(GlyphSettings settings) {
  return "GlyphSettings(" ~
      specGlyphsToCode(settings.spec) ~ ", " ~
      specStepsGlyphsToCode(settings.specSteps) ~ ", " ~
      resultGlyphsToCode(settings.result) ~ ", " ~
      dotMatrixGlyphsToCode(settings.dotMatrix) ~ ", " ~
      landingGlyphsToCode(settings.landing) ~ ", " ~
      progressGlyphsToCode(settings.progress) ~
    ")";
}


/// it should be able to compile the settings code


/// it should be able to transform  the Settings to code.

/++
  When you run complex tests, or tests that take a lot of time, it helps
  to mark certain areas as steps, to ease the debug or to improve the report.

  A good usage is for running BDD tests where a step can be steps from the
  `Gherkin Syntax` or UI Automation tests.

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.datetime;
import std.stdio;

/** A stepstructure. Creating a Step will automatically be added to the current step as a child
  * The steps can be nested to allow you to group steps as with meanigful names.
  *
  * The steps ends when the Struct is destroyed. In order to have a step that represents a method
  * assign it to a local variable
  *
  * Examples:
  * ------------------------
  * void TestSetup() @system
  * {
  *   auto aStep = Step("Given some precondition");
  *
  *   Step("Some setup");
  *   performSomeSetup();
  *
  *   Step("Other setup");
  *   performOtherSetup();
  * }
  * // will create this tree:
  * // Test
  * //  |
  * //  +- Given some precondition
  * //        |
  * //        +- Some setup
  * //        +- Other setup
  * ------------------------
  */
struct Step
{
  static {
    /// The current suite name. Do not alter this global variable
    string suite;
    /// The current test name. Do not alter this global variable
    string test;
  }

  @disable
  this();

  private {
    StepResult step;
  }

  /// Create and attach a step
  this(string name) {
    step = new StepResult;
    step.name = name;
    step.begin = Clock.currTime;
    step.end = Clock.currTime;

    if(LifeCycleListeners.instance is null) {
      writeln("Warning! Can not set steps if the LifeCycleListeners.instance is not set.");
      return;
    }

    LifeCycleListeners.instance.begin(suite, test, step);
  }

  /// Mark the test as finished
  ~this() {
    if(LifeCycleListeners.instance is null) {
      writeln("Warning! Can not set steps if the LifeCycleListeners.instance is not set.");
      return;
    }

    step.end = Clock.currTime;
    LifeCycleListeners.instance.end(suite, test, step);
  }
}
/++
  A module containing the logic for parsing and analysing the code coverage

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.algorithm;
import std.range;
import std.string;
import std.stdio;
import std.conv;
import std.exception;
import std.file;
import std.path;
import std.math;


shared static this() {
  import core.runtime;

  if(exists("coverage")) {
    rmdirRecurse("coverage");
  }

  mkdirRecurse(buildPath("coverage", "raw"));

  dmd_coverDestPath(buildPath("coverage", "raw"));
}

/// Converts coverage lst files to html
double convertLstFiles(string packagePath, string packageName) {
  if(!exists(buildPath("coverage", "html"))) {
    mkdirRecurse(buildPath("coverage", "html"));
  }

  std.file.write(buildPath("coverage", "html", "coverage.css"), `body, html {
  height: 100%;
}

header {
  background-color: #FFF;
  border-bottom: 1px solid #777;
  padding: 10px;
}

header .progress {
  max-width: 300px;
}

header .progress .progress-bar {
  min-width: 2em;
}

main {
  display: block;
  margin: 0;
}

figure {
  display: block;
  margin: 0;
  width: 100%;
}

figure figcaption {
  display: block;
  font-family: sans-serif;
  padding: 5px 10px 4px 10px;
  border-radius: 3px 3px 0 0;
  font-weight: bold;
}

pre {
  overflow: visible;
  padding: 0;
  margin: 0;
  font-size: 14px;
  word-break: break-all;
  word-wrap: break-word;
  background-color: transparent;
  border: 0;
  border-radius: 0;
  line-height: 1.5;
  width: 100%;
}

.code-container {
  position: relative;
}

.coverage-container {
  position: absolute;
  left: 0;
  top: 0;
  width: 100px;
  font: inherit;
}

.code-container code {
  position: absolute;
  left: 100px;
  top: 0;
  width: calc(100% - 50px);
}

code.hljs {
    padding-top: 0;

    font-size: inherit;
    line-height: inherit;
    width: calc(100% - 100px);

    white-space: pre;
}

pre .line {
  font: inherit;
  color: #777;
  overflow: hidden;
  position: relative;

  border-right: 3px solid #ccc;
  padding-left: 5px;
}

pre .line .hit-count {
  opacity: 0;
}

pre .line.has-code .hit-count {
  display: block;
  position: absolute;
  opacity: 1;
  top: 0;
  right: 3px;
  color: #0000cc;
}

pre .line.has-code {
  border-right: 3px solid #ff0000;
}

pre .line.has-code.hit {
  border-right: 3px solid #00aa00;
}`);

  auto coverageData =
    dirEntries(buildPath("coverage", "raw"), SpanMode.shallow)
    .filter!(f => f.name.endsWith(".lst"))
    .filter!(f => f.isFile)
    .map!(a => readText(a.name))
    .map!(a => a.toCoverageFile(packagePath)).array;

  std.file.write(buildPath("coverage", "html", "coverage-shield.svg"), coverageShield(coverageData.filter!"a.isInCurrentProject".array.coveragePercent.to!int.to!string));
  std.file.write(buildPath("coverage", "html", "index.html"), coverageData.toHtmlIndex(packageName));

  foreach (data; coverageData) {
    auto htmlFile = data.path.toCoverageHtmlFileName;

    std.file.write(buildPath("coverage", "html", htmlFile), data.toHtml);
  }

  return coverageData.coveragePercent;
}

string toCoverageHtmlFileName(string fileName) {
  return fileName.replace("/", "-").replace("\\", "-") ~ ".html";
}

/// Get the line that contains the coverage summary
auto getCoverageSummary(string fileContent) {
  auto lines = fileContent.splitLines.array;

  std.algorithm.reverse(lines);

  return lines
      .filter!(a => a.indexOf('|') == -1 || a.indexOf('|') > 9)
      .map!(a => a.strip)
      .filter!(a => a != "");
}

/// It should get the coverage summary from the .lst file with no coverage


/// It should get the coverage summary from the .lst file with missing data


/// It should get the coverage summary from the .lst file with percentage


/// Get the filename from the coverage summary
string getFileName(string fileContent) {
  auto r = fileContent.getCoverageSummary;

  if(r.empty) {
    return "";
  }

  auto pos = r.front.lastIndexOf(".d");

  return r.front[0..pos + 2];
}


/// It should get the filename from the .lst file with no coverage


/// It should get the filename from the .lst file with no code


/// It should get the filename from the .lst file with percentage


/// Get the percentage from the covered summary
double getCoveragePercent(string fileContent) {
  auto r = fileContent.getCoverageSummary;

  if(r.empty) {
    return 100;
  }

  auto pos = r.front.lastIndexOf('%');

  if(pos == -1) {
    return 100;
  }

  auto pos2 = r.front[0..pos].lastIndexOf(' ') + 1;

  return r.front[pos2..pos].to!double;
}

/// It should get the filename from the .lst file with no coverage


/// It should get the filename from the .lst file with no code


/// It should get the filename from the .lst file with percentage


/// The representation of a line from the .lst file
struct LineCoverage {

  ///
  string code;

  ///
  size_t hits;

  ///
  bool hasCode;

  @disable this();

  ///
  this(string line) {
    enforce(line.indexOf("\n") == -1, "You should provide a line");
    line = line.strip;
    auto column = line.indexOf("|");

    if(column == -1) {
      code = line;
    } else if(column == 0) {
      code = line[1..$];
    } else {
      hits = line[0..column].strip.to!size_t;
      hasCode = true;
      code = line[column + 1..$];
    }
  }
}

/// It should parse an empty line


/// Parse the file lines
auto toCoverageLines(string fileContent) {
  return fileContent
      .splitLines
      .filter!(a => a.indexOf('|') != -1 && a.indexOf('|') < 10)
      .map!(a => a.strip)
      .map!(a => LineCoverage(a));
}

/// It should convert a .lst file to covered line structs


/// Structure that represents one .lst file
struct CoveredFile {
  /// The covered file path
  string path;

  /// Is true if the file is from the tested library and
  /// false if is an external file
  bool isInCurrentProject;

  /// Is true if the file is set to be ignored
  /// from the final report
  bool isIgnored;

  /// The module name
  string moduleName;

  /// The covered percent
  double coveragePercent;

  /// The file lines with coverage data
  LineCoverage[] lines;
}

/// Check if a file should be ignored from the report
bool isIgnored(const string content) {
  auto firstLine = content.splitter('\n');

  if(firstLine.empty) {
    return false;
  }

  auto smallCase = firstLine.front.strip.toLower;
  auto pieces = smallCase.replace("\t", " ").splitter(' ').filter!(a => a != "").array;

  if(pieces[0].indexOf("//") == -1 && pieces[0].indexOf("/*") == -1 && pieces[0].indexOf("/+") == -1) {
    return false;
  }

  if(pieces.length == 2) {
    return pieces[0].indexOf("ignore") != -1 && pieces[1] == "coverage";
  }

  if(pieces.length < 3) {
    return false;
  }

  return pieces[1] == "ignore" && pieces[2] == "coverage";
}

/// It should return true for ignored coverage files



/// It should return false for when the ignore coverage file is missing



/// Check if a file is in the current path
bool isPackagePath(string fullPath, string packagePath) {
  if(fullPath.indexOf("trial_") != -1) {
    return false;
  }

  if(fullPath.indexOf(packagePath) == 0) {
    return true;
  }

  if(fullPath.replace("\\", "/").indexOf(packagePath) == 0) {
    return true;
  }

  return false;
}

/// Check project paths


/// Converts a .lst file content to a CoveredFile structure
CoveredFile toCoverageFile(string content, string packagePath) {
  auto fileName = content.getFileName;
  auto fullPath = buildNormalizedPath(getcwd, fileName);

  return CoveredFile(
    fileName,
    fullPath.isPackagePath(packagePath),
    content.isIgnored(),
    getModuleName(fullPath),
    getCoveragePercent(content),
    content.toCoverageLines.array);
}

/// should convert a .lst file to CoveredFile structure


/// should mark the `trial_.d` file as external file


/// Generate the html for a line coverage
string toLineCoverage(T)(LineCoverage line, T index) {
  return `<div class="line {hasCode} {hit}"><span class="line-number">{line}</span><span class="hit-count">{hitCount}</span></div>`
            .replaceVariable("hasCode", line.hasCode ? "has-code" : "")
            .replaceVariable("hit", line.hits > 0 ? "hit" : "")
            .replaceVariable("line", index.to!string)
            .replaceVariable("hitCount", line.hits.to!string);
}

/// Render line coverage column


/// Get the line coverage column for the html report
string toHtmlCoverage(LineCoverage[] lines) {
  return lines.enumerate(1).map!(a => a[1].toLineCoverage(a[0])).array.join("").replace("\n", "");
}

/// Cont how many lines were hit
auto hitLines(LineCoverage[] lines) {
  return lines.filter!(a => a.hits > 0).array.length;
}

/// Cont how many lines were hit
auto codeLines(LineCoverage[] lines) {
  return lines.filter!(a => a.hasCode).array.length;
}

/// Replace an `{variable}` inside a string
string replaceVariable(const string page, const string key, const string value) pure {
  return page.replace("{"~key~"}", value);
}

/// It should replace a variable inside a page


/// wraps some string in a html page
string wrapToHtml(string content, string title) {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">

  <link rel="stylesheet" href="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/default.min.css">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
  <link rel="stylesheet" href="coverage.css">

  <script src="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/highlight.min.js"></script>
  <script src="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/languages/d.min.js"></script>
  <title>{title}</title>
</head>
<body>
  {content}
</body>
</html>`.replaceVariable("content", content).replaceVariable("title", title);
}

///should replace the variables inside the page.html


/// Create an html progress bar
string htmlProgress(string percent) {
  return `<div class="progress">
  <div class="progress-bar progress-bar-info progress-bar-striped" role="progressbar" aria-valuenow="{percent}" aria-valuemin="0" aria-valuemax="100" style="width: {percent}%">
    <span class="sr-only">{percent}% Covered</span>
    {percent}%
  </div>
</div>`.replaceVariable("percent", percent);
}

///should replace the variables inside the page.html


/// Generate the coverage page header
string coverageHeader(CoveredFile coveredFile) {
  return `<header>
  <h1>{title} <small>{hitLines}/{totalLines}({coveragePercent}%) line coverage</small></h1>
  <ol class="breadcrumb">
    <li><a href="index.html">index</a></li>
    <li>{pathPieces}</li>
  </ol>
</header>`
          .replaceVariable("title", coveredFile.moduleName)
          .replaceVariable("hitLines", coveredFile.lines.hitLines.to!string)
          .replaceVariable("totalLines", coveredFile.lines.codeLines.to!string)
          .replaceVariable("coveragePercent", coveredFile.coveragePercent.to!string)
          .replaceVariable("pathPieces", pathSplitter(coveredFile.path).array.join(`</li><li>`));
}

/// Check variables for the coverage header


/// Convert a `CoveredFile` struct to html
string toHtml(CoveredFile coveredFile) {
   return wrapToHtml(
     coverageHeader(coveredFile) ~
     `<main class="coverage">
  <figure>
    <pre class="code-container">
      <div class="coverage-container">{lines}</div>
      <code class="d">{code}</code>
    </pre>
  </figure>
</main>
<script>hljs.initHighlightingOnLoad();</script>`
          .replaceVariable("lines", coveredFile.lines.toHtmlCoverage)
          .replaceVariable("code", coveredFile.lines.map!(a => a.code.replace("<", "&lt;").replace(">", "&gt;")).array.join("\n")),

      coveredFile.moduleName ~ " coverage"
   );
}

/// Check variables for the coverage html


string indexTable(string content) {
  return `<table class="table">
  <thead>
    <tr>
      <th>Module</th>
      <th>File</th>
      <th>Lines Covered</th>
      <th>Percent</th>
    </tr>
  </thead>
  <tbody>{content}</tbody>
</table>`.replaceVariable("content", content);
}

string ignoredTable(string content) {
  return `<table class="table">
  <thead>
    <tr>
      <th>Module</th>
      <th>File</th>
      <th>Lines ignored</th>
    </tr>
  </thead>
  <tbody>{content}</tbody>
</table>`.replaceVariable("content", content);
}

/// Check if the table body is inserted


/// Calculate the coverage percent from the current project
double coveragePercent(CoveredFile[] coveredFiles) {
  if(coveredFiles.length == 0) {
    return 100;
  }

  double total = 0;
  double covered = 0;

  foreach(file; coveredFiles.filter!"a.isInCurrentProject".filter!"!a.isIgnored") {
    total += file.lines.map!(a => a.hasCode ? 1 : 0).sum;
    covered += file.lines.filter!(a => a.hasCode).map!(a => a.hits > 0 ? 1 : 0).sum;
  }

  if(total == 0) {
    return 100;
  }

  return round((covered / total) * 10000) / 100;
}

/// No files are always 100% covered


/// check a 50% covered file


/// check a 50% external covered file



string toHtmlIndex(CoveredFile[] coveredFiles, string name) {
  sort!("toUpper(a.path) < toUpper(b.path)", SwapStrategy.stable)(coveredFiles);
  string content;

  string table;
  size_t totalHitLines;
  size_t totalLines;
  size_t ignoredLines;
  int count;

  foreach(file; coveredFiles.filter!"a.isInCurrentProject".filter!"!a.isIgnored") {
    auto currentHitLines = file.lines.hitLines;
    auto currentTotalLines = file.lines.codeLines;

    table ~= `<tr>
      <td><a href="` ~ file.path.toCoverageHtmlFileName ~ `">` ~ file.path ~ `</a></td>
      <td>` ~ file.moduleName ~ `</td>
      <td>` ~ file.lines.hitLines.to!string ~ `/` ~ currentTotalLines.to!string ~ `</td>
      <td>` ~ file.coveragePercent.to!string.htmlProgress ~ `</td>
    </tr>`;

    totalHitLines += currentHitLines;
    totalLines += currentTotalLines;
    count++;
  }

  table ~= `<tr>
      <th colspan="2">Total</td>
      <th>` ~ totalHitLines.to!string ~ `/` ~ totalLines.to!string ~ `</td>
      <th>` ~ coveredFiles.coveragePercent.to!string.htmlProgress ~ `</td>
    </tr>`;

  content ~= indexHeader(name) ~ table.indexTable;


  /// Ignored files
  table = "";
  foreach(file; coveredFiles.filter!"a.isInCurrentProject".filter!"a.isIgnored") {
    auto currentTotalLines = file.lines.codeLines;

    table ~= `<tr>
      <td><a href="` ~ file.path.toCoverageHtmlFileName ~ `">` ~ file.path ~ `</a></td>
      <td>` ~ file.moduleName ~ `</td>
      <td>` ~ currentTotalLines.to!string ~ `/` ~ totalLines.to!string ~ `</td>
    </tr>`;

    ignoredLines += currentTotalLines;
    count++;
  }

  table ~= `<tr>
      <th colspan="2">Total</td>
      <th>` ~ ignoredLines.to!string ~ `/` ~ totalLines.to!string ~ `</td>
    </tr>`;

  content ~= `<h1>Ignored</h1>` ~ table.ignoredTable;

  /// external files
  table = "";
  foreach(file; coveredFiles.filter!"!a.isInCurrentProject") {
    table ~= `<tr>
      <td><a href="` ~ file.path.toCoverageHtmlFileName ~ `">` ~ file.path ~ `</a></td>
      <td>` ~ file.moduleName ~ `</td>
      <td>` ~ file.lines.hitLines.to!string ~ `/` ~ file.lines.codeLines.to!string ~ `</td>
      <td>` ~ file.coveragePercent.to!string.htmlProgress ~ `</td>
    </tr>`;
  }

  content ~= `<h1>Dependencies</h1>` ~ table.indexTable;

  content = `<div class="container">` ~ content ~ `</div>`;

  return wrapToHtml(content, "Code Coverage report");
}

string indexHeader(string name) {
  return `<h1>` ~ name ~ ` <img src="coverage-shield.svg"></h1>`;
}


/// Create line coverage shield as svg
string coverageShield(string percent) {
  return `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="118" height="20"><linearGradient id="b" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="a"><rect width="118" height="20" rx="3" fill="#fff"/></clipPath><g clip-path="url(#a)"><path fill="#555" d="M0 0h83v20H0z"/><path fill="#4c1" d="M83 0h35v20H83z"/><path fill="url(#b)" d="M0 0h118v20H0z"/></g><g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11"><text x="41.5" y="15" fill="#010101" fill-opacity=".3">line coverage</text><text x="41.5" y="14">line coverage</text><text x="99.5" y="15" fill="#010101" fill-opacity=".3">?%</text><text x="99.5" y="14">?%</text></g></svg>`.replace("?%", percent ~ "%");
}

/// The line coverage shield should contain the percent
/++
  A module containing the attributes used to add metadata to your tests

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

/// This struct is used to mark some test functions
struct TestAttribute {
  ///
  string file;

  ///
  size_t line;
}

/// This specifies when a setup method must be called
struct TestSetupAttribute {
  /// Run before the suite starts
  bool beforeAll;

  /// Run after the suite ends
  bool afterAll;

  /// Run before each test
  bool beforeEach;

  /// Run after each test
  bool afterEach;
}

/// Mark a test
TestAttribute Test(string file = __FILE__, size_t line = __LINE__) {
  return TestAttribute(file, line);
}

/// Mark a function to be executed before each test
TestSetupAttribute BeforeEach() {
  return TestSetupAttribute(false, false, true, false);
}

/// Mark a function to be executed after each test
TestSetupAttribute AfterEach() {
  return TestSetupAttribute(false, false, false, true);
}

/// Mark a function to be executed before the suite starts
TestSetupAttribute BeforeAll() {
  return TestSetupAttribute(true, false, false, false);
}

/// Mark a function to be executed after the suite ends
TestSetupAttribute AfterAll() {
  return TestSetupAttribute(false, true, false, false);
}/++ Ignore coverage
	Module for interacting with the user's terminal, including color output, cursor manipulation, and full-featured real-time mouse and keyboard input. Also includes high-level convenience methods, like [Terminal.getline], which gives the user a line editor with history, completion, etc. See the [#examples].


	The main interface for this module is the Terminal struct, which
	encapsulates the output functions and line-buffered input of the terminal, and
	RealTimeConsoleInput, which gives real time input.

	Creating an instance of these structs will perform console initialization. When the struct
	goes out of scope, any changes in console settings will be automatically reverted.

	Note: on Posix, it traps SIGINT and translates it into an input event. You should
	keep your event loop moving and keep an eye open for this to exit cleanly; simply break
	your event loop upon receiving a UserInterruptionEvent. (Without
	the signal handler, ctrl+c can leave your terminal in a bizarre state.)

	As a user, if you have to forcibly kill your program and the event doesn't work, there's still ctrl+\

	On Mac Terminal btw, a lot of hacks are needed and mouse support doesn't work. Most functions basically
	work now though.

	Future_Roadmap:
	$(LIST
		* The CharacterEvent and NonCharacterKeyEvent types will be removed. Instead, use KeyboardEvent
		  on new programs.

		* The ScrollbackBuffer will be expanded to be easier to use to partition your screen. It might even
		  handle input events of some sort. Its API may change.

		* getline I want to be really easy to use both for code and end users. It will need multi-line support
		  eventually.

		* I might add an expandable event loop and base level widget classes. This may be Linux-specific in places and may overlap with similar functionality in simpledisplay.d. If I can pull it off without a third module, I want them to be compatible with each other too so the two modules can be combined easily. (Currently, they are both compatible with my eventloop.d and can be easily combined through it, but that is a third module.)

		* More advanced terminal features as functions, where available, like cursor changing and full-color functions.

		* The module will eventually be renamed to `arsd.terminal`.

		* More documentation.
	)

	WHAT I WON'T DO:
	$(LIST
		* support everything under the sun. If it isn't default-installed on an OS I or significant number of other people
		  might actually use, and isn't written by me, I don't really care about it. This means the only supported terminals are:
		  $(LIST

		  * xterm (and decently xterm compatible emulators like Konsole)
		  * Windows console
		  * rxvt (to a lesser extent)
		  * Linux console
		  * My terminal emulator family of applications https://github.com/adamdruppe/terminal-emulator
		  )

		  Anything else is cool if it does work, but I don't want to go out of my way for it.

		* Use other libraries, unless strictly optional. terminal.d is a stand-alone module by default and
		  always will be.

		* Do a full TUI widget set. I might do some basics and lay a little groundwork, but a full TUI
		  is outside the scope of this module (unless I can do it really small.)
	)
+/


/*
	Widgets:
		tab widget
		scrollback buffer
		partitioned canvas
*/

// FIXME: ctrl+d eof on stdin

// FIXME: http://msdn.microsoft.com/en-us/library/windows/desktop/ms686016%28v=vs.85%29.aspx

version(Posix) {
	enum SIGWINCH = 28;
	__gshared bool windowSizeChanged = false;
	__gshared bool interrupted = false; /// you might periodically check this in a long operation and abort if it is set. Remember it is volatile. It is also sent through the input event loop via RealTimeConsoleInput
	__gshared bool hangedUp = false; /// similar to interrupted.

	version(with_eventloop)
		struct SignalFired {}

	extern(C)
	void sizeSignalHandler(int sigNumber) nothrow {
		windowSizeChanged = true;
		version(with_eventloop) {
			import arsd.eventloop;
			try
				send(SignalFired());
			catch(Exception) {}
		}
	}
	extern(C)
	void interruptSignalHandler(int sigNumber) nothrow {
		interrupted = true;
		version(with_eventloop) {
			import arsd.eventloop;
			try
				send(SignalFired());
			catch(Exception) {}
		}
	}
	extern(C)
	void hangupSignalHandler(int sigNumber) nothrow {
		hangedUp = true;
		version(with_eventloop) {
			import arsd.eventloop;
			try
				send(SignalFired());
			catch(Exception) {}
		}
	}

}

// parts of this were taken from Robik's ConsoleD
// https://github.com/robik/ConsoleD/blob/master/consoled.d

// Uncomment this line to get a main() to demonstrate this module's
// capabilities.
//version = Demo

version(Windows) {
	import core.sys.windows.windows;
	import std.string : toStringz;
	private {
		enum RED_BIT = 4;
		enum GREEN_BIT = 2;
		enum BLUE_BIT = 1;
	}
}

version(Posix) {
	import core.sys.posix.termios;
	import core.sys.posix.unistd;
	import unix = core.sys.posix.unistd;
	import core.sys.posix.sys.types;
	import core.sys.posix.sys.time;
	import core.stdc.stdio;
	private {
		enum RED_BIT = 1;
		enum GREEN_BIT = 2;
		enum BLUE_BIT = 4;
	}

	version(linux) {
		extern(C) int ioctl(int, int, ...);
		enum int TIOCGWINSZ = 0x5413;
	} else version(OSX) {
		import core.stdc.config;
		extern(C) int ioctl(int, c_ulong, ...);
		enum TIOCGWINSZ = 1074295912;
	} else static assert(0, "confirm the value of tiocgwinsz");

	struct winsize {
		ushort ws_row;
		ushort ws_col;
		ushort ws_xpixel;
		ushort ws_ypixel;
	}

	// I'm taking this from the minimal termcap from my Slackware box (which I use as my /etc/termcap) and just taking the most commonly used ones (for me anyway).

	// this way we'll have some definitions for 99% of typical PC cases even without any help from the local operating system

	enum string builtinTermcap = `
# Generic VT entry.
vg|vt-generic|Generic VT entries:\
	:bs:mi:ms:pt:xn:xo:it#8:\
	:RA=\E[?7l:SA=\E?7h:\
	:bl=^G:cr=^M:ta=^I:\
	:cm=\E[%i%d;%dH:\
	:le=^H:up=\E[A:do=\E[B:nd=\E[C:\
	:LE=\E[%dD:RI=\E[%dC:UP=\E[%dA:DO=\E[%dB:\
	:ho=\E[H:cl=\E[H\E[2J:ce=\E[K:cb=\E[1K:cd=\E[J:sf=\ED:sr=\EM:\
	:ct=\E[3g:st=\EH:\
	:cs=\E[%i%d;%dr:sc=\E7:rc=\E8:\
	:ei=\E[4l:ic=\E[@:IC=\E[%d@:al=\E[L:AL=\E[%dL:\
	:dc=\E[P:DC=\E[%dP:dl=\E[M:DL=\E[%dM:\
	:so=\E[7m:se=\E[m:us=\E[4m:ue=\E[m:\
	:mb=\E[5m:mh=\E[2m:md=\E[1m:mr=\E[7m:me=\E[m:\
	:sc=\E7:rc=\E8:kb=\177:\
	:ku=\E[A:kd=\E[B:kr=\E[C:kl=\E[D:


# Slackware 3.1 linux termcap entry (Sat Apr 27 23:03:58 CDT 1996):
lx|linux|console|con80x25|LINUX System Console:\
        :do=^J:co#80:li#25:cl=\E[H\E[J:sf=\ED:sb=\EM:\
        :le=^H:bs:am:cm=\E[%i%d;%dH:nd=\E[C:up=\E[A:\
        :ce=\E[K:cd=\E[J:so=\E[7m:se=\E[27m:us=\E[36m:ue=\E[m:\
        :md=\E[1m:mr=\E[7m:mb=\E[5m:me=\E[m:is=\E[1;25r\E[25;1H:\
        :ll=\E[1;25r\E[25;1H:al=\E[L:dc=\E[P:dl=\E[M:\
        :it#8:ku=\E[A:kd=\E[B:kr=\E[C:kl=\E[D:kb=^H:ti=\E[r\E[H:\
        :ho=\E[H:kP=\E[5~:kN=\E[6~:kH=\E[4~:kh=\E[1~:kD=\E[3~:kI=\E[2~:\
        :k1=\E[[A:k2=\E[[B:k3=\E[[C:k4=\E[[D:k5=\E[[E:k6=\E[17~:\
	:F1=\E[23~:F2=\E[24~:\
        :k7=\E[18~:k8=\E[19~:k9=\E[20~:k0=\E[21~:K1=\E[1~:K2=\E[5~:\
        :K4=\E[4~:K5=\E[6~:\
        :pt:sr=\EM:vt#3:xn:km:bl=^G:vi=\E[?25l:ve=\E[?25h:vs=\E[?25h:\
        :sc=\E7:rc=\E8:cs=\E[%i%d;%dr:\
        :r1=\Ec:r2=\Ec:r3=\Ec:

# Some other, commonly used linux console entries.
lx|con80x28:co#80:li#28:tc=linux:
lx|con80x43:co#80:li#43:tc=linux:
lx|con80x50:co#80:li#50:tc=linux:
lx|con100x37:co#100:li#37:tc=linux:
lx|con100x40:co#100:li#40:tc=linux:
lx|con132x43:co#132:li#43:tc=linux:

# vt102 - vt100 + insert line etc. VT102 does not have insert character.
v2|vt102|DEC vt102 compatible:\
	:co#80:li#24:\
	:ic@:IC@:\
	:is=\E[m\E[?1l\E>:\
	:rs=\E[m\E[?1l\E>:\
	:eA=\E)0:as=^N:ae=^O:ac=aaffggjjkkllmmnnooqqssttuuvvwwxx:\
	:ks=:ke=:\
	:k1=\EOP:k2=\EOQ:k3=\EOR:k4=\EOS:\
	:tc=vt-generic:

# vt100 - really vt102 without insert line, insert char etc.
vt|vt100|DEC vt100 compatible:\
	:im@:mi@:al@:dl@:ic@:dc@:AL@:DL@:IC@:DC@:\
	:tc=vt102:


# Entry for an xterm. Insert mode has been disabled.
vs|xterm|xterm-color|xterm-256color|vs100|xterm terminal emulator (X Window System):\
	:am:bs:mi@:km:co#80:li#55:\
	:im@:ei@:\
	:cl=\E[H\E[J:\
	:ct=\E[3k:ue=\E[m:\
	:is=\E[m\E[?1l\E>:\
	:rs=\E[m\E[?1l\E>:\
	:vi=\E[?25l:ve=\E[?25h:\
	:eA=\E)0:as=^N:ae=^O:ac=aaffggjjkkllmmnnooqqssttuuvvwwxx:\
	:kI=\E[2~:kD=\E[3~:kP=\E[5~:kN=\E[6~:\
	:k1=\EOP:k2=\EOQ:k3=\EOR:k4=\EOS:k5=\E[15~:\
	:k6=\E[17~:k7=\E[18~:k8=\E[19~:k9=\E[20~:k0=\E[21~:\
	:F1=\E[23~:F2=\E[24~:\
	:kh=\E[H:kH=\E[F:\
	:ks=:ke=:\
	:te=\E[2J\E[?47l\E8:ti=\E7\E[?47h:\
	:tc=vt-generic:


#rxvt, added by me
rxvt|rxvt-unicode:\
	:am:bs:mi@:km:co#80:li#55:\
	:im@:ei@:\
	:ct=\E[3k:ue=\E[m:\
	:is=\E[m\E[?1l\E>:\
	:rs=\E[m\E[?1l\E>:\
	:vi=\E[?25l:\
	:ve=\E[?25h:\
	:eA=\E)0:as=^N:ae=^O:ac=aaffggjjkkllmmnnooqqssttuuvvwwxx:\
	:kI=\E[2~:kD=\E[3~:kP=\E[5~:kN=\E[6~:\
	:k1=\E[11~:k2=\E[12~:k3=\E[13~:k4=\E[14~:k5=\E[15~:\
	:k6=\E[17~:k7=\E[18~:k8=\E[19~:k9=\E[20~:k0=\E[21~:\
	:F1=\E[23~:F2=\E[24~:\
	:kh=\E[7~:kH=\E[8~:\
	:ks=:ke=:\
	:te=\E[2J\E[?47l\E8:ti=\E7\E[?47h:\
	:tc=vt-generic:


# Some other entries for the same xterm.
v2|xterms|vs100s|xterm small window:\
	:co#80:li#24:tc=xterm:
vb|xterm-bold|xterm with bold instead of underline:\
	:us=\E[1m:tc=xterm:
vi|xterm-ins|xterm with insert mode:\
	:mi:im=\E[4h:ei=\E[4l:tc=xterm:

Eterm|Eterm Terminal Emulator (X11 Window System):\
        :am:bw:eo:km:mi:ms:xn:xo:\
        :co#80:it#8:li#24:lm#0:pa#64:Co#8:AF=\E[3%dm:AB=\E[4%dm:op=\E[39m\E[49m:\
        :AL=\E[%dL:DC=\E[%dP:DL=\E[%dM:DO=\E[%dB:IC=\E[%d@:\
        :K1=\E[7~:K2=\EOu:K3=\E[5~:K4=\E[8~:K5=\E[6~:LE=\E[%dD:\
        :RI=\E[%dC:UP=\E[%dA:ae=^O:al=\E[L:as=^N:bl=^G:cd=\E[J:\
        :ce=\E[K:cl=\E[H\E[2J:cm=\E[%i%d;%dH:cr=^M:\
        :cs=\E[%i%d;%dr:ct=\E[3g:dc=\E[P:dl=\E[M:do=\E[B:\
        :ec=\E[%dX:ei=\E[4l:ho=\E[H:i1=\E[?47l\E>\E[?1l:ic=\E[@:\
        :im=\E[4h:is=\E[r\E[m\E[2J\E[H\E[?7h\E[?1;3;4;6l\E[4l:\
        :k1=\E[11~:k2=\E[12~:k3=\E[13~:k4=\E[14~:k5=\E[15~:\
        :k6=\E[17~:k7=\E[18~:k8=\E[19~:k9=\E[20~:kD=\E[3~:\
        :kI=\E[2~:kN=\E[6~:kP=\E[5~:kb=^H:kd=\E[B:ke=:kh=\E[7~:\
        :kl=\E[D:kr=\E[C:ks=:ku=\E[A:le=^H:mb=\E[5m:md=\E[1m:\
        :me=\E[m\017:mr=\E[7m:nd=\E[C:rc=\E8:\
        :sc=\E7:se=\E[27m:sf=^J:so=\E[7m:sr=\EM:st=\EH:ta=^I:\
        :te=\E[2J\E[?47l\E8:ti=\E7\E[?47h:ue=\E[24m:up=\E[A:\
        :us=\E[4m:vb=\E[?5h\E[?5l:ve=\E[?25h:vi=\E[?25l:\
        :ac=aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~:

# DOS terminal emulator such as Telix or TeleMate.
# This probably also works for the SCO console, though it's incomplete.
an|ansi|ansi-bbs|ANSI terminals (emulators):\
	:co#80:li#24:am:\
	:is=:rs=\Ec:kb=^H:\
	:as=\E[m:ae=:eA=:\
	:ac=0\333+\257,\256.\031-\030a\261f\370g\361j\331k\277l\332m\300n\305q\304t\264u\303v\301w\302x\263~\025:\
	:kD=\177:kH=\E[Y:kN=\E[U:kP=\E[V:kh=\E[H:\
	:k1=\EOP:k2=\EOQ:k3=\EOR:k4=\EOS:k5=\EOT:\
	:k6=\EOU:k7=\EOV:k8=\EOW:k9=\EOX:k0=\EOY:\
	:tc=vt-generic:

	`;
}

enum Bright = 0x08;

/// Defines the list of standard colors understood by Terminal.
enum Color : ushort {
	black = 0, /// .
	red = RED_BIT, /// .
	green = GREEN_BIT, /// .
	yellow = red | green, /// .
	blue = BLUE_BIT, /// .
	magenta = red | blue, /// .
	cyan = blue | green, /// .
	white = red | green | blue, /// .
	DEFAULT = 256,
}

/// When capturing input, what events are you interested in?
///
/// Note: these flags can be OR'd together to select more than one option at a time.
///
/// Ctrl+C and other keyboard input is always captured, though it may be line buffered if you don't use raw.
/// The rationale for that is to ensure the Terminal destructor has a chance to run, since the terminal is a shared resource and should be put back before the program terminates.
enum ConsoleInputFlags {
	raw = 0, /// raw input returns keystrokes immediately, without line buffering
	echo = 1, /// do you want to automatically echo input back to the user?
	mouse = 2, /// capture mouse events
	paste = 4, /// capture paste events (note: without this, paste can come through as keystrokes)
	size = 8, /// window resize events

	releasedKeys = 64, /// key release events. Not reliable on Posix.

	allInputEvents = 8|4|2, /// subscribe to all input events. Note: in previous versions, this also returned release events. It no longer does, use allInputEventsWithRelease if you want them.
	allInputEventsWithRelease = allInputEvents|releasedKeys, /// subscribe to all input events, including (unreliable on Posix) key release events.
}

/// Defines how terminal output should be handled.
enum ConsoleOutputType {
	linear = 0, /// do you want output to work one line at a time?
	cellular = 1, /// or do you want access to the terminal screen as a grid of characters?
	//truncatedCellular = 3, /// cellular, but instead of wrapping output to the next line automatically, it will truncate at the edges

	minimalProcessing = 255, /// do the least possible work, skips most construction and desturction tasks. Only use if you know what you're doing here
}

/// Some methods will try not to send unnecessary commands to the screen. You can override their judgement using a ForceOption parameter, if present
enum ForceOption {
	automatic = 0, /// automatically decide what to do (best, unless you know for sure it isn't right)
	neverSend = -1, /// never send the data. This will only update Terminal's internal state. Use with caution.
	alwaysSend = 1, /// always send the data, even if it doesn't seem necessary
}

// we could do it with termcap too, getenv("TERMCAP") then split on : and replace \E with \033 and get the pieces

/// Encapsulates the I/O capabilities of a terminal.
///
/// Warning: do not write out escape sequences to the terminal. This won't work
/// on Windows and will confuse Terminal's internal state on Posix.
struct Terminal {
	///
	@disable this();
	@disable this(this);
	private ConsoleOutputType type;

	version(Posix) {
		private int fdOut;
		private int fdIn;
		private int[] delegate() getSizeOverride;
		void delegate(in void[]) _writeDelegate; // used to override the unix write() system call, set it magically
	}

	version(Posix) {
		bool terminalInFamily(string[] terms...) {
			import std.process;
			import std.string;
			auto term = environment.get("TERM");
			foreach(t; terms)
				if(indexOf(term, t) != -1)
					return true;

			return false;
		}

		// This is a filthy hack because Terminal.app and OS X are garbage who don't
		// work the way they're advertised. I just have to best-guess hack and hope it
		// doesn't break anything else. (If you know a better way, let me know!)
		bool isMacTerminal() {
			import std.process;
			import std.string;
			auto term = environment.get("TERM");
			return term == "xterm-256color";
		}

		static string[string] termcapDatabase;
		static void readTermcapFile(bool useBuiltinTermcap = false) {
			import std.file;
			import std.stdio;
			import std.string;

			if(!exists("/etc/termcap"))
				useBuiltinTermcap = true;

			string current;

			void commitCurrentEntry() {
				if(current is null)
					return;

				string names = current;
				auto idx = indexOf(names, ":");
				if(idx != -1)
					names = names[0 .. idx];

				foreach(name; split(names, "|"))
					termcapDatabase[name] = current;

				current = null;
			}

			void handleTermcapLine(in char[] line) {
				if(line.length == 0) { // blank
					commitCurrentEntry();
					return; // continue
				}
				if(line[0] == '#') // comment
					return; // continue
				size_t termination = line.length;
				if(line[$-1] == '\\')
					termination--; // cut off the \\
				current ~= strip(line[0 .. termination]);
				// termcap entries must be on one logical line, so if it isn't continued, we know we're done
				if(line[$-1] != '\\')
					commitCurrentEntry();
			}

			if(useBuiltinTermcap) {
				foreach(line; splitLines(builtinTermcap)) {
					handleTermcapLine(line);
				}
			} else {
				foreach(line; File("/etc/termcap").byLine()) {
					handleTermcapLine(line);
				}
			}
		}

		static string getTermcapDatabase(string terminal) {
			import std.string;

			if(termcapDatabase is null)
				readTermcapFile();

			auto data = terminal in termcapDatabase;
			if(data is null)
				return null;

			auto tc = *data;
			auto more = indexOf(tc, ":tc=");
			if(more != -1) {
				auto tcKey = tc[more + ":tc=".length .. $];
				auto end = indexOf(tcKey, ":");
				if(end != -1)
					tcKey = tcKey[0 .. end];
				tc = getTermcapDatabase(tcKey) ~ tc;
			}

			return tc;
		}

		string[string] termcap;
		void readTermcap() {
			import std.process;
			import std.string;
			import std.array;

			string termcapData = environment.get("TERMCAP");
			if(termcapData.length == 0) {
				termcapData = getTermcapDatabase(environment.get("TERM"));
			}

			auto e = replace(termcapData, "\\\n", "\n");
			termcap = null;

			foreach(part; split(e, ":")) {
				// FIXME: handle numeric things too

				auto things = split(part, "=");
				if(things.length)
					termcap[things[0]] =
						things.length > 1 ? things[1] : null;
			}
		}

		string findSequenceInTermcap(in char[] sequenceIn) {
			char[10] sequenceBuffer;
			char[] sequence;
			if(sequenceIn.length > 0 && sequenceIn[0] == '\033') {
				if(!(sequenceIn.length < sequenceBuffer.length - 1))
					return null;
				sequenceBuffer[1 .. sequenceIn.length + 1] = sequenceIn[];
				sequenceBuffer[0] = '\\';
				sequenceBuffer[1] = 'E';
				sequence = sequenceBuffer[0 .. sequenceIn.length + 1];
			} else {
				sequence = sequenceBuffer[1 .. sequenceIn.length + 1];
			}

			import std.array;
			foreach(k, v; termcap)
				if(v == sequence)
					return k;
			return null;
		}

		string getTermcap(string key) {
			auto k = key in termcap;
			if(k !is null) return *k;
			return null;
		}

		// Looks up a termcap item and tries to execute it. Returns false on failure
		bool doTermcap(T...)(string key, T t) {
			import std.conv;
			auto fs = getTermcap(key);
			if(fs is null)
				return false;

			int swapNextTwo = 0;

			R getArg(R)(int idx) {
				if(swapNextTwo == 2) {
					idx ++;
					swapNextTwo--;
				} else if(swapNextTwo == 1) {
					idx --;
					swapNextTwo--;
				}

				foreach(i, arg; t) {
					if(i == idx)
						return to!R(arg);
				}
				assert(0, to!string(idx) ~ " is out of bounds working " ~ fs);
			}

			char[256] buffer;
			int bufferPos = 0;

			void addChar(char c) {
				import std.exception;
				enforce(bufferPos < buffer.length);
				buffer[bufferPos++] = c;
			}

			void addString(in char[] c) {
				import std.exception;
				enforce(bufferPos + c.length < buffer.length);
				buffer[bufferPos .. bufferPos + c.length] = c[];
				bufferPos += c.length;
			}

			void addInt(int c, int minSize) {
				import std.string;
				auto str = format("%0"~(minSize ? to!string(minSize) : "")~"d", c);
				addString(str);
			}

			bool inPercent;
			int argPosition = 0;
			int incrementParams = 0;
			bool skipNext;
			bool nextIsChar;
			bool inBackslash;

			foreach(char c; fs) {
				if(inBackslash) {
					if(c == 'E')
						addChar('\033');
					else
						addChar(c);
					inBackslash = false;
				} else if(nextIsChar) {
					if(skipNext)
						skipNext = false;
					else
						addChar(cast(char) (c + getArg!int(argPosition) + (incrementParams ? 1 : 0)));
					if(incrementParams) incrementParams--;
					argPosition++;
					inPercent = false;
				} else if(inPercent) {
					switch(c) {
						case '%':
							addChar('%');
							inPercent = false;
						break;
						case '2':
						case '3':
						case 'd':
							if(skipNext)
								skipNext = false;
							else
								addInt(getArg!int(argPosition) + (incrementParams ? 1 : 0),
									c == 'd' ? 0 : (c - '0')
								);
							if(incrementParams) incrementParams--;
							argPosition++;
							inPercent = false;
						break;
						case '.':
							if(skipNext)
								skipNext = false;
							else
								addChar(cast(char) (getArg!int(argPosition) + (incrementParams ? 1 : 0)));
							if(incrementParams) incrementParams--;
							argPosition++;
						break;
						case '+':
							nextIsChar = true;
							inPercent = false;
						break;
						case 'i':
							incrementParams = 2;
							inPercent = false;
						break;
						case 's':
							skipNext = true;
							inPercent = false;
						break;
						case 'b':
							argPosition--;
							inPercent = false;
						break;
						case 'r':
							swapNextTwo = 2;
							inPercent = false;
						break;
						// FIXME: there's more
						// http://www.gnu.org/software/termutils/manual/termcap-1.3/html_mono/termcap.html

						default:
							assert(0, "not supported " ~ c);
					}
				} else {
					if(c == '%')
						inPercent = true;
					else if(c == '\\')
						inBackslash = true;
					else
						addChar(c);
				}
			}

			writeStringRaw(buffer[0 .. bufferPos]);
			return true;
		}
	}

	version(Posix)
	/**
	 * Constructs an instance of Terminal representing the capabilities of
	 * the current terminal.
	 *
	 * While it is possible to override the stdin+stdout file descriptors, remember
	 * that is not portable across platforms and be sure you know what you're doing.
	 *
	 * ditto on getSizeOverride. That's there so you can do something instead of ioctl.
	 */
	this(ConsoleOutputType type, int fdIn = 0, int fdOut = 1, int[] delegate() getSizeOverride = null) {
		this.fdIn = fdIn;
		this.fdOut = fdOut;
		this.getSizeOverride = getSizeOverride;
		this.type = type;

		readTermcap();

		if(type == ConsoleOutputType.minimalProcessing) {
			_suppressDestruction = true;
			return;
		}

		if(type == ConsoleOutputType.cellular) {
			doTermcap("ti");
			clear();
			moveTo(0, 0, ForceOption.alwaysSend); // we need to know where the cursor is for some features to work, and moving it is easier than querying it
		}

		if(terminalInFamily("xterm", "rxvt", "screen")) {
			writeStringRaw("\033[22;0t"); // save window title on a stack (support seems spotty, but it doesn't hurt to have it)
		}
	}

	version(Windows) {
		HANDLE hConsole;
		CONSOLE_SCREEN_BUFFER_INFO originalSbi;
	}

	version(Windows)
	/// ditto
	this(ConsoleOutputType type) {
		if(type == ConsoleOutputType.cellular) {
			hConsole = CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE, 0, null, CONSOLE_TEXTMODE_BUFFER, null);
			if(hConsole == INVALID_HANDLE_VALUE) {
				import std.conv;
				throw new Exception(to!string(GetLastError()));
			}

			SetConsoleActiveScreenBuffer(hConsole);
			/*
http://msdn.microsoft.com/en-us/library/windows/desktop/ms686125%28v=vs.85%29.aspx
http://msdn.microsoft.com/en-us/library/windows/desktop/ms683193%28v=vs.85%29.aspx
			*/
			COORD size;
			/*
			CONSOLE_SCREEN_BUFFER_INFO sbi;
			GetConsoleScreenBufferInfo(hConsole, &sbi);
			size.X = cast(short) GetSystemMetrics(SM_CXMIN);
			size.Y = cast(short) GetSystemMetrics(SM_CYMIN);
			*/

			// FIXME: this sucks, maybe i should just revert it. but there shouldn't be scrollbars in cellular mode
			//size.X = 80;
			//size.Y = 24;
			//SetConsoleScreenBufferSize(hConsole, size);

			clear();
		} else {
			hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
		}

		GetConsoleScreenBufferInfo(hConsole, &originalSbi);
	}

	// only use this if you are sure you know what you want, since the terminal is a shared resource you generally really want to reset it to normal when you leave...
	bool _suppressDestruction;

	version(Posix)
	~this() {
		if(_suppressDestruction) {
			flush();
			return;
		}
		if(type == ConsoleOutputType.cellular) {
			doTermcap("te");
		}
		if(terminalInFamily("xterm", "rxvt", "screen")) {
			writeStringRaw("\033[23;0t"); // restore window title from the stack
		}
		showCursor();
		reset();
		flush();

		if(lineGetter !is null)
			lineGetter.dispose();
	}

	version(Windows)
	~this() {
		flush(); // make sure user data is all flushed before resetting
		reset();
		showCursor();

		if(lineGetter !is null)
			lineGetter.dispose();

		auto stdo = GetStdHandle(STD_OUTPUT_HANDLE);
		SetConsoleActiveScreenBuffer(stdo);
		if(hConsole !is stdo)
			CloseHandle(hConsole);
	}

	// lazily initialized and preserved between calls to getline for a bit of efficiency (only a bit)
	// and some history storage.
	LineGetter lineGetter;

	int _currentForeground = Color.DEFAULT;
	int _currentBackground = Color.DEFAULT;
	RGB _currentForegroundRGB;
	RGB _currentBackgroundRGB;
	bool reverseVideo = false;

	/++
		Attempts to set color according to a 24 bit value (r, g, b, each >= 0 and < 256).


		This is not supported on all terminals. It will attempt to fall back to a 256-color
		or 8-color palette in those cases automatically.

		Returns: true if it believes it was successful (note that it cannot be completely sure),
		false if it had to use a fallback.
	+/
	bool setTrueColor(RGB foreground, RGB background, ForceOption force = ForceOption.automatic) {
		if(force == ForceOption.neverSend) {
			_currentForeground = -1;
			_currentBackground = -1;
			_currentForegroundRGB = foreground;
			_currentBackgroundRGB = background;
			return true;
		}

		if(force == ForceOption.automatic && _currentForeground == -1 && _currentBackground == -1 && (_currentForegroundRGB == foreground && _currentBackgroundRGB == background))
			return true;

		_currentForeground = -1;
		_currentBackground = -1;
		_currentForegroundRGB = foreground;
		_currentBackgroundRGB = background;

		version(Windows) {
			flush();
			ushort setTob = cast(ushort) approximate16Color(background);
			ushort setTof = cast(ushort) approximate16Color(foreground);
			SetConsoleTextAttribute(
				hConsole,
				cast(ushort)((setTob << 4) | setTof));
			return false;
		} else {
			// FIXME: if the terminal reliably does support 24 bit color, use it
			// instead of the round off. But idk how to detect that yet...

			// fallback to 16 color for term that i know don't take it well
			import std.process;
			import std.string;
			if(environment.get("TERM") == "rxvt" || environment.get("TERM") == "linux") {
				// not likely supported, use 16 color fallback
				auto setTof = approximate16Color(foreground);
				auto setTob = approximate16Color(background);

				writeStringRaw(format("\033[%dm\033[3%dm\033[4%dm",
					(setTof & Bright) ? 1 : 0,
					cast(int) (setTof & ~Bright),
					cast(int) (setTob & ~Bright)
				));

				return false;
			}

			// otherwise, assume it is probably supported and give it a try
			writeStringRaw(format("\033[38;5;%dm\033[48;5;%dm",
				colorToXTermPaletteIndex(foreground),
				colorToXTermPaletteIndex(background)
			));

			return true;
		}
	}

	/// Changes the current color. See enum Color for the values.
	void color(int foreground, int background, ForceOption force = ForceOption.automatic, bool reverseVideo = false) {
		if(force != ForceOption.neverSend) {
			version(Windows) {
				// assuming a dark background on windows, so LowContrast == dark which means the bit is NOT set on hardware
				/*
				foreground ^= LowContrast;
				background ^= LowContrast;
				*/

				ushort setTof = cast(ushort) foreground;
				ushort setTob = cast(ushort) background;

				// this isn't necessarily right but meh
				if(background == Color.DEFAULT)
					setTob = Color.black;
				if(foreground == Color.DEFAULT)
					setTof = Color.white;

				if(force == ForceOption.alwaysSend || reverseVideo != this.reverseVideo || foreground != _currentForeground || background != _currentBackground) {
					flush(); // if we don't do this now, the buffering can screw up the colors...
					if(reverseVideo) {
						if(background == Color.DEFAULT)
							setTof = Color.black;
						else
							setTof = cast(ushort) background | (foreground & Bright);

						if(background == Color.DEFAULT)
							setTob = Color.white;
						else
							setTob = cast(ushort) (foreground & ~Bright);
					}
					SetConsoleTextAttribute(
						hConsole,
						cast(ushort)((setTob << 4) | setTof));
				}
			} else {
				import std.process;
				// I started using this envvar for my text editor, but now use it elsewhere too
				// if we aren't set to dark, assume light
				/*
				if(getenv("ELVISBG") == "dark") {
					// LowContrast on dark bg menas
				} else {
					foreground ^= LowContrast;
					background ^= LowContrast;
				}
				*/

				ushort setTof = cast(ushort) foreground & ~Bright;
				ushort setTob = cast(ushort) background & ~Bright;

				if(foreground & Color.DEFAULT)
					setTof = 9; // ansi sequence for reset
				if(background == Color.DEFAULT)
					setTob = 9;

				import std.string;

				if(force == ForceOption.alwaysSend || reverseVideo != this.reverseVideo || foreground != _currentForeground || background != _currentBackground) {
					writeStringRaw(format("\033[%dm\033[3%dm\033[4%dm\033[%dm",
						(foreground != Color.DEFAULT && (foreground & Bright)) ? 1 : 0,
						cast(int) setTof,
						cast(int) setTob,
						reverseVideo ? 7 : 27
					));
				}
			}
		}

		_currentForeground = foreground;
		_currentBackground = background;
		this.reverseVideo = reverseVideo;
	}

	private bool _underlined = false;

	/// Note: the Windows console does not support underlining
	void underline(bool set, ForceOption force = ForceOption.automatic) {
		if(set == _underlined && force != ForceOption.alwaysSend)
			return;
		version(Posix) {
			if(set)
				writeStringRaw("\033[4m");
			else
				writeStringRaw("\033[24m");
		}
		_underlined = set;
	}
	// FIXME: do I want to do bold and italic?

	/// Returns the terminal to normal output colors
	void reset() {
		version(Windows)
			SetConsoleTextAttribute(
				hConsole,
				originalSbi.wAttributes);
		else
			writeStringRaw("\033[0m");

		_underlined = false;
		_currentForeground = Color.DEFAULT;
		_currentBackground = Color.DEFAULT;
		reverseVideo = false;
	}

	// FIXME: add moveRelative

	/// The current x position of the output cursor. 0 == leftmost column
	@property int cursorX() {
		return _cursorX;
	}

	/// The current y position of the output cursor. 0 == topmost row
	@property int cursorY() {
		return _cursorY;
	}

	private int _cursorX;
	private int _cursorY;

	/// Moves the output cursor to the given position. (0, 0) is the upper left corner of the screen. The force parameter can be used to force an update, even if Terminal doesn't think it is necessary
	void moveTo(int x, int y, ForceOption force = ForceOption.automatic) {
		if(force != ForceOption.neverSend && (force == ForceOption.alwaysSend || x != _cursorX || y != _cursorY)) {
			executeAutoHideCursor();
			version(Posix) {
				doTermcap("cm", y, x);
			} else version(Windows) {

				flush(); // if we don't do this now, the buffering can screw up the position
				COORD coord = {cast(short) x, cast(short) y};
				SetConsoleCursorPosition(hConsole, coord);
			} else static assert(0);
		}

		_cursorX = x;
		_cursorY = y;
	}

	/// shows the cursor
	void showCursor() {
		version(Posix)
			doTermcap("ve");
		else {
			CONSOLE_CURSOR_INFO info;
			GetConsoleCursorInfo(hConsole, &info);
			info.bVisible = true;
			SetConsoleCursorInfo(hConsole, &info);
		}
	}

	/// hides the cursor
	void hideCursor() {
		version(Posix) {
			doTermcap("vi");
		} else {
			CONSOLE_CURSOR_INFO info;
			GetConsoleCursorInfo(hConsole, &info);
			info.bVisible = false;
			SetConsoleCursorInfo(hConsole, &info);
		}

	}

	private bool autoHidingCursor;
	private bool autoHiddenCursor;
	// explicitly not publicly documented
	// Sets the cursor to automatically insert a hide command at the front of the output buffer iff it is moved.
	// Call autoShowCursor when you are done with the batch update.
	void autoHideCursor() {
		autoHidingCursor = true;
	}

	private void executeAutoHideCursor() {
		if(autoHidingCursor) {
			version(Windows)
				hideCursor();
			else version(Posix) {
				// prepend the hide cursor command so it is the first thing flushed
				writeBuffer = "\033[?25l" ~ writeBuffer;
			}

			autoHiddenCursor = true;
			autoHidingCursor = false; // already been done, don't insert the command again
		}
	}

	// explicitly not publicly documented
	// Shows the cursor if it was automatically hidden by autoHideCursor and resets the internal auto hide state.
	void autoShowCursor() {
		if(autoHiddenCursor)
			showCursor();

		autoHidingCursor = false;
		autoHiddenCursor = false;
	}

	/*
	// alas this doesn't work due to a bunch of delegate context pointer and postblit problems
	// instead of using: auto input = terminal.captureInput(flags)
	// use: auto input = RealTimeConsoleInput(&terminal, flags);
	/// Gets real time input, disabling line buffering
	RealTimeConsoleInput captureInput(ConsoleInputFlags flags) {
		return RealTimeConsoleInput(&this, flags);
	}
	*/

	/// Changes the terminal's title
	void setTitle(string t) {
		version(Windows) {
			SetConsoleTitleA(toStringz(t));
		} else {
			import std.string;
			if(terminalInFamily("xterm", "rxvt", "screen"))
				writeStringRaw(format("\033]0;%s\007", t));
		}
	}

	/// Flushes your updates to the terminal.
	/// It is important to call this when you are finished writing for now if you are using the version=with_eventloop
	void flush() {
		if(writeBuffer.length == 0)
			return;

		version(Posix) {
			if(_writeDelegate !is null) {
				_writeDelegate(writeBuffer);
			} else {
				ssize_t written;

				while(writeBuffer.length) {
					written = unix.write(this.fdOut, writeBuffer.ptr, writeBuffer.length);
					if(written < 0)
						throw new Exception("write failed for some reason");
					writeBuffer = writeBuffer[written .. $];
				}
			}
		} else version(Windows) {
			import std.conv;
			// FIXME: I'm not sure I'm actually happy with this allocation but
			// it probably isn't a big deal. At least it has unicode support now.
			wstring writeBufferw = to!wstring(writeBuffer);
			while(writeBufferw.length) {
				DWORD written;
				WriteConsoleW(hConsole, writeBufferw.ptr, cast(DWORD)writeBufferw.length, &written, null);
				writeBufferw = writeBufferw[written .. $];
			}

			writeBuffer = null;
		}
	}

	int[] getSize() {
		version(Windows) {
			CONSOLE_SCREEN_BUFFER_INFO info;
			GetConsoleScreenBufferInfo( hConsole, &info );

			int cols, rows;

			cols = (info.srWindow.Right - info.srWindow.Left + 1);
			rows = (info.srWindow.Bottom - info.srWindow.Top + 1);

			return [cols, rows];
		} else {
			if(getSizeOverride is null) {
				winsize w;
				ioctl(0, TIOCGWINSZ, &w);
				return [w.ws_col, w.ws_row];
			} else return getSizeOverride();
		}
	}

	void updateSize() {
		auto size = getSize();
		_width = size[0];
		_height = size[1];
	}

	private int _width;
	private int _height;

	/// The current width of the terminal (the number of columns)
	@property int width() {
		if(_width == 0 || _height == 0)
			updateSize();
		return _width;
	}

	/// The current height of the terminal (the number of rows)
	@property int height() {
		if(_width == 0 || _height == 0)
			updateSize();
		return _height;
	}

	/*
	void write(T...)(T t) {
		foreach(arg; t) {
			writeStringRaw(to!string(arg));
		}
	}
	*/

	/// Writes to the terminal at the current cursor position.
	void writef(T...)(string f, T t) {
		import std.string;
		writePrintableString(format(f, t));
	}

	/// ditto
	void writefln(T...)(string f, T t) {
		writef(f ~ "\n", t);
	}

	/// ditto
	void write(T...)(T t) {
		import std.conv;
		string data;
		foreach(arg; t) {
			data ~= to!string(arg);
		}

		writePrintableString(data);
	}

	/// ditto
	void writeln(T...)(T t) {
		write(t, "\n");
	}

	/+
	/// A combined moveTo and writef that puts the cursor back where it was before when it finishes the write.
	/// Only works in cellular mode.
	/// Might give better performance than moveTo/writef because if the data to write matches the internal buffer, it skips sending anything (to override the buffer check, you can use moveTo and writePrintableString with ForceOption.alwaysSend)
	void writefAt(T...)(int x, int y, string f, T t) {
		import std.string;
		auto toWrite = format(f, t);

		auto oldX = _cursorX;
		auto oldY = _cursorY;

		writeAtWithoutReturn(x, y, toWrite);

		moveTo(oldX, oldY);
	}

	void writeAtWithoutReturn(int x, int y, in char[] data) {
		moveTo(x, y);
		writeStringRaw(toWrite, ForceOption.alwaysSend);
	}
	+/

	void writePrintableString(in char[] s, ForceOption force = ForceOption.automatic) {
		// an escape character is going to mess things up. Actually any non-printable character could, but meh
		// assert(s.indexOf("\033") == -1);

		// tracking cursor position
		foreach(ch; s) {
			switch(ch) {
				case '\n':
					_cursorX = 0;
					_cursorY++;
				break;
				case '\r':
					_cursorX = 0;
				break;
				case '\t':
					_cursorX ++;
					_cursorX += _cursorX % 8; // FIXME: get the actual tabstop, if possible
				break;
				default:
					if(ch <= 127) // way of only advancing once per dchar instead of per code unit
						_cursorX++;
			}

			if(_wrapAround && _cursorX > width) {
				_cursorX = 0;
				_cursorY++;
			}

			if(_cursorY == height)
				_cursorY--;

			/+
			auto index = getIndex(_cursorX, _cursorY);
			if(data[index] != ch) {
				data[index] = ch;
			}
			+/
		}

		writeStringRaw(s);
	}

	/* private */ bool _wrapAround = true;

	deprecated alias writePrintableString writeString; /// use write() or writePrintableString instead

	private string writeBuffer;

	// you really, really shouldn't use this unless you know what you are doing
	/*private*/ void writeStringRaw(in char[] s) {
		// FIXME: make sure all the data is sent, check for errors
		version(Posix) {
			writeBuffer ~= s; // buffer it to do everything at once in flush() calls
		} else version(Windows) {
			writeBuffer ~= s;
		} else static assert(0);
	}

	/// Clears the screen.
	void clear() {
		version(Posix) {
			doTermcap("cl");
		} else version(Windows) {
			// http://support.microsoft.com/kb/99261
			flush();

			DWORD c;
			CONSOLE_SCREEN_BUFFER_INFO csbi;
			DWORD conSize;
			GetConsoleScreenBufferInfo(hConsole, &csbi);
			conSize = csbi.dwSize.X * csbi.dwSize.Y;
			COORD coordScreen;
			FillConsoleOutputCharacterA(hConsole, ' ', conSize, coordScreen, &c);
			FillConsoleOutputAttribute(hConsole, csbi.wAttributes, conSize, coordScreen, &c);
			moveTo(0, 0, ForceOption.alwaysSend);
		}

		_cursorX = 0;
		_cursorY = 0;
	}

	/// gets a line, including user editing. Convenience method around the LineGetter class and RealTimeConsoleInput facilities - use them if you need more control.
	/// You really shouldn't call this if stdin isn't actually a user-interactive terminal! So if you expect people to pipe data to your app, check for that or use something else.
	// FIXME: add a method to make it easy to check if stdin is actually a tty and use other methods there.
	string getline(string prompt = null) {
		if(lineGetter is null)
			lineGetter = new LineGetter(&this);
		// since the struct might move (it shouldn't, this should be unmovable!) but since
		// it technically might, I'm updating the pointer before using it just in case.
		lineGetter.terminal = &this;

		if(prompt !is null)
			lineGetter.prompt = prompt;

		auto input = RealTimeConsoleInput(&this, ConsoleInputFlags.raw);
		auto line = lineGetter.getline(&input);

		// lineGetter leaves us exactly where it was when the user hit enter, giving best
		// flexibility to real-time input and cellular programs. The convenience function,
		// however, wants to do what is right in most the simple cases, which is to actually
		// print the line (echo would be enabled without RealTimeConsoleInput anyway and they
		// did hit enter), so we'll do that here too.
		writePrintableString("\n");

		return line;
	}

}

/+
struct ConsoleBuffer {
	int cursorX;
	int cursorY;
	int width;
	int height;
	dchar[] data;

	void actualize(Terminal* t) {
		auto writer = t.getBufferedWriter();

		this.copyTo(&(t.onScreen));
	}

	void copyTo(ConsoleBuffer* buffer) {
		buffer.cursorX = this.cursorX;
		buffer.cursorY = this.cursorY;
		buffer.width = this.width;
		buffer.height = this.height;
		buffer.data[] = this.data[];
	}
}
+/

/**
 * Encapsulates the stream of input events received from the terminal input.
 */
struct RealTimeConsoleInput {
	@disable this();
	@disable this(this);

	version(Posix) {
		private int fdOut;
		private int fdIn;
		private sigaction_t oldSigWinch;
		private sigaction_t oldSigIntr;
		private sigaction_t oldHupIntr;
		private termios old;
		ubyte[128] hack;
		// apparently termios isn't the size druntime thinks it is (at least on 32 bit, sometimes)....
		// tcgetattr smashed other variables in here too that could create random problems
		// so this hack is just to give some room for that to happen without destroying the rest of the world
	}

	version(Windows) {
		private DWORD oldInput;
		private DWORD oldOutput;
		HANDLE inputHandle;
	}

	private ConsoleInputFlags flags;
	private Terminal* terminal;
	private void delegate()[] destructor;

	/// To capture input, you need to provide a terminal and some flags.
	public this(Terminal* terminal, ConsoleInputFlags flags) {
		this.flags = flags;
		this.terminal = terminal;

		version(Windows) {
			inputHandle = GetStdHandle(STD_INPUT_HANDLE);

			GetConsoleMode(inputHandle, &oldInput);

			DWORD mode = 0;
			mode |= ENABLE_PROCESSED_INPUT /* 0x01 */; // this gives Ctrl+C which we probably want to be similar to linux
			//if(flags & ConsoleInputFlags.size)
			mode |= ENABLE_WINDOW_INPUT /* 0208 */; // gives size etc
			if(flags & ConsoleInputFlags.echo)
				mode |= ENABLE_ECHO_INPUT; // 0x4
			if(flags & ConsoleInputFlags.mouse)
				mode |= ENABLE_MOUSE_INPUT; // 0x10
			// if(flags & ConsoleInputFlags.raw) // FIXME: maybe that should be a separate flag for ENABLE_LINE_INPUT

			SetConsoleMode(inputHandle, mode);
			destructor ~= { SetConsoleMode(inputHandle, oldInput); };


			GetConsoleMode(terminal.hConsole, &oldOutput);
			mode = 0;
			// we want this to match linux too
			mode |= ENABLE_PROCESSED_OUTPUT; /* 0x01 */
			mode |= ENABLE_WRAP_AT_EOL_OUTPUT; /* 0x02 */
			SetConsoleMode(terminal.hConsole, mode);
			destructor ~= { SetConsoleMode(terminal.hConsole, oldOutput); };

			// FIXME: change to UTF8 as well
		}

		version(Posix) {
			this.fdIn = terminal.fdIn;
			this.fdOut = terminal.fdOut;

			if(fdIn != -1) {
				tcgetattr(fdIn, &old);
				auto n = old;

				auto f = ICANON;
				if(!(flags & ConsoleInputFlags.echo))
					f |= ECHO;

				n.c_lflag &= ~f;
				tcsetattr(fdIn, TCSANOW, &n);
			}

			// some weird bug breaks this, https://github.com/robik/ConsoleD/issues/3
			//destructor ~= { tcsetattr(fdIn, TCSANOW, &old); };

			if(flags & ConsoleInputFlags.size) {
				import core.sys.posix.signal;
				sigaction_t n;
				n.sa_handler = &sizeSignalHandler;
				n.sa_mask = cast(sigset_t) 0;
				n.sa_flags = 0;
				sigaction(SIGWINCH, &n, &oldSigWinch);
			}

			{
				import core.sys.posix.signal;
				sigaction_t n;
				n.sa_handler = &interruptSignalHandler;
				n.sa_mask = cast(sigset_t) 0;
				n.sa_flags = 0;
				sigaction(SIGINT, &n, &oldSigIntr);
			}

			{
				import core.sys.posix.signal;
				sigaction_t n;
				n.sa_handler = &hangupSignalHandler;
				n.sa_mask = cast(sigset_t) 0;
				n.sa_flags = 0;
				sigaction(SIGHUP, &n, &oldHupIntr);
			}



			if(flags & ConsoleInputFlags.mouse) {
				// basic button press+release notification

				// FIXME: try to get maximum capabilities from all terminals
				// right now this works well on xterm but rxvt isn't sending movements...

				terminal.writeStringRaw("\033[?1000h");
				destructor ~= { terminal.writeStringRaw("\033[?1000l"); };
				// the MOUSE_HACK env var is for the case where I run screen
				// but set TERM=xterm (which I do from putty). The 1003 mouse mode
				// doesn't work there, breaking mouse support entirely. So by setting
				// MOUSE_HACK=1002 it tells us to use the other mode for a fallback.
				import std.process : environment;
				if(terminal.terminalInFamily("xterm") && environment.get("MOUSE_HACK") != "1002") {
					// this is vt200 mouse with full motion tracking, supported by xterm
					terminal.writeStringRaw("\033[?1003h");
					destructor ~= { terminal.writeStringRaw("\033[?1003l"); };
				} else if(terminal.terminalInFamily("rxvt", "screen") || environment.get("MOUSE_HACK") == "1002") {
					terminal.writeStringRaw("\033[?1002h"); // this is vt200 mouse with press/release and motion notification iff buttons are pressed
					destructor ~= { terminal.writeStringRaw("\033[?1002l"); };
				}
			}
			if(flags & ConsoleInputFlags.paste) {
				if(terminal.terminalInFamily("xterm", "rxvt", "screen")) {
					terminal.writeStringRaw("\033[?2004h"); // bracketed paste mode
					destructor ~= { terminal.writeStringRaw("\033[?2004l"); };
				}
			}

			// try to ensure the terminal is in UTF-8 mode
			if(terminal.terminalInFamily("xterm", "screen", "linux") && !terminal.isMacTerminal()) {
				terminal.writeStringRaw("\033%G");
			}

			terminal.flush();
		}


		version(with_eventloop) {
			import arsd.eventloop;
			version(Windows)
				auto listenTo = inputHandle;
			else version(Posix)
				auto listenTo = this.fdIn;
			else static assert(0, "idk about this OS");

			version(Posix)
			addListener(&signalFired);

			if(listenTo != -1) {
				addFileEventListeners(listenTo, &eventListener, null, null);
				destructor ~= { removeFileEventListeners(listenTo); };
			}
			addOnIdle(&terminal.flush);
			destructor ~= { removeOnIdle(&terminal.flush); };
		}
	}

	version(with_eventloop) {
		version(Posix)
		void signalFired(SignalFired) {
			if(interrupted) {
				interrupted = false;
				send(InputEvent(UserInterruptionEvent(), terminal));
			}
			if(windowSizeChanged)
				send(checkWindowSizeChanged());
			if(hangedUp) {
				hangedUp = false;
				send(InputEvent(HangupEvent(), terminal));
			}
		}

		import arsd.eventloop;
		void eventListener(OsFileHandle fd) {
			auto queue = readNextEvents();
			foreach(event; queue)
				send(event);
		}
	}

	~this() {
		// the delegate thing doesn't actually work for this... for some reason
		version(Posix)
			if(fdIn != -1)
				tcsetattr(fdIn, TCSANOW, &old);

		version(Posix) {
			if(flags & ConsoleInputFlags.size) {
				// restoration
				sigaction(SIGWINCH, &oldSigWinch, null);
			}
			sigaction(SIGINT, &oldSigIntr, null);
			sigaction(SIGHUP, &oldHupIntr, null);
		}

		// we're just undoing everything the constructor did, in reverse order, same criteria
		foreach_reverse(d; destructor)
			d();
	}

	/**
		Returns true if there iff getch() would not block.

		WARNING: kbhit might consume input that would be ignored by getch. This
		function is really only meant to be used in conjunction with getch. Typically,
		you should use a full-fledged event loop if you want all kinds of input. kbhit+getch
		are just for simple keyboard driven applications.
	*/
	bool kbhit() {
		auto got = getch(true);

		if(got == dchar.init)
			return false;

		getchBuffer = got;
		return true;
	}

	/// Check for input, waiting no longer than the number of milliseconds
	bool timedCheckForInput(int milliseconds) {
		version(Windows) {
			auto response = WaitForSingleObject(terminal.hConsole, milliseconds);
			if(response  == 0)
				return true; // the object is ready
			return false;
		} else version(Posix) {
			if(fdIn == -1)
				return false;

			timeval tv;
			tv.tv_sec = 0;
			tv.tv_usec = milliseconds * 1000;

			fd_set fs;
			FD_ZERO(&fs);

			FD_SET(fdIn, &fs);
			if(select(fdIn + 1, &fs, null, null, &tv) == -1) {
				return false;
			}

			return FD_ISSET(fdIn, &fs);
		}
	}

	/* private */ bool anyInput_internal() {
		if(inputQueue.length || timedCheckForInput(0))
			return true;
		version(Posix)
			if(interrupted || windowSizeChanged || hangedUp)
				return true;
		return false;
	}

	private dchar getchBuffer;

	/// Get one key press from the terminal, discarding other
	/// events in the process. Returns dchar.init upon receiving end-of-file.
	///
	/// Be aware that this may return non-character key events, like F1, F2, arrow keys, etc., as private use Unicode characters. Check them against KeyboardEvent.Key if you like.
	dchar getch(bool nonblocking = false) {
		if(getchBuffer != dchar.init) {
			auto a = getchBuffer;
			getchBuffer = dchar.init;
			return a;
		}

		if(nonblocking && !anyInput_internal())
			return dchar.init;

		auto event = nextEvent();
		while(event.type != InputEvent.Type.KeyboardEvent || event.keyboardEvent.pressed == false) {
			if(event.type == InputEvent.Type.UserInterruptionEvent)
				throw new UserInterruptionException();
			if(event.type == InputEvent.Type.HangupEvent)
				throw new HangupException();
			if(event.type == InputEvent.Type.EndOfFileEvent)
				return dchar.init;

			if(nonblocking && !anyInput_internal())
				return dchar.init;

			event = nextEvent();
		}
		return event.keyboardEvent.which;
	}

	//char[128] inputBuffer;
	//int inputBufferPosition;
	version(Posix)
	int nextRaw(bool interruptable = false) {
		if(fdIn == -1)
			return 0;

		char[1] buf;
		try_again:
		auto ret = read(fdIn, buf.ptr, buf.length);
		if(ret == 0)
			return 0; // input closed
		if(ret == -1) {
			import core.stdc.errno;
			if(errno == EINTR)
				// interrupted by signal call, quite possibly resize or ctrl+c which we want to check for in the event loop
				if(interruptable)
					return -1;
				else
					goto try_again;
			else
				throw new Exception("read failed");
		}

		//terminal.writef("RAW READ: %d\n", buf[0]);

		if(ret == 1)
			return inputPrefilter ? inputPrefilter(buf[0]) : buf[0];
		else
			assert(0); // read too much, should be impossible
	}

	version(Posix)
		int delegate(char) inputPrefilter;

	version(Posix)
	dchar nextChar(int starting) {
		if(starting <= 127)
			return cast(dchar) starting;
		char[6] buffer;
		int pos = 0;
		buffer[pos++] = cast(char) starting;

		// see the utf-8 encoding for details
		int remaining = 0;
		ubyte magic = starting & 0xff;
		while(magic & 0b1000_000) {
			remaining++;
			magic <<= 1;
		}

		while(remaining && pos < buffer.length) {
			buffer[pos++] = cast(char) nextRaw();
			remaining--;
		}

		import std.utf;
		size_t throwAway; // it insists on the index but we don't care
		return decode(buffer[], throwAway);
	}

	InputEvent checkWindowSizeChanged() {
		auto oldWidth = terminal.width;
		auto oldHeight = terminal.height;
		terminal.updateSize();
		version(Posix)
		windowSizeChanged = false;
		return InputEvent(SizeChangedEvent(oldWidth, oldHeight, terminal.width, terminal.height), terminal);
	}


	// character event
	// non-character key event
	// paste event
	// mouse event
	// size event maybe, and if appropriate focus events

	/// Returns the next event.
	///
	/// Experimental: It is also possible to integrate this into
	/// a generic event loop, currently under -version=with_eventloop and it will
	/// require the module arsd.eventloop (Linux only at this point)
	InputEvent nextEvent() {
		terminal.flush();
		if(inputQueue.length) {
			auto e = inputQueue[0];
			inputQueue = inputQueue[1 .. $];
			return e;
		}

		wait_for_more:
		version(Posix)
		if(interrupted) {
			interrupted = false;
			return InputEvent(UserInterruptionEvent(), terminal);
		}

		version(Posix)
		if(hangedUp) {
			hangedUp = false;
			return InputEvent(HangupEvent(), terminal);
		}

		version(Posix)
		if(windowSizeChanged) {
			return checkWindowSizeChanged();
		}

		auto more = readNextEvents();
		if(!more.length)
			goto wait_for_more; // i used to do a loop (readNextEvents can read something, but it might be discarded by the input filter) but now it goto's above because readNextEvents might be interrupted by a SIGWINCH aka size event so we want to check that at least

		assert(more.length);

		auto e = more[0];
		inputQueue = more[1 .. $];
		return e;
	}

	InputEvent* peekNextEvent() {
		if(inputQueue.length)
			return &(inputQueue[0]);
		return null;
	}

	enum InjectionPosition { head, tail }
	void injectEvent(InputEvent ev, InjectionPosition where) {
		final switch(where) {
			case InjectionPosition.head:
				inputQueue = ev ~ inputQueue;
			break;
			case InjectionPosition.tail:
				inputQueue ~= ev;
			break;
		}
	}

	InputEvent[] inputQueue;

	version(Windows)
	InputEvent[] readNextEvents() {
		terminal.flush(); // make sure all output is sent out before waiting for anything

		INPUT_RECORD[32] buffer;
		DWORD actuallyRead;
			// FIXME: ReadConsoleInputW
		auto success = ReadConsoleInputA(inputHandle, buffer.ptr, buffer.length, &actuallyRead);
		if(success == 0)
			throw new Exception("ReadConsoleInput");

		InputEvent[] newEvents;
		input_loop: foreach(record; buffer[0 .. actuallyRead]) {
			switch(record.EventType) {
				case KEY_EVENT:
					auto ev = record.KeyEvent;
					KeyboardEvent ke;
					CharacterEvent e;
					NonCharacterKeyEvent ne;

					e.eventType = ev.bKeyDown ? CharacterEvent.Type.Pressed : CharacterEvent.Type.Released;
					ne.eventType = ev.bKeyDown ? NonCharacterKeyEvent.Type.Pressed : NonCharacterKeyEvent.Type.Released;

					ke.pressed = ev.bKeyDown ? true : false;

					// only send released events when specifically requested
					if(!(flags & ConsoleInputFlags.releasedKeys) && !ev.bKeyDown)
						break;

					e.modifierState = ev.dwControlKeyState;
					ne.modifierState = ev.dwControlKeyState;
					ke.modifierState = ev.dwControlKeyState;

					if(ev.UnicodeChar) {
						// new style event goes first
						ke.which = cast(dchar) cast(wchar) ev.UnicodeChar;
						newEvents ~= InputEvent(ke, terminal);

						// old style event then follows as the fallback
						e.character = cast(dchar) cast(wchar) ev.UnicodeChar;
						newEvents ~= InputEvent(e, terminal);
					} else {
						// old style event
						ne.key = cast(NonCharacterKeyEvent.Key) ev.wVirtualKeyCode;

						// new style event. See comment on KeyboardEvent.Key
						ke.which = cast(KeyboardEvent.Key) (ev.wVirtualKeyCode + 0xF0000);

						// FIXME: make this better. the goal is to make sure the key code is a valid enum member
						// Windows sends more keys than Unix and we're doing lowest common denominator here
						foreach(member; __traits(allMembers, NonCharacterKeyEvent.Key))
							if(__traits(getMember, NonCharacterKeyEvent.Key, member) == ne.key) {
								newEvents ~= InputEvent(ke, terminal);
								newEvents ~= InputEvent(ne, terminal);
								break;
							}
					}
				break;
				case MOUSE_EVENT:
					auto ev = record.MouseEvent;
					MouseEvent e;

					e.modifierState = ev.dwControlKeyState;
					e.x = ev.dwMousePosition.X;
					e.y = ev.dwMousePosition.Y;

					switch(ev.dwEventFlags) {
						case 0:
							//press or release
							e.eventType = MouseEvent.Type.Pressed;
							static DWORD lastButtonState;
							auto lastButtonState2 = lastButtonState;
							e.buttons = ev.dwButtonState;
							lastButtonState = e.buttons;

							// this is sent on state change. if fewer buttons are pressed, it must mean released
							if(cast(DWORD) e.buttons < lastButtonState2) {
								e.eventType = MouseEvent.Type.Released;
								// if last was 101 and now it is 100, then button far right was released
								// so we flip the bits, ~100 == 011, then and them: 101 & 011 == 001, the
								// button that was released
								e.buttons = lastButtonState2 & ~e.buttons;
							}
						break;
						case MOUSE_MOVED:
							e.eventType = MouseEvent.Type.Moved;
							e.buttons = ev.dwButtonState;
						break;
						case 0x0004/*MOUSE_WHEELED*/:
							e.eventType = MouseEvent.Type.Pressed;
							if(ev.dwButtonState > 0)
								e.buttons = MouseEvent.Button.ScrollDown;
							else
								e.buttons = MouseEvent.Button.ScrollUp;
						break;
						default:
							continue input_loop;
					}

					newEvents ~= InputEvent(e, terminal);
				break;
				case WINDOW_BUFFER_SIZE_EVENT:
					auto ev = record.WindowBufferSizeEvent;
					auto oldWidth = terminal.width;
					auto oldHeight = terminal.height;
					terminal._width = ev.dwSize.X;
					terminal._height = ev.dwSize.Y;
					newEvents ~= InputEvent(SizeChangedEvent(oldWidth, oldHeight, terminal.width, terminal.height), terminal);
				break;
				// FIXME: can we catch ctrl+c here too?
				default:
					// ignore
			}
		}

		return newEvents;
	}

	version(Posix)
	InputEvent[] readNextEvents() {
		terminal.flush(); // make sure all output is sent out before we try to get input

		// we want to starve the read, especially if we're called from an edge-triggered
		// epoll (which might happen in version=with_eventloop.. impl detail there subject
		// to change).
		auto initial = readNextEventsHelper();

		// lol this calls select() inside a function prolly called from epoll but meh,
		// it is the simplest thing that can possibly work. The alternative would be
		// doing non-blocking reads and buffering in the nextRaw function (not a bad idea
		// btw, just a bit more of a hassle).
		while(timedCheckForInput(0)) {
			auto ne = readNextEventsHelper();
			initial ~= ne;
			foreach(n; ne)
				if(n.type == InputEvent.Type.EndOfFileEvent)
					return initial; // hit end of file, get out of here lest we infinite loop
					// (select still returns info available even after we read end of file)
		}
		return initial;
	}

	// The helper reads just one actual event from the pipe...
	version(Posix)
	InputEvent[] readNextEventsHelper() {
		InputEvent[] charPressAndRelease(dchar character) {
			if((flags & ConsoleInputFlags.releasedKeys))
				return [
					// new style event
					InputEvent(KeyboardEvent(true, character, 0), terminal),
					InputEvent(KeyboardEvent(false, character, 0), terminal),
					// old style event
					InputEvent(CharacterEvent(CharacterEvent.Type.Pressed, character, 0), terminal),
					InputEvent(CharacterEvent(CharacterEvent.Type.Released, character, 0), terminal),
				];
			else return [
				// new style event
				InputEvent(KeyboardEvent(true, character, 0), terminal),
				// old style event
				InputEvent(CharacterEvent(CharacterEvent.Type.Pressed, character, 0), terminal)
			];
		}
		InputEvent[] keyPressAndRelease(NonCharacterKeyEvent.Key key, uint modifiers = 0) {
			if((flags & ConsoleInputFlags.releasedKeys))
				return [
					// new style event FIXME: when the old events are removed, kill the +0xF0000 from here!
					InputEvent(KeyboardEvent(true, cast(dchar)(key) + 0xF0000, modifiers), terminal),
					InputEvent(KeyboardEvent(false, cast(dchar)(key) + 0xF0000, modifiers), terminal),
					// old style event
					InputEvent(NonCharacterKeyEvent(NonCharacterKeyEvent.Type.Pressed, key, modifiers), terminal),
					InputEvent(NonCharacterKeyEvent(NonCharacterKeyEvent.Type.Released, key, modifiers), terminal),
				];
			else return [
				// new style event FIXME: when the old events are removed, kill the +0xF0000 from here!
				InputEvent(KeyboardEvent(true, cast(dchar)(key) + 0xF0000, modifiers), terminal),
				// old style event
				InputEvent(NonCharacterKeyEvent(NonCharacterKeyEvent.Type.Pressed, key, modifiers), terminal)
			];
		}

		char[30] sequenceBuffer;

		// this assumes you just read "\033["
		char[] readEscapeSequence(char[] sequence) {
			int sequenceLength = 2;
			sequence[0] = '\033';
			sequence[1] = '[';

			while(sequenceLength < sequence.length) {
				auto n = nextRaw();
				sequence[sequenceLength++] = cast(char) n;
				// I think a [ is supposed to termiate a CSI sequence
				// but the Linux console sends CSI[A for F1, so I'm
				// hacking it to accept that too
				if(n >= 0x40 && !(sequenceLength == 3 && n == '['))
					break;
			}

			return sequence[0 .. sequenceLength];
		}

		InputEvent[] translateTermcapName(string cap) {
			switch(cap) {
				//case "k0":
					//return keyPressAndRelease(NonCharacterKeyEvent.Key.F1);
				case "k1":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F1);
				case "k2":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F2);
				case "k3":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F3);
				case "k4":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F4);
				case "k5":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F5);
				case "k6":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F6);
				case "k7":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F7);
				case "k8":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F8);
				case "k9":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F9);
				case "k;":
				case "k0":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F10);
				case "F1":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F11);
				case "F2":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F12);


				case "kb":
					return charPressAndRelease('\b');
				case "kD":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.Delete);

				case "kd":
				case "do":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.DownArrow);
				case "ku":
				case "up":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.UpArrow);
				case "kl":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.LeftArrow);
				case "kr":
				case "nd":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.RightArrow);

				case "kN":
				case "K5":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.PageDown);
				case "kP":
				case "K2":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.PageUp);

				case "ho": // this might not be a key but my thing sometimes returns it... weird...
				case "kh":
				case "K1":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.Home);
				case "kH":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.End);
				case "kI":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.Insert);
				default:
					// don't know it, just ignore
					//import std.stdio;
					//writeln(cap);
			}

			return null;
		}


		InputEvent[] doEscapeSequence(in char[] sequence) {
			switch(sequence) {
				case "\033[200~":
					// bracketed paste begin
					// we want to keep reading until
					// "\033[201~":
					// and build a paste event out of it


					string data;
					for(;;) {
						auto n = nextRaw();
						if(n == '\033') {
							n = nextRaw();
							if(n == '[') {
								auto esc = readEscapeSequence(sequenceBuffer);
								if(esc == "\033[201~") {
									// complete!
									break;
								} else {
									// was something else apparently, but it is pasted, so keep it
									data ~= esc;
								}
							} else {
								data ~= '\033';
								data ~= cast(char) n;
							}
						} else {
							data ~= cast(char) n;
						}
					}
					return [InputEvent(PasteEvent(data), terminal)];
				case "\033[M":
					// mouse event
					auto buttonCode = nextRaw() - 32;
						// nextChar is commented because i'm not using UTF-8 mouse mode
						// cuz i don't think it is as widely supported
					auto x = cast(int) (/*nextChar*/(nextRaw())) - 33; /* they encode value + 32, but make upper left 1,1. I want it to be 0,0 */
					auto y = cast(int) (/*nextChar*/(nextRaw())) - 33; /* ditto */


					bool isRelease = (buttonCode & 0b11) == 3;
					int buttonNumber;
					if(!isRelease) {
						buttonNumber = (buttonCode & 0b11);
						if(buttonCode & 64)
							buttonNumber += 3; // button 4 and 5 are sent as like button 1 and 2, but code | 64
							// so button 1 == button 4 here

						// note: buttonNumber == 0 means button 1 at this point
						buttonNumber++; // hence this


						// apparently this considers middle to be button 2. but i want middle to be button 3.
						if(buttonNumber == 2)
							buttonNumber = 3;
						else if(buttonNumber == 3)
							buttonNumber = 2;
					}

					auto modifiers = buttonCode & (0b0001_1100);
						// 4 == shift
						// 8 == meta
						// 16 == control

					MouseEvent m;

					if(buttonCode & 32)
						m.eventType = MouseEvent.Type.Moved;
					else
						m.eventType = isRelease ? MouseEvent.Type.Released : MouseEvent.Type.Pressed;

					// ugh, if no buttons are pressed, released and moved are indistinguishable...
					// so we'll count the buttons down, and if we get a release
					static int buttonsDown = 0;
					if(!isRelease && buttonNumber <= 3) // exclude wheel "presses"...
						buttonsDown++;

					if(isRelease && m.eventType != MouseEvent.Type.Moved) {
						if(buttonsDown)
							buttonsDown--;
						else // no buttons down, so this should be a motion instead..
							m.eventType = MouseEvent.Type.Moved;
					}


					if(buttonNumber == 0)
						m.buttons = 0; // we don't actually know :(
					else
						m.buttons = 1 << (buttonNumber - 1); // I prefer flags so that's how we do it
					m.x = x;
					m.y = y;
					m.modifierState = modifiers;

					return [InputEvent(m, terminal)];
				default:
					// look it up in the termcap key database
					auto cap = terminal.findSequenceInTermcap(sequence);
					if(cap !is null) {
						return translateTermcapName(cap);
					} else {
						if(terminal.terminalInFamily("xterm")) {
							import std.conv, std.string;
							auto terminator = sequence[$ - 1];
							auto parts = sequence[2 .. $ - 1].split(";");
							// parts[0] and terminator tells us the key
							// parts[1] tells us the modifierState

							uint modifierState;

							int modGot;
							if(parts.length > 1)
								modGot = to!int(parts[1]);
							mod_switch: switch(modGot) {
								case 2: modifierState |= ModifierState.shift; break;
								case 3: modifierState |= ModifierState.alt; break;
								case 4: modifierState |= ModifierState.shift | ModifierState.alt; break;
								case 5: modifierState |= ModifierState.control; break;
								case 6: modifierState |= ModifierState.shift | ModifierState.control; break;
								case 7: modifierState |= ModifierState.alt | ModifierState.control; break;
								case 8: modifierState |= ModifierState.shift | ModifierState.alt | ModifierState.control; break;
								case 9:
								..
								case 16:
									modifierState |= ModifierState.meta;
									if(modGot != 9) {
										modGot -= 8;
										goto mod_switch;
									}
								break;

								// this is an extension in my own terminal emulator
								case 20:
								..
								case 36:
									modifierState |= ModifierState.windows;
									modGot -= 20;
									goto mod_switch;
								default:
							}

							switch(terminator) {
								case 'A': return keyPressAndRelease(NonCharacterKeyEvent.Key.UpArrow, modifierState);
								case 'B': return keyPressAndRelease(NonCharacterKeyEvent.Key.DownArrow, modifierState);
								case 'C': return keyPressAndRelease(NonCharacterKeyEvent.Key.RightArrow, modifierState);
								case 'D': return keyPressAndRelease(NonCharacterKeyEvent.Key.LeftArrow, modifierState);

								case 'H': return keyPressAndRelease(NonCharacterKeyEvent.Key.Home, modifierState);
								case 'F': return keyPressAndRelease(NonCharacterKeyEvent.Key.End, modifierState);

								case 'P': return keyPressAndRelease(NonCharacterKeyEvent.Key.F1, modifierState);
								case 'Q': return keyPressAndRelease(NonCharacterKeyEvent.Key.F2, modifierState);
								case 'R': return keyPressAndRelease(NonCharacterKeyEvent.Key.F3, modifierState);
								case 'S': return keyPressAndRelease(NonCharacterKeyEvent.Key.F4, modifierState);

								case '~': // others
									switch(parts[0]) {
										case "5": return keyPressAndRelease(NonCharacterKeyEvent.Key.PageUp, modifierState);
										case "6": return keyPressAndRelease(NonCharacterKeyEvent.Key.PageDown, modifierState);
										case "2": return keyPressAndRelease(NonCharacterKeyEvent.Key.Insert, modifierState);
										case "3": return keyPressAndRelease(NonCharacterKeyEvent.Key.Delete, modifierState);

										case "15": return keyPressAndRelease(NonCharacterKeyEvent.Key.F5, modifierState);
										case "17": return keyPressAndRelease(NonCharacterKeyEvent.Key.F6, modifierState);
										case "18": return keyPressAndRelease(NonCharacterKeyEvent.Key.F7, modifierState);
										case "19": return keyPressAndRelease(NonCharacterKeyEvent.Key.F8, modifierState);
										case "20": return keyPressAndRelease(NonCharacterKeyEvent.Key.F9, modifierState);
										case "21": return keyPressAndRelease(NonCharacterKeyEvent.Key.F10, modifierState);
										case "23": return keyPressAndRelease(NonCharacterKeyEvent.Key.F11, modifierState);
										case "24": return keyPressAndRelease(NonCharacterKeyEvent.Key.F12, modifierState);
										default:
									}
								break;

								default:
							}
						} else if(terminal.terminalInFamily("rxvt")) {
							// FIXME: figure these out. rxvt seems to just change the terminator while keeping the rest the same
							// though it isn't consistent. ugh.
						} else {
							// maybe we could do more terminals, but linux doesn't even send it and screen just seems to pass through, so i don't think so; xterm prolly covers most them anyway
							// so this space is semi-intentionally left blank
						}
					}
			}

			return null;
		}

		auto c = nextRaw(true);
		if(c == -1)
			return null; // interrupted; give back nothing so the other level can recheck signal flags
		if(c == 0)
			return [InputEvent(EndOfFileEvent(), terminal)];
		if(c == '\033') {
			if(timedCheckForInput(50)) {
				// escape sequence
				c = nextRaw();
				if(c == '[') { // CSI, ends on anything >= 'A'
					return doEscapeSequence(readEscapeSequence(sequenceBuffer));
				} else if(c == 'O') {
					// could be xterm function key
					auto n = nextRaw();

					char[3] thing;
					thing[0] = '\033';
					thing[1] = 'O';
					thing[2] = cast(char) n;

					auto cap = terminal.findSequenceInTermcap(thing);
					if(cap is null) {
						return keyPressAndRelease(NonCharacterKeyEvent.Key.escape) ~
							charPressAndRelease('O') ~
							charPressAndRelease(thing[2]);
					} else {
						return translateTermcapName(cap);
					}
				} else {
					// I don't know, probably unsupported terminal or just quick user input or something
					return keyPressAndRelease(NonCharacterKeyEvent.Key.escape) ~ charPressAndRelease(nextChar(c));
				}
			} else {
				// user hit escape (or super slow escape sequence, but meh)
				return keyPressAndRelease(NonCharacterKeyEvent.Key.escape);
			}
		} else {
			// FIXME: what if it is neither? we should check the termcap
			auto next = nextChar(c);
			if(next == 127) // some terminals send 127 on the backspace. Let's normalize that.
				next = '\b';
			return charPressAndRelease(next);
		}
	}
}

/// The new style of keyboard event
struct KeyboardEvent {
	bool pressed; ///
	dchar which; ///
	uint modifierState; ///

	///
	bool isCharacter() {
		return !(which >= Key.min && which <= Key.max);
	}

	// these match Windows virtual key codes numerically for simplicity of translation there
	// but are plus a unicode private use area offset so i can cram them in the dchar
	// http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx
	/// .
	enum Key : dchar {
		escape = 0x1b + 0xF0000, /// .
		F1 = 0x70 + 0xF0000, /// .
		F2 = 0x71 + 0xF0000, /// .
		F3 = 0x72 + 0xF0000, /// .
		F4 = 0x73 + 0xF0000, /// .
		F5 = 0x74 + 0xF0000, /// .
		F6 = 0x75 + 0xF0000, /// .
		F7 = 0x76 + 0xF0000, /// .
		F8 = 0x77 + 0xF0000, /// .
		F9 = 0x78 + 0xF0000, /// .
		F10 = 0x79 + 0xF0000, /// .
		F11 = 0x7A + 0xF0000, /// .
		F12 = 0x7B + 0xF0000, /// .
		LeftArrow = 0x25 + 0xF0000, /// .
		RightArrow = 0x27 + 0xF0000, /// .
		UpArrow = 0x26 + 0xF0000, /// .
		DownArrow = 0x28 + 0xF0000, /// .
		Insert = 0x2d + 0xF0000, /// .
		Delete = 0x2e + 0xF0000, /// .
		Home = 0x24 + 0xF0000, /// .
		End = 0x23 + 0xF0000, /// .
		PageUp = 0x21 + 0xF0000, /// .
		PageDown = 0x22 + 0xF0000, /// .
	}


}

/// Deprecated: use KeyboardEvent instead in new programs
/// Input event for characters
struct CharacterEvent {
	/// .
	enum Type {
		Released, /// .
		Pressed /// .
	}

	Type eventType; /// .
	dchar character; /// .
	uint modifierState; /// Don't depend on this to be available for character events
}

/// Deprecated: use KeyboardEvent instead in new programs
struct NonCharacterKeyEvent {
	/// .
	enum Type {
		Released, /// .
		Pressed /// .
	}
	Type eventType; /// .

	// these match Windows virtual key codes numerically for simplicity of translation there
	//http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx
	/// .
	enum Key : int {
		escape = 0x1b, /// .
		F1 = 0x70, /// .
		F2 = 0x71, /// .
		F3 = 0x72, /// .
		F4 = 0x73, /// .
		F5 = 0x74, /// .
		F6 = 0x75, /// .
		F7 = 0x76, /// .
		F8 = 0x77, /// .
		F9 = 0x78, /// .
		F10 = 0x79, /// .
		F11 = 0x7A, /// .
		F12 = 0x7B, /// .
		LeftArrow = 0x25, /// .
		RightArrow = 0x27, /// .
		UpArrow = 0x26, /// .
		DownArrow = 0x28, /// .
		Insert = 0x2d, /// .
		Delete = 0x2e, /// .
		Home = 0x24, /// .
		End = 0x23, /// .
		PageUp = 0x21, /// .
		PageDown = 0x22, /// .
		}
	Key key; /// .

	uint modifierState; /// A mask of ModifierState. Always use by checking modifierState & ModifierState.something, the actual value differs across platforms

}

/// .
struct PasteEvent {
	string pastedText; /// .
}

/// .
struct MouseEvent {
	// these match simpledisplay.d numerically as well
	/// .
	enum Type {
		Moved = 0, /// .
		Pressed = 1, /// .
		Released = 2, /// .
		Clicked, /// .
	}

	Type eventType; /// .

	// note: these should numerically match simpledisplay.d for maximum beauty in my other code
	/// .
	enum Button : uint {
		None = 0, /// .
		Left = 1, /// .
		Middle = 4, /// .
		Right = 2, /// .
		ScrollUp = 8, /// .
		ScrollDown = 16 /// .
	}
	uint buttons; /// A mask of Button
	int x; /// 0 == left side
	int y; /// 0 == top
	uint modifierState; /// shift, ctrl, alt, meta, altgr. Not always available. Always check by using modifierState & ModifierState.something
}

/// When you get this, check terminal.width and terminal.height to see the new size and react accordingly.
struct SizeChangedEvent {
	int oldWidth;
	int oldHeight;
	int newWidth;
	int newHeight;
}

/// the user hitting ctrl+c will send this
/// You should drop what you're doing and perhaps exit when this happens.
struct UserInterruptionEvent {}

/// If the user hangs up (for example, closes the terminal emulator without exiting the app), this is sent.
/// If you receive it, you should generally cleanly exit.
struct HangupEvent {}

/// Sent upon receiving end-of-file from stdin.
struct EndOfFileEvent {}

interface CustomEvent {}

version(Windows)
enum ModifierState : uint {
	shift = 0x10,
	control = 0x8 | 0x4, // 8 == left ctrl, 4 == right ctrl

	// i'm not sure if the next two are available
	alt = 2 | 1, //2 ==left alt, 1 == right alt

	// FIXME: I don't think these are actually available
	windows = 512,
	meta = 4096, // FIXME sanity

	// I don't think this is available on Linux....
	scrollLock = 0x40,
}
else
enum ModifierState : uint {
	shift = 4,
	alt = 2,
	control = 16,
	meta = 8,

	windows = 512 // only available if you are using my terminal emulator; it isn't actually offered on standard linux ones
}

version(DDoc)
///
enum ModifierState : uint {
	///
	shift = 4,
	///
	alt = 2,
	///
	control = 16,

}

/++
	[RealTimeConsoleInput.nextEvent] returns one of these. Check the type, then use the [InputEvent.get|get] method to get the more detailed information about the event.
++/
struct InputEvent {
	/// .
	enum Type {
		KeyboardEvent, /// Keyboard key pressed (or released, where supported)
		CharacterEvent, /// Do not use this in new programs, use KeyboardEvent instead
		NonCharacterKeyEvent, /// Do not use this in new programs, use KeyboardEvent instead
		PasteEvent, /// The user pasted some text. Not always available, the pasted text might come as a series of character events instead.
		MouseEvent, /// only sent if you subscribed to mouse events
		SizeChangedEvent, /// only sent if you subscribed to size events
		UserInterruptionEvent, /// the user hit ctrl+c
		EndOfFileEvent, /// stdin has received an end of file
		HangupEvent, /// the terminal hanged up - for example, if the user closed a terminal emulator
		CustomEvent /// .
	}

	/// .
	@property Type type() { return t; }

	/// Returns a pointer to the terminal associated with this event.
	/// (You can usually just ignore this as there's only one terminal typically.)
	///
	/// It may be null in the case of program-generated events;
	@property Terminal* terminal() { return term; }

	/++
		Gets the specific event instance. First, check the type (such as in a `switch` statement), then extract the correct one from here. Note that the template argument is a $(B value type of the enum above), not a type argument. So to use it, do $(D event.get!(InputEvent.Type.KeyboardEvent)), for example.

		See_Also:

		The event types:
			[KeyboardEvent], [MouseEvent], [SizeChangedEvent],
			[PasteEvent], [UserInterruptionEvent],
			[EndOfFileEvent], [HangupEvent], [CustomEvent]

		And associated functions:
			[RealTimeConsoleInput], [ConsoleInputFlags]
	++/
	@property auto get(Type T)() {
		if(type != T)
			throw new Exception("Wrong event type");
		static if(T == Type.CharacterEvent)
			return characterEvent;
		else static if(T == Type.KeyboardEvent)
			return keyboardEvent;
		else static if(T == Type.NonCharacterKeyEvent)
			return nonCharacterKeyEvent;
		else static if(T == Type.PasteEvent)
			return pasteEvent;
		else static if(T == Type.MouseEvent)
			return mouseEvent;
		else static if(T == Type.SizeChangedEvent)
			return sizeChangedEvent;
		else static if(T == Type.UserInterruptionEvent)
			return userInterruptionEvent;
		else static if(T == Type.EndOfFileEvent)
			return endOfFileEvent;
		else static if(T == Type.HangupEvent)
			return hangupEvent;
		else static if(T == Type.CustomEvent)
			return customEvent;
		else static assert(0, "Type " ~ T.stringof ~ " not added to the get function");
	}

	/// custom event is public because otherwise there's no point at all
	this(CustomEvent c, Terminal* p = null) {
		t = Type.CustomEvent;
		customEvent = c;
	}

	private {
		this(CharacterEvent c, Terminal* p) {
			t = Type.CharacterEvent;
			characterEvent = c;
		}
		this(KeyboardEvent c, Terminal* p) {
			t = Type.KeyboardEvent;
			keyboardEvent = c;
		}
		this(NonCharacterKeyEvent c, Terminal* p) {
			t = Type.NonCharacterKeyEvent;
			nonCharacterKeyEvent = c;
		}
		this(PasteEvent c, Terminal* p) {
			t = Type.PasteEvent;
			pasteEvent = c;
		}
		this(MouseEvent c, Terminal* p) {
			t = Type.MouseEvent;
			mouseEvent = c;
		}
		this(SizeChangedEvent c, Terminal* p) {
			t = Type.SizeChangedEvent;
			sizeChangedEvent = c;
		}
		this(UserInterruptionEvent c, Terminal* p) {
			t = Type.UserInterruptionEvent;
			userInterruptionEvent = c;
		}
		this(HangupEvent c, Terminal* p) {
			t = Type.HangupEvent;
			hangupEvent = c;
		}
		this(EndOfFileEvent c, Terminal* p) {
			t = Type.EndOfFileEvent;
			endOfFileEvent = c;
		}

		Type t;
		Terminal* term;

		union {
			KeyboardEvent keyboardEvent;
			CharacterEvent characterEvent;
			NonCharacterKeyEvent nonCharacterKeyEvent;
			PasteEvent pasteEvent;
			MouseEvent mouseEvent;
			SizeChangedEvent sizeChangedEvent;
			UserInterruptionEvent userInterruptionEvent;
			HangupEvent hangupEvent;
			EndOfFileEvent endOfFileEvent;
			CustomEvent customEvent;
		}
	}
}

version(Demo)
/// View the source of this!
void main() {
	auto terminal = Terminal(ConsoleOutputType.cellular);

	//terminal.color(Color.DEFAULT, Color.DEFAULT);

	//
	///*
	auto getter = new FileLineGetter(&terminal, "test");
	getter.prompt = "> ";
	getter.history = ["abcdefghijklmnopqrstuvwzyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
	terminal.writeln("\n" ~ getter.getline());
	terminal.writeln("\n" ~ getter.getline());
	terminal.writeln("\n" ~ getter.getline());
	getter.dispose();
	//*/

	terminal.writeln(terminal.getline());
	terminal.writeln(terminal.getline());
	terminal.writeln(terminal.getline());

	//input.getch();

	// return;
	//

	terminal.setTitle("Basic I/O");
	auto input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.raw | ConsoleInputFlags.allInputEvents);
	terminal.color(Color.green | Bright, Color.black);

	terminal.write("test some long string to see if it wraps or what because i dont really know what it is going to do so i just want to test i think it will wrap but gotta be sure lolololololololol");
	terminal.writefln("%d %d", terminal.cursorX, terminal.cursorY);

	int centerX = terminal.width / 2;
	int centerY = terminal.height / 2;

	bool timeToBreak = false;

	void handleEvent(InputEvent event) {
		terminal.writef("%s\n", event.type);
		final switch(event.type) {
			case InputEvent.Type.UserInterruptionEvent:
			case InputEvent.Type.HangupEvent:
			case InputEvent.Type.EndOfFileEvent:
				timeToBreak = true;
				version(with_eventloop) {
					import arsd.eventloop;
					exit();
				}
			break;
			case InputEvent.Type.SizeChangedEvent:
				auto ev = event.get!(InputEvent.Type.SizeChangedEvent);
				terminal.writeln(ev);
			break;
			case InputEvent.Type.KeyboardEvent:
				auto ev = event.get!(InputEvent.Type.KeyboardEvent);
					terminal.writef("\t%s", ev);
				terminal.writef(" (%s)", cast(KeyboardEvent.Key) ev.which);
				terminal.writeln();
				if(ev.which == 'Q') {
					timeToBreak = true;
					version(with_eventloop) {
						import arsd.eventloop;
						exit();
					}
				}

				if(ev.which == 'C')
					terminal.clear();
			break;
			case InputEvent.Type.CharacterEvent: // obsolete
				auto ev = event.get!(InputEvent.Type.CharacterEvent);
				terminal.writef("\t%s\n", ev);
			break;
			case InputEvent.Type.NonCharacterKeyEvent: // obsolete
				terminal.writef("\t%s\n", event.get!(InputEvent.Type.NonCharacterKeyEvent));
			break;
			case InputEvent.Type.PasteEvent:
				terminal.writef("\t%s\n", event.get!(InputEvent.Type.PasteEvent));
			break;
			case InputEvent.Type.MouseEvent:
				terminal.writef("\t%s\n", event.get!(InputEvent.Type.MouseEvent));
			break;
			case InputEvent.Type.CustomEvent:
			break;
		}

		terminal.writefln("%d %d", terminal.cursorX, terminal.cursorY);

		/*
		if(input.kbhit()) {
			auto c = input.getch();
			if(c == 'q' || c == 'Q')
				break;
			terminal.moveTo(centerX, centerY);
			terminal.writef("%c", c);
			terminal.flush();
		}
		usleep(10000);
		*/
	}

	version(with_eventloop) {
		import arsd.eventloop;
		addListener(&handleEvent);
		loop();
	} else {
		loop: while(true) {
			auto event = input.nextEvent();
			handleEvent(event);
			if(timeToBreak)
				break loop;
		}
	}
}

/**
	FIXME: support lines that wrap
	FIXME: better controls maybe

	FIXME: support multi-line "lines" and some form of line continuation, both
	       from the user (if permitted) and from the application, so like the user
	       hits "class foo { \n" and the app says "that line needs continuation" automatically.

	FIXME: fix lengths on prompt and suggestion

	A note on history:

	To save history, you must call LineGetter.dispose() when you're done with it.
	History will not be automatically saved without that call!

	The history saving and loading as a trivially encountered race condition: if you
	open two programs that use the same one at the same time, the one that closes second
	will overwrite any history changes the first closer saved.

	GNU Getline does this too... and it actually kinda drives me nuts. But I don't know
	what a good fix is except for doing a transactional commit straight to the file every
	time and that seems like hitting the disk way too often.

	We could also do like a history server like a database daemon that keeps the order
	correct but I don't actually like that either because I kinda like different bashes
	to have different history, I just don't like it all to get lost.

	Regardless though, this isn't even used in bash anyway, so I don't think I care enough
	to put that much effort into it. Just using separate files for separate tasks is good
	enough I think.
*/
class LineGetter {
	/* A note on the assumeSafeAppends in here: since these buffers are private, we can be
	   pretty sure that stomping isn't an issue, so I'm using this liberally to keep the
	   append/realloc code simple and hopefully reasonably fast. */

	// saved to file
	string[] history;

	// not saved
	Terminal* terminal;
	string historyFilename;

	/// Make sure that the parent terminal struct remains in scope for the duration
	/// of LineGetter's lifetime, as it does hold on to and use the passed pointer
	/// throughout.
	///
	/// historyFilename will load and save an input history log to a particular folder.
	/// Leaving it null will mean no file will be used and history will not be saved across sessions.
	this(Terminal* tty, string historyFilename = null) {
		this.terminal = tty;
		this.historyFilename = historyFilename;

		line.reserve(128);

		if(historyFilename.length)
			loadSettingsAndHistoryFromFile();

		regularForeground = cast(Color) terminal._currentForeground;
		background = cast(Color) terminal._currentBackground;
		suggestionForeground = Color.blue;
	}

	/// Call this before letting LineGetter die so it can do any necessary
	/// cleanup and save the updated history to a file.
	void dispose() {
		if(historyFilename.length)
			saveSettingsAndHistoryToFile();
	}

	/// Override this to change the directory where history files are stored
	///
	/// Default is $HOME/.arsd-getline on linux and %APPDATA%/arsd-getline/ on Windows.
	/* virtual */ string historyFileDirectory() {
		version(Windows) {
			char[1024] path;
			// FIXME: this doesn't link because the crappy dmd lib doesn't have it
			if(0) { // SHGetFolderPathA(null, CSIDL_APPDATA, null, 0, path.ptr) >= 0) {
				import core.stdc.string;
				return cast(string) path[0 .. strlen(path.ptr)] ~ "\\arsd-getline";
			} else {
				import std.process;
				return environment["APPDATA"] ~ "\\arsd-getline";
			}
		} else version(Posix) {
			import std.process;
			return environment["HOME"] ~ "/.arsd-getline";
		}
	}

	/// You can customize the colors here. You should set these after construction, but before
	/// calling startGettingLine or getline.
	Color suggestionForeground;
	Color regularForeground; /// .
	Color background; /// .
	//bool reverseVideo;

	/// Set this if you want a prompt to be drawn with the line. It does NOT support color in string.
	string prompt;

	/// Turn on auto suggest if you want a greyed thing of what tab
	/// would be able to fill in as you type.
	///
	/// You might want to turn it off if generating a completion list is slow.
	bool autoSuggest = true;


	/// Override this if you don't want all lines added to the history.
	/// You can return null to not add it at all, or you can transform it.
	/* virtual */ string historyFilter(string candidate) {
		return candidate;
	}

	/// You may override this to do nothing
	/* virtual */ void saveSettingsAndHistoryToFile() {
		import std.file;
		if(!exists(historyFileDirectory))
			mkdir(historyFileDirectory);
		auto fn = historyPath();
		import std.stdio;
		auto file = File(fn, "wt");
		foreach(item; history)
			file.writeln(item);
	}

	private string historyPath() {
		import std.path;
		auto filename = historyFileDirectory() ~ dirSeparator ~ historyFilename ~ ".history";
		return filename;
	}

	/// You may override this to do nothing
	/* virtual */ void loadSettingsAndHistoryFromFile() {
		import std.file;
		history = null;
		auto fn = historyPath();
		if(exists(fn)) {
			import std.stdio;
			foreach(line; File(fn, "rt").byLine)
				history ~= line.idup;

		}
	}

	/**
		Override this to provide tab completion. You may use the candidate
		argument to filter the list, but you don't have to (LineGetter will
		do it for you on the values you return).

		Ideally, you wouldn't return more than about ten items since the list
		gets difficult to use if it is too long.

		Default is to provide recent command history as autocomplete.
	*/
	/* virtual */ protected string[] tabComplete(in dchar[] candidate) {
		return history.length > 20 ? history[0 .. 20] : history;
	}

	private string[] filterTabCompleteList(string[] list) {
		if(list.length == 0)
			return list;

		string[] f;
		f.reserve(list.length);

		foreach(item; list) {
			import std.algorithm;
			if(startsWith(item, line[0 .. cursorPosition]))
				f ~= item;
		}

		return f;
	}

	/// Override this to provide a custom display of the tab completion list
	protected void showTabCompleteList(string[] list) {
		if(list.length) {
			// FIXME: allow mouse clicking of an item, that would be cool

			// FIXME: scroll
			//if(terminal.type == ConsoleOutputType.linear) {
				terminal.writeln();
				foreach(item; list) {
					terminal.color(suggestionForeground, background);
					import std.utf;
					auto idx = codeLength!char(line[0 .. cursorPosition]);
					terminal.write("  ", item[0 .. idx]);
					terminal.color(regularForeground, background);
					terminal.writeln(item[idx .. $]);
				}
				updateCursorPosition();
				redraw();
			//}
		}
	}

	/// One-call shop for the main workhorse
	/// If you already have a RealTimeConsoleInput ready to go, you
	/// should pass a pointer to yours here. Otherwise, LineGetter will
	/// make its own.
	public string getline(RealTimeConsoleInput* input = null) {
		startGettingLine();
		if(input is null) {
			auto i = RealTimeConsoleInput(terminal, ConsoleInputFlags.raw | ConsoleInputFlags.allInputEvents);
			while(workOnLine(i.nextEvent())) {}
		} else
			while(workOnLine(input.nextEvent())) {}
		return finishGettingLine();
	}

	private int currentHistoryViewPosition = 0;
	private dchar[] uncommittedHistoryCandidate;
	void loadFromHistory(int howFarBack) {
		if(howFarBack < 0)
			howFarBack = 0;
		if(howFarBack > history.length) // lol signed/unsigned comparison here means if i did this first, before howFarBack < 0, it would totally cycle around.
			howFarBack = cast(int) history.length;
		if(howFarBack == currentHistoryViewPosition)
			return;
		if(currentHistoryViewPosition == 0) {
			// save the current line so we can down arrow back to it later
			if(uncommittedHistoryCandidate.length < line.length) {
				uncommittedHistoryCandidate.length = line.length;
			}

			uncommittedHistoryCandidate[0 .. line.length] = line[];
			uncommittedHistoryCandidate = uncommittedHistoryCandidate[0 .. line.length];
			uncommittedHistoryCandidate.assumeSafeAppend();
		}

		currentHistoryViewPosition = howFarBack;

		if(howFarBack == 0) {
			line.length = uncommittedHistoryCandidate.length;
			line.assumeSafeAppend();
			line[] = uncommittedHistoryCandidate[];
		} else {
			line = line[0 .. 0];
			line.assumeSafeAppend();
			foreach(dchar ch; history[$ - howFarBack])
				line ~= ch;
		}

		cursorPosition = cast(int) line.length;
		scrollToEnd();
	}

	bool insertMode = true;
	bool multiLineMode = false;

	private dchar[] line;
	private int cursorPosition = 0;
	private int horizontalScrollPosition = 0;

	private void scrollToEnd() {
		horizontalScrollPosition = (cast(int) line.length);
		horizontalScrollPosition -= availableLineLength();
		if(horizontalScrollPosition < 0)
			horizontalScrollPosition = 0;
	}

	// used for redrawing the line in the right place
	// and detecting mouse events on our line.
	private int startOfLineX;
	private int startOfLineY;

	// private string[] cachedCompletionList;

	// FIXME
	// /// Note that this assumes the tab complete list won't change between actual
	// /// presses of tab by the user. If you pass it a list, it will use it, but
	// /// otherwise it will keep track of the last one to avoid calls to tabComplete.
	private string suggestion(string[] list = null) {
		import std.algorithm, std.utf;
		auto relevantLineSection = line[0 .. cursorPosition];
		// FIXME: see about caching the list if we easily can
		if(list is null)
			list = filterTabCompleteList(tabComplete(relevantLineSection));

		if(list.length) {
			string commonality = list[0];
			foreach(item; list[1 .. $]) {
				commonality = commonPrefix(commonality, item);
			}

			if(commonality.length) {
				return commonality[codeLength!char(relevantLineSection) .. $];
			}
		}

		return null;
	}

	/// Adds a character at the current position in the line. You can call this too if you hook events for hotkeys or something.
	/// You'll probably want to call redraw() after adding chars.
	void addChar(dchar ch) {
		assert(cursorPosition >= 0 && cursorPosition <= line.length);
		if(cursorPosition == line.length)
			line ~= ch;
		else {
			assert(line.length);
			if(insertMode) {
				line ~= ' ';
				for(int i = cast(int) line.length - 2; i >= cursorPosition; i --)
					line[i + 1] = line[i];
			}
			line[cursorPosition] = ch;
		}
		cursorPosition++;

		if(cursorPosition >= horizontalScrollPosition + availableLineLength())
			horizontalScrollPosition++;
	}

	/// .
	void addString(string s) {
		// FIXME: this could be more efficient
		// but does it matter? these lines aren't super long anyway. But then again a paste could be excessively long (prolly accidental, but still)
		foreach(dchar ch; s)
			addChar(ch);
	}

	/// Deletes the character at the current position in the line.
	/// You'll probably want to call redraw() after deleting chars.
	void deleteChar() {
		if(cursorPosition == line.length)
			return;
		for(int i = cursorPosition; i < line.length - 1; i++)
			line[i] = line[i + 1];
		line = line[0 .. $-1];
		line.assumeSafeAppend();
	}

	///
	void deleteToEndOfLine() {
		while(cursorPosition < line.length)
			deleteChar();
	}

	int availableLineLength() {
		return terminal.width - startOfLineX - cast(int) prompt.length - 1;
	}

	private int lastDrawLength = 0;
	void redraw() {
		terminal.moveTo(startOfLineX, startOfLineY);

		auto lineLength = availableLineLength();
		if(lineLength < 0)
			throw new Exception("too narrow terminal to draw");

		terminal.write(prompt);

		auto towrite = line[horizontalScrollPosition .. $];
		auto cursorPositionToDrawX = cursorPosition - horizontalScrollPosition;
		auto cursorPositionToDrawY = 0;

		if(towrite.length > lineLength) {
			towrite = towrite[0 .. lineLength];
		}

		terminal.write(towrite);

		lineLength -= towrite.length;

		string suggestion;

		if(lineLength >= 0) {
			suggestion = ((cursorPosition == towrite.length) && autoSuggest) ? this.suggestion() : null;
			if(suggestion.length) {
				terminal.color(suggestionForeground, background);
				terminal.write(suggestion);
				terminal.color(regularForeground, background);
			}
		}

		// FIXME: graphemes and utf-8 on suggestion/prompt
		auto written = cast(int) (towrite.length + suggestion.length + prompt.length);

		if(written < lastDrawLength)
		foreach(i; written .. lastDrawLength)
			terminal.write(" ");
		lastDrawLength = written;

		terminal.moveTo(startOfLineX + cursorPositionToDrawX + cast(int) prompt.length, startOfLineY + cursorPositionToDrawY);
	}

	/// Starts getting a new line. Call workOnLine and finishGettingLine afterward.
	///
	/// Make sure that you've flushed your input and output before calling this
	/// function or else you might lose events or get exceptions from this.
	void startGettingLine() {
		// reset from any previous call first
		cursorPosition = 0;
		horizontalScrollPosition = 0;
		justHitTab = false;
		currentHistoryViewPosition = 0;
		if(line.length) {
			line = line[0 .. 0];
			line.assumeSafeAppend();
		}

		updateCursorPosition();
		terminal.showCursor();

		lastDrawLength = availableLineLength();
		redraw();
	}

	private void updateCursorPosition() {
		terminal.flush();

		// then get the current cursor position to start fresh
		version(Windows) {
			CONSOLE_SCREEN_BUFFER_INFO info;
			GetConsoleScreenBufferInfo(terminal.hConsole, &info);
			startOfLineX = info.dwCursorPosition.X;
			startOfLineY = info.dwCursorPosition.Y;
		} else {
			// request current cursor position

			// we have to turn off cooked mode to get this answer, otherwise it will all
			// be messed up. (I hate unix terminals, the Windows way is so much easer.)

			// We also can't use RealTimeConsoleInput here because it also does event loop stuff
			// which would be broken by the child destructor :( (maybe that should be a FIXME)

			ubyte[128] hack2;
			termios old;
			ubyte[128] hack;
			tcgetattr(terminal.fdIn, &old);
			auto n = old;
			n.c_lflag &= ~(ICANON | ECHO);
			tcsetattr(terminal.fdIn, TCSANOW, &n);
			scope(exit)
				tcsetattr(terminal.fdIn, TCSANOW, &old);


			terminal.writeStringRaw("\033[6n");
			terminal.flush();

			import core.sys.posix.unistd;
			// reading directly to bypass any buffering
			ubyte[16] buffer;
			auto len = read(terminal.fdIn, buffer.ptr, buffer.length);
			if(len <= 0)
				throw new Exception("Couldn't get cursor position to initialize get line");
			auto got = buffer[0 .. len];
			if(got.length < 6)
				throw new Exception("not enough cursor reply answer");
			if(got[0] != '\033' || got[1] != '[' || got[$-1] != 'R')
				throw new Exception("wrong answer for cursor position");
			auto gots = cast(char[]) got[2 .. $-1];

			import std.conv;
			import std.string;

			auto pieces = split(gots, ";");
			if(pieces.length != 2) throw new Exception("wtf wrong answer on cursor position");

			startOfLineX = to!int(pieces[1]) - 1;
			startOfLineY = to!int(pieces[0]) - 1;
		}

		// updating these too because I can with the more accurate info from above
		terminal._cursorX = startOfLineX;
		terminal._cursorY = startOfLineY;
	}

	private bool justHitTab;

	/// for integrating into another event loop
	/// you can pass individual events to this and
	/// the line getter will work on it
	///
	/// returns false when there's nothing more to do
	bool workOnLine(InputEvent e) {
		switch(e.type) {
			case InputEvent.Type.EndOfFileEvent:
				justHitTab = false;
				// FIXME: this should be distinct from an empty line when hit at the beginning
				return false;
			//break;
			case InputEvent.Type.KeyboardEvent:
				auto ev = e.keyboardEvent;
				if(ev.pressed == false)
					return true;
				/* Insert the character (unless it is backspace, tab, or some other control char) */
				auto ch = ev.which;
				switch(ch) {
					case 4: // ctrl+d will also send a newline-equivalent
					case '\r':
					case '\n':
						justHitTab = false;
						return false;
					case '\t':
						auto relevantLineSection = line[0 .. cursorPosition];
						auto possibilities = filterTabCompleteList(tabComplete(relevantLineSection));
						import std.utf;

						if(possibilities.length == 1) {
							auto toFill = possibilities[0][codeLength!char(relevantLineSection) .. $];
							if(toFill.length) {
								addString(toFill);
								redraw();
							}
							justHitTab = false;
						} else {
							if(justHitTab) {
								justHitTab = false;
								showTabCompleteList(possibilities);
							} else {
								justHitTab = true;
								/* fill it in with as much commonality as there is amongst all the suggestions */
								auto suggestion = this.suggestion(possibilities);
								if(suggestion.length) {
									addString(suggestion);
									redraw();
								}
							}
						}
					break;
					case '\b':
						justHitTab = false;
						if(cursorPosition) {
							cursorPosition--;
							for(int i = cursorPosition; i < line.length - 1; i++)
								line[i] = line[i + 1];
							line = line[0 .. $ - 1];
							line.assumeSafeAppend();

							if(!multiLineMode) {
								if(horizontalScrollPosition > cursorPosition - 1)
									horizontalScrollPosition = cursorPosition - 1 - availableLineLength();
								if(horizontalScrollPosition < 0)
									horizontalScrollPosition = 0;
							}

							redraw();
						}
					break;
					case KeyboardEvent.Key.LeftArrow:
						justHitTab = false;
						if(cursorPosition)
							cursorPosition--;
						if(!multiLineMode) {
							if(cursorPosition < horizontalScrollPosition)
								horizontalScrollPosition--;
						}

						redraw();
					break;
					case KeyboardEvent.Key.RightArrow:
						justHitTab = false;
						if(cursorPosition < line.length)
							cursorPosition++;
						if(!multiLineMode) {
							if(cursorPosition >= horizontalScrollPosition + availableLineLength())
								horizontalScrollPosition++;
						}

						redraw();
					break;
					case KeyboardEvent.Key.UpArrow:
						justHitTab = false;
						loadFromHistory(currentHistoryViewPosition + 1);
						redraw();
					break;
					case KeyboardEvent.Key.DownArrow:
						justHitTab = false;
						loadFromHistory(currentHistoryViewPosition - 1);
						redraw();
					break;
					case KeyboardEvent.Key.PageUp:
						justHitTab = false;
						loadFromHistory(cast(int) history.length);
						redraw();
					break;
					case KeyboardEvent.Key.PageDown:
						justHitTab = false;
						loadFromHistory(0);
						redraw();
					break;
					case 1: // ctrl+a does home too in the emacs keybindings
					case KeyboardEvent.Key.Home:
						justHitTab = false;
						cursorPosition = 0;
						horizontalScrollPosition = 0;
						redraw();
					break;
					case 5: // ctrl+e from emacs
					case KeyboardEvent.Key.End:
						justHitTab = false;
						cursorPosition = cast(int) line.length;
						scrollToEnd();
						redraw();
					break;
					case KeyboardEvent.Key.Insert:
						justHitTab = false;
						insertMode = !insertMode;
						// FIXME: indicate this on the UI somehow
						// like change the cursor or something
					break;
					case KeyboardEvent.Key.Delete:
						justHitTab = false;
						if(ev.modifierState & ModifierState.control)
							deleteToEndOfLine();
						else
							deleteChar();
						redraw();
					break;
					case 11: // ctrl+k is delete to end of line from emacs
						justHitTab = false;
						deleteToEndOfLine();
						redraw();
					break;
					default:
						justHitTab = false;
						if(e.keyboardEvent.isCharacter)
							addChar(ch);
						redraw();
				}
			break;
			case InputEvent.Type.PasteEvent:
				justHitTab = false;
				addString(e.pasteEvent.pastedText);
				redraw();
			break;
			case InputEvent.Type.MouseEvent:
				/* Clicking with the mouse to move the cursor is so much easier than arrowing
				   or even emacs/vi style movements much of the time, so I'ma support it. */

				auto me = e.mouseEvent;
				if(me.eventType == MouseEvent.Type.Pressed) {
					if(me.buttons & MouseEvent.Button.Left) {
						if(me.y == startOfLineY) {
							// FIXME: prompt.length should be graphemes or at least code poitns
							int p = me.x - startOfLineX - cast(int) prompt.length + horizontalScrollPosition;
							if(p >= 0 && p < line.length) {
								justHitTab = false;
								cursorPosition = p;
								redraw();
							}
						}
					}
				}
			break;
			case InputEvent.Type.SizeChangedEvent:
				/* We'll adjust the bounding box. If you don't like this, handle SizeChangedEvent
				   yourself and then don't pass it to this function. */
				// FIXME
			break;
			case InputEvent.Type.UserInterruptionEvent:
				/* I'll take this as canceling the line. */
				throw new UserInterruptionException();
			//break;
			case InputEvent.Type.HangupEvent:
				/* I'll take this as canceling the line. */
				throw new HangupException();
			//break;
			default:
				/* ignore. ideally it wouldn't be passed to us anyway! */
		}

		return true;
	}

	string finishGettingLine() {
		import std.conv;
		auto f = to!string(line);
		auto history = historyFilter(f);
		if(history !is null)
			this.history ~= history;

		// FIXME: we should hide the cursor if it was hidden in the call to startGettingLine
		return f;
	}
}

/// Adds default constructors that just forward to the superclass
mixin template LineGetterConstructors() {
	this(Terminal* tty, string historyFilename = null) {
		super(tty, historyFilename);
	}
}

/// This is a line getter that customizes the tab completion to
/// fill in file names separated by spaces, like a command line thing.
class FileLineGetter : LineGetter {
	mixin LineGetterConstructors;

	/// You can set this property to tell it where to search for the files
	/// to complete.
	string searchDirectory = ".";

	override protected string[] tabComplete(in dchar[] candidate) {
		import std.file, std.conv, std.algorithm, std.string;
		const(dchar)[] soFar = candidate;
		auto idx = candidate.lastIndexOf(" ");
		if(idx != -1)
			soFar = candidate[idx + 1 .. $];

		string[] list;
		foreach(string name; dirEntries(searchDirectory, SpanMode.breadth)) {
			// try without the ./
			if(startsWith(name[2..$], soFar))
				list ~= text(candidate, name[searchDirectory.length + 1 + soFar.length .. $]);
			else // and with
			if(startsWith(name, soFar))
				list ~= text(candidate, name[soFar.length .. $]);
		}

		return list;
	}
}

version(Windows) {
	// to get the directory for saving history in the line things
	enum CSIDL_APPDATA = 26;
	extern(Windows) HRESULT SHGetFolderPathA(HWND, int, HANDLE, DWORD, LPSTR);
}





/* Like getting a line, printing a lot of lines is kinda important too, so I'm including
   that widget here too. */


struct ScrollbackBuffer {

	bool demandsAttention;

	this(string name) {
		this.name = name;
	}

	void write(T...)(T t) {
		import std.conv : text;
		addComponent(text(t), foreground_, background_, null);
	}

	void writeln(T...)(T t) {
		write(t, "\n");
	}

	void writef(T...)(string fmt, T t) {
		import std.format: format;
		write(format(fmt, t));
	}

	void writefln(T...)(string fmt, T t) {
		writef(fmt, t, "\n");
	}

	void clear() {
		lines = null;
		clickRegions = null;
		scrollbackPosition = 0;
	}

	int foreground_ = Color.DEFAULT, background_ = Color.DEFAULT;
	void color(int foreground, int background) {
		this.foreground_ = foreground;
		this.background_ = background;
	}

	void addComponent(string text, int foreground, int background, bool delegate() onclick) {
		if(lines.length == 0) {
			addLine();
		}
		bool first = true;
		import std.algorithm;
		foreach(t; splitter(text, "\n")) {
			if(!first) addLine();
			first = false;
			lines[$-1].components ~= LineComponent(t, foreground, background, onclick);
		}
	}

	void addLine() {
		lines ~= Line();
		if(scrollbackPosition) // if the user is scrolling back, we want to keep them basically centered where they are
			scrollbackPosition++;
	}

	void addLine(string line) {
		lines ~= Line([LineComponent(line)]);
		if(scrollbackPosition) // if the user is scrolling back, we want to keep them basically centered where they are
			scrollbackPosition++;
	}

	void scrollUp(int lines = 1) {
		scrollbackPosition += lines;
		//if(scrollbackPosition >= this.lines.length)
		//	scrollbackPosition = cast(int) this.lines.length - 1;
	}

	void scrollDown(int lines = 1) {
		scrollbackPosition -= lines;
		if(scrollbackPosition < 0)
			scrollbackPosition = 0;
	}

	void scrollToBottom() {
		scrollbackPosition = 0;
	}

	// this needs width and height to know how to word wrap it
	void scrollToTop(int width, int height) {
		scrollbackPosition = scrollTopPosition(width, height);
	}




	struct LineComponent {
		string text;
		bool isRgb;
		union {
			int color;
			RGB colorRgb;
		}
		union {
			int background;
			RGB backgroundRgb;
		}
		bool delegate() onclick; // return true if you need to redraw

		// 16 color ctor
		this(string text, int color = Color.DEFAULT, int background = Color.DEFAULT, bool delegate() onclick = null) {
			this.text = text;
			this.color = color;
			this.background = background;
			this.onclick = onclick;
			this.isRgb = false;
		}

		// true color ctor
		this(string text, RGB colorRgb, RGB backgroundRgb = RGB(0, 0, 0), bool delegate() onclick = null) {
			this.text = text;
			this.colorRgb = colorRgb;
			this.backgroundRgb = backgroundRgb;
			this.onclick = onclick;
			this.isRgb = true;
		}
	}

	struct Line {
		LineComponent[] components;
		int length() {
			int l = 0;
			foreach(c; components)
				l += c.text.length;
			return l;
		}
	}

	// FIXME: limit scrollback lines.length

	Line[] lines;
	string name;

	int x, y, width, height;

	int scrollbackPosition;


	int scrollTopPosition(int width, int height) {
		int lineCount;

		foreach_reverse(line; lines) {
			int written = 0;
			comp_loop: foreach(cidx, component; line.components) {
				auto towrite = component.text;
				foreach(idx, dchar ch; towrite) {
					if(written >= width) {
						lineCount++;
						written = 0;
					}

					if(ch == '\t')
						written += 8; // FIXME
					else
						written++;
				}
			}
			lineCount++;
		}

		//if(lineCount > height)
			return lineCount - height;
		//return 0;
	}

	void drawInto(Terminal* terminal, in int x = 0, in int y = 0, int width = 0, int height = 0) {
		if(lines.length == 0)
			return;

		if(width == 0)
			width = terminal.width;
		if(height == 0)
			height = terminal.height;

		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;

		/* We need to figure out how much is going to fit
		   in a first pass, so we can figure out where to
		   start drawing */

		int remaining = height + scrollbackPosition;
		int start = cast(int) lines.length;
		int howMany = 0;

		bool firstPartial = false;

		static struct Idx {
			size_t cidx;
			size_t idx;
		}

		Idx firstPartialStartIndex;

		// this is private so I know we can safe append
		clickRegions.length = 0;
		clickRegions.assumeSafeAppend();

		// FIXME: should prolly handle \n and \r in here too.

		// we'll work backwards to figure out how much will fit...
		// this will give accurate per-line things even with changing width and wrapping
		// while being generally efficient - we usually want to show the end of the list
		// anyway; actually using the scrollback is a bit of an exceptional case.

		// It could probably do this instead of on each redraw, on each resize or insertion.
		// or at least cache between redraws until one of those invalidates it.
		foreach_reverse(line; lines) {
			int written = 0;
			int brokenLineCount;
			Idx[16] lineBreaksBuffer;
			Idx[] lineBreaks = lineBreaksBuffer[];
			comp_loop: foreach(cidx, component; line.components) {
				auto towrite = component.text;
				foreach(idx, dchar ch; towrite) {
					if(written >= width) {
						if(brokenLineCount == lineBreaks.length)
							lineBreaks ~= Idx(cidx, idx);
						else
							lineBreaks[brokenLineCount] = Idx(cidx, idx);

						brokenLineCount++;

						written = 0;
					}

					if(ch == '\t')
						written += 8; // FIXME
					else
						written++;
				}
			}

			lineBreaks = lineBreaks[0 .. brokenLineCount];

			foreach_reverse(lineBreak; lineBreaks) {
				if(remaining == 1) {
					firstPartial = true;
					firstPartialStartIndex = lineBreak;
					break;
				} else {
					remaining--;
				}
				if(remaining <= 0)
					break;
			}

			remaining--;

			start--;
			howMany++;
			if(remaining <= 0)
				break;
		}

		// second pass: actually draw it
		int linePos = remaining;

		foreach(idx, line; lines[start .. start + howMany]) {
			int written = 0;

			if(linePos < 0) {
				linePos++;
				continue;
			}

			terminal.moveTo(x, y + ((linePos >= 0) ? linePos : 0));

			auto todo = line.components;

			if(firstPartial) {
				todo = todo[firstPartialStartIndex.cidx .. $];
			}

			foreach(ref component; todo) {
				if(component.isRgb)
					terminal.setTrueColor(component.colorRgb, component.backgroundRgb);
				else
					terminal.color(component.color, component.background);
				auto towrite = component.text;

				again:

				if(linePos >= height)
					break;

				if(firstPartial) {
					towrite = towrite[firstPartialStartIndex.idx .. $];
					firstPartial = false;
				}

				foreach(idx, dchar ch; towrite) {
					if(written >= width) {
						clickRegions ~= ClickRegion(&component, terminal.cursorX, terminal.cursorY, written);
						terminal.write(towrite[0 .. idx]);
						towrite = towrite[idx .. $];
						linePos++;
						written = 0;
						terminal.moveTo(x, y + linePos);
						goto again;
					}

					if(ch == '\t')
						written += 8; // FIXME
					else
						written++;
				}

				if(towrite.length) {
					clickRegions ~= ClickRegion(&component, terminal.cursorX, terminal.cursorY, written);
					terminal.write(towrite);
				}
			}

			if(written < width) {
				terminal.color(Color.DEFAULT, Color.DEFAULT);
				foreach(i; written .. width)
					terminal.write(" ");
			}

			linePos++;

			if(linePos >= height)
				break;
		}

		if(linePos < height) {
			terminal.color(Color.DEFAULT, Color.DEFAULT);
			foreach(i; linePos .. height) {
				if(i >= 0 && i < height) {
					terminal.moveTo(x, y + i);
					foreach(w; 0 .. width)
						terminal.write(" ");
				}
			}
		}
	}

	private struct ClickRegion {
		LineComponent* component;
		int xStart;
		int yStart;
		int length;
	}
	private ClickRegion[] clickRegions;

	/// Default event handling for this widget. Call this only after drawing it into a rectangle
	/// and only if the event ought to be dispatched to it (which you determine however you want;
	/// you could dispatch all events to it, or perhaps filter some out too)
	///
	/// Returns true if it should be redrawn
	bool handleEvent(InputEvent e) {
		final switch(e.type) {
			case InputEvent.Type.KeyboardEvent:
				auto ev = e.keyboardEvent;

				demandsAttention = false;

				switch(ev.which) {
					case KeyboardEvent.Key.UpArrow:
						scrollUp();
						return true;
					case KeyboardEvent.Key.DownArrow:
						scrollDown();
						return true;
					case KeyboardEvent.Key.PageUp:
						scrollUp(height);
						return true;
					case KeyboardEvent.Key.PageDown:
						scrollDown(height);
						return true;
					default:
						// ignore
				}
			break;
			case InputEvent.Type.MouseEvent:
				auto ev = e.mouseEvent;
				if(ev.x >= x && ev.x < x + width && ev.y >= y && ev.y < y + height) {
					demandsAttention = false;
					// it is inside our box, so do something with it
					auto mx = ev.x - x;
					auto my = ev.y - y;

					if(ev.eventType == MouseEvent.Type.Pressed) {
						if(ev.buttons & MouseEvent.Button.Left) {
							foreach(region; clickRegions)
								if(ev.x >= region.xStart && ev.x < region.xStart + region.length && ev.y == region.yStart)
									if(region.component.onclick !is null)
										return region.component.onclick();
						}
						if(ev.buttons & MouseEvent.Button.ScrollUp) {
							scrollUp();
							return true;
						}
						if(ev.buttons & MouseEvent.Button.ScrollDown) {
							scrollDown();
							return true;
						}
					}
				} else {
					// outside our area, free to ignore
				}
			break;
			case InputEvent.Type.SizeChangedEvent:
				// (size changed might be but it needs to be handled at a higher level really anyway)
				// though it will return true because it probably needs redrawing anyway.
				return true;
			case InputEvent.Type.UserInterruptionEvent:
				throw new UserInterruptionException();
			case InputEvent.Type.HangupEvent:
				throw new HangupException();
			case InputEvent.Type.EndOfFileEvent:
				// ignore, not relevant to this
			break;
			case InputEvent.Type.CharacterEvent:
			case InputEvent.Type.NonCharacterKeyEvent:
				// obsolete, ignore them until they are removed
			break;
			case InputEvent.Type.CustomEvent:
			case InputEvent.Type.PasteEvent:
				// ignored, not relevant to us
			break;
		}

		return false;
	}
}


class UserInterruptionException : Exception {
	this() { super("Ctrl+C"); }
}
class HangupException : Exception {
	this() { super("Hup"); }
}



/*

	// more efficient scrolling
	http://msdn.microsoft.com/en-us/library/windows/desktop/ms685113%28v=vs.85%29.aspx
	// and the unix sequences


	rxvt documentation:
	use this to finish the input magic for that


       For the keypad, use Shift to temporarily override Application-Keypad
       setting use Num_Lock to toggle Application-Keypad setting if Num_Lock
       is off, toggle Application-Keypad setting. Also note that values of
       Home, End, Delete may have been compiled differently on your system.

                         Normal       Shift         Control      Ctrl+Shift
       Tab               ^I           ESC [ Z       ^I           ESC [ Z
       BackSpace         ^H           ^?            ^?           ^?
       Find              ESC [ 1 ~    ESC [ 1 $     ESC [ 1 ^    ESC [ 1 @
       Insert            ESC [ 2 ~    paste         ESC [ 2 ^    ESC [ 2 @
       Execute           ESC [ 3 ~    ESC [ 3 $     ESC [ 3 ^    ESC [ 3 @
       Select            ESC [ 4 ~    ESC [ 4 $     ESC [ 4 ^    ESC [ 4 @
       Prior             ESC [ 5 ~    scroll-up     ESC [ 5 ^    ESC [ 5 @
       Next              ESC [ 6 ~    scroll-down   ESC [ 6 ^    ESC [ 6 @
       Home              ESC [ 7 ~    ESC [ 7 $     ESC [ 7 ^    ESC [ 7 @
       End               ESC [ 8 ~    ESC [ 8 $     ESC [ 8 ^    ESC [ 8 @
       Delete            ESC [ 3 ~    ESC [ 3 $     ESC [ 3 ^    ESC [ 3 @
       F1                ESC [ 11 ~   ESC [ 23 ~    ESC [ 11 ^   ESC [ 23 ^
       F2                ESC [ 12 ~   ESC [ 24 ~    ESC [ 12 ^   ESC [ 24 ^
       F3                ESC [ 13 ~   ESC [ 25 ~    ESC [ 13 ^   ESC [ 25 ^
       F4                ESC [ 14 ~   ESC [ 26 ~    ESC [ 14 ^   ESC [ 26 ^
       F5                ESC [ 15 ~   ESC [ 28 ~    ESC [ 15 ^   ESC [ 28 ^
       F6                ESC [ 17 ~   ESC [ 29 ~    ESC [ 17 ^   ESC [ 29 ^
       F7                ESC [ 18 ~   ESC [ 31 ~    ESC [ 18 ^   ESC [ 31 ^
       F8                ESC [ 19 ~   ESC [ 32 ~    ESC [ 19 ^   ESC [ 32 ^
       F9                ESC [ 20 ~   ESC [ 33 ~    ESC [ 20 ^   ESC [ 33 ^
       F10               ESC [ 21 ~   ESC [ 34 ~    ESC [ 21 ^   ESC [ 34 ^
       F11               ESC [ 23 ~   ESC [ 23 $    ESC [ 23 ^   ESC [ 23 @
       F12               ESC [ 24 ~   ESC [ 24 $    ESC [ 24 ^   ESC [ 24 @
       F13               ESC [ 25 ~   ESC [ 25 $    ESC [ 25 ^   ESC [ 25 @
       F14               ESC [ 26 ~   ESC [ 26 $    ESC [ 26 ^   ESC [ 26 @
       F15 (Help)        ESC [ 28 ~   ESC [ 28 $    ESC [ 28 ^   ESC [ 28 @
       F16 (Menu)        ESC [ 29 ~   ESC [ 29 $    ESC [ 29 ^   ESC [ 29 @

       F17               ESC [ 31 ~   ESC [ 31 $    ESC [ 31 ^   ESC [ 31 @
       F18               ESC [ 32 ~   ESC [ 32 $    ESC [ 32 ^   ESC [ 32 @
       F19               ESC [ 33 ~   ESC [ 33 $    ESC [ 33 ^   ESC [ 33 @
       F20               ESC [ 34 ~   ESC [ 34 $    ESC [ 34 ^   ESC [ 34 @
                                                                 Application
       Up                ESC [ A      ESC [ a       ESC O a      ESC O A
       Down              ESC [ B      ESC [ b       ESC O b      ESC O B
       Right             ESC [ C      ESC [ c       ESC O c      ESC O C
       Left              ESC [ D      ESC [ d       ESC O d      ESC O D
       KP_Enter          ^M                                      ESC O M
       KP_F1             ESC O P                                 ESC O P
       KP_F2             ESC O Q                                 ESC O Q
       KP_F3             ESC O R                                 ESC O R
       KP_F4             ESC O S                                 ESC O S
       XK_KP_Multiply    *                                       ESC O j
       XK_KP_Add         +                                       ESC O k
       XK_KP_Separator   ,                                       ESC O l
       XK_KP_Subtract    -                                       ESC O m
       XK_KP_Decimal     .                                       ESC O n
       XK_KP_Divide      /                                       ESC O o
       XK_KP_0           0                                       ESC O p
       XK_KP_1           1                                       ESC O q
       XK_KP_2           2                                       ESC O r
       XK_KP_3           3                                       ESC O s
       XK_KP_4           4                                       ESC O t
       XK_KP_5           5                                       ESC O u
       XK_KP_6           6                                       ESC O v
       XK_KP_7           7                                       ESC O w
       XK_KP_8           8                                       ESC O x
       XK_KP_9           9                                       ESC O y
*/

version(Demo_kbhit)
void main() {
	auto terminal = Terminal(ConsoleOutputType.linear);
	auto input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.raw);

	int a;
	char ch = '.';
	while(a < 1000) {
		a++;
		if(a % terminal.width == 0) {
			terminal.write("\r");
			if(ch == '.')
				ch = ' ';
			else
				ch = '.';
		}

		if(input.kbhit())
			terminal.write(input.getch());
		else
			terminal.write(ch);

		terminal.flush();

		import core.thread;
		Thread.sleep(50.msecs);
	}
}

/*
	The Xterm palette progression is:
	[0, 95, 135, 175, 215, 255]

	So if I take the color and subtract 55, then div 40, I get
	it into one of these areas. If I add 20, I get a reasonable
	rounding.
*/

ubyte colorToXTermPaletteIndex(RGB color) {
	/*
		Here, I will round off to the color ramp or the
		greyscale. I will NOT use the bottom 16 colors because
		there's duplicates (or very close enough) to them in here
	*/

	if(color.r == color.g && color.g == color.b) {
		// grey - find one of them:
		if(color.r == 0) return 0;
		// meh don't need those two, let's simplify branche
		//if(color.r == 0xc0) return 7;
		//if(color.r == 0x80) return 8;
		// it isn't == 255 because it wants to catch anything
		// that would wrap the simple algorithm below back to 0.
		if(color.r >= 248) return 15;

		// there's greys in the color ramp too, but these
		// are all close enough as-is, no need to complicate
		// algorithm for approximation anyway

		return cast(ubyte) (232 + ((color.r - 8) / 10));
	}

	// if it isn't grey, it is color

	// the ramp goes blue, green, red, with 6 of each,
	// so just multiplying will give something good enough

	// will give something between 0 and 5, with some rounding
	auto r = (cast(int) color.r - 35) / 40;
	auto g = (cast(int) color.g - 35) / 40;
	auto b = (cast(int) color.b - 35) / 40;

	return cast(ubyte) (16 + b + g*6 + r*36);
}

/++
	Represents a 24-bit color.


	$(TIP You can convert these to and from [arsd.color.Color] using
	      `.tupleof`:

		---
	      	RGB rgb;
		Color c = Color(rgb.tupleof);
		---
	)
+/
struct RGB {
	ubyte r; ///
	ubyte g; ///
	ubyte b; ///
	// terminal can't actually use this but I want the value
	// there for assignment to an arsd.color.Color
	private ubyte a = 255;
}

// This is an approximation too for a few entries, but a very close one.
RGB xtermPaletteIndexToColor(int paletteIdx) {
	RGB color;

	if(paletteIdx < 16) {
		if(paletteIdx == 7)
			return RGB(0xc0, 0xc0, 0xc0);
		else if(paletteIdx == 8)
			return RGB(0x80, 0x80, 0x80);

		color.r = (paletteIdx & 0b001) ? ((paletteIdx & 0b1000) ? 0xff : 0x80) : 0x00;
		color.g = (paletteIdx & 0b010) ? ((paletteIdx & 0b1000) ? 0xff : 0x80) : 0x00;
		color.b = (paletteIdx & 0b100) ? ((paletteIdx & 0b1000) ? 0xff : 0x80) : 0x00;

	} else if(paletteIdx < 232) {
		// color ramp, 6x6x6 cube
		color.r = cast(ubyte) ((paletteIdx - 16) / 36 * 40 + 55);
		color.g = cast(ubyte) (((paletteIdx - 16) % 36) / 6 * 40 + 55);
		color.b = cast(ubyte) ((paletteIdx - 16) % 6 * 40 + 55);

		if(color.r == 55) color.r = 0;
		if(color.g == 55) color.g = 0;
		if(color.b == 55) color.b = 0;
	} else {
		// greyscale ramp, from 0x8 to 0xee
		color.r = cast(ubyte) (8 + (paletteIdx - 232) * 10);
		color.g = color.r;
		color.b = color.g;
	}

	return color;
}

int approximate16Color(RGB color) {
	int c;
	c |= color.r > 64 ? RED_BIT : 0;
	c |= color.g > 64 ? GREEN_BIT : 0;
	c |= color.b > 64 ? BLUE_BIT : 0;

	c |= (((color.r + color.g + color.b) / 3) > 80) ? Bright : 0;

	return c;
}

/*
void main() {
	auto terminal = Terminal(ConsoleOutputType.linear);
	terminal.setTrueColor(RGB(255, 0, 255), RGB(255, 255, 255));
	terminal.writeln("Hello, world!");
}
*//++
  A module containing custom exceptions for display convenience

  Copyright: © 2017 Szabo Bogdan
  License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
  Authors: Szabo Bogdan
+/

import std.conv;
import std.regex;
import std.exception;
import std.stdio;
import std.string;
import std.algorithm;

import core.demangle;

version (Have_fluent_asserts_core) { } else {
  auto toTestException(Throwable t)
  {
    return t;
  }
}

version (Have_fluent_asserts_core) {

  import fluentasserts.core.base;
  import fluentasserts.core.results;

  ///
  class TestExceptionWrapper : TestException {
    private {
      TestException exception;
      IResult[] results;
    }

    ///
    this(TestException exception, IResult[] results, string fileName, size_t line, Throwable next = null) {
      this.exception = exception;
      this.results = results;

      super(results, fileName, line, next);

      this.msg = exception.msg ~ "\n" ~ this.msg;
    }

    ///
    override void print(ResultPrinter printer) {
      exception.print(printer);

      results.each!(a => a.print(printer));
    }

    ///
    override string toString() {
      return exception.toString ~ results.map!(a => a.toString).join("\n").to!string;
    }
  }

  /// The message of a wrapped exception should contain the original exception


/// Converts a Throwable to a TestException which improves the failure verbosity
TestException toTestException(Throwable t)
{
  auto exception = cast(TestException) t;

  if (exception is null)
  {
    IResult[] results = [cast(IResult) new MessageResult(t.classinfo.name ~ ": " ~ t.msg)];

    if (t.file.indexOf("../") == -1)
    {
      results ~= cast(IResult) new SourceResult(t.file, t.line);
    }

    if (t !is null && t.info !is null)
    {
      results ~= cast(IResult) new StackResult(t.info);
    }

    exception = new TestException(results, t.file, t.line, t);
  } else {
    exception = new TestExceptionWrapper(exception, [ cast(IResult) new StackResult(t.info) ], t.file, t.line, t);
  }

  return exception;
}



/// A structure that allows you to detect which modules are relevant to display
struct ExternalValidator
{

  /// The list of external modules like the standard library or dub dependencies
  string[] externalModules;

  /// Check if the provided name comes from an external dependency
  bool isExternal(const string name)
  {
    auto reversed = name.dup;
    reverse(reversed);

    string substring = name;
    int sum = 0;
    int index = 0;
    foreach (ch; reversed)
    {
      if (ch == ')')
      {
        sum++;
      }

      if (ch == '(')
      {
        sum--;
      }

      if (sum == 0)
      {
        break;
      }
      index++;
    }

    auto tmpSubstring = reversed[index .. $];
    reverse(tmpSubstring);
    substring = tmpSubstring.to!string;

    auto wordEnd = substring.lastIndexOf(' ') + 1;
    auto chainEnd = substring.lastIndexOf(").") + 1;

    if (chainEnd > wordEnd)
    {
      return isExternal(name[0 .. chainEnd]);
    }

    auto functionName = substring[wordEnd .. $];

    return !externalModules.filter!(a => functionName.indexOf(a) == 0).empty;
  }
}


/// Used to display the stack
class StackResult : IResult
{
  static
  {
    ///
    string[] externalModules;
  }

  ///
  Frame[] frames;

  ///
  this(Throwable.TraceInfo t)
  {
    foreach (line; t)
    {

      auto frame = line.to!string.toFrame;
      frame.name = demangle(frame.name).to!string;
      frames ~= frame;
    }
  }

  private
  {
    auto getFrames()
    {
      return frames.until!(a => a.name.indexOf("generated") != -1)
        .until!(a => a.name.indexOf("D5trial") != -1);
    }
  }

  override
  {
    /// Converts the result to a string
    string toString()
    {
      string result = "Stack trace:\n-------------------\n...\n";

      foreach (frame; getFrames)
      {
        result ~= frame.toString ~ "\n";
      }

      return result ~ "...";
    }

    /// Prints the stack using the default writer
    void print(ResultPrinter printer)
    {
      int colorIndex = 0;
      printer.primary("Stack trace:\n-------------------\n...\n");

      auto validator = ExternalValidator(externalModules);

      foreach (frame; getFrames)
      {
        if (validator.isExternal(frame.name))
        {
          printer.primary(frame.toString);
        }
        else
        {
          frame.print(printer);
        }

        printer.primary("\n");
      }

      printer.primary("...");
    }
  }
}


/// Represents a stack frame
struct Frame
{
  ///
  int index = -1;

  ///
  string moduleName;

  ///
  string address;

  ///
  string name;

  ///
  string offset;

  ///
  string file;

  ///
  int line = -1;

  string toString() const {
    string result;

    if(index >= 0) {
      result ~= leftJustifier(index.to!string, 4).to!string;
    }

    result ~= address ~ " ";
    result ~= name == "" ? "????" : name;

    if(moduleName != "") {
      result ~= " at " ~ moduleName;
    }

    if(offset != "") {
      result ~= " + " ~ offset;
    }

    if(file != "") {
      result ~= " (" ~ file;

      if(line > 0) {
        result ~= ":" ~ line.to!string;
      }

      result ~= ")";
    }

    return result;
  }

  void print(ResultPrinter printer)
  {
    if(index >= 0) {
      printer.info(leftJustifier(index.to!string, 4).to!string);
    }

    printer.primary(address ~ " ");
    printer.info(name == "" ? "????" : name);

    if(moduleName != "") {
      printer.primary(" at ");
      printer.info(moduleName);
    }

    if(offset != "") {
      printer.primary(" + ");
      printer.info(offset);
    }

    if(file != "") {
      printer.primary(" (");
      printer.info(file);

      if(line > 0) {
        printer.primary(":");
        printer.info(line.to!string);
      }

      printer.primary(")");
    }
  }
}

/// The frame should convert a frame to string


/// The frame should not output an index < 0 or a line < 0


/// The frame should not output the file if it is missing from the stack


/// The frame should not output the module if it is missing from the stack


/// The frame should not output the offset if it is missing from the stack


/// The frame should display `????` when the name is missing


/// The frame should print all fields


/// The frame should not print an index < 0 or a line < 0


/// The frame should not print the file if it's missing


/// The frame should not print the module if it's missing


/// The frame should not print the offset if it's missing


/// The frame should print ???? when the name is missing


immutable static
{
  string index = `(?P<index>[0-9]+)`;
  string moduleName = `(?P<module>\S+)`;
  string address = `(?P<address>0x[0-9a-fA-F]+)`;
  string name = `(?P<name>.+)`;
  string offset = `(?P<offset>(0x[0-9A-Za-z]+)|([0-9]+))`;
  string file = `(?P<file>.+)`;
  string linePattern = `(?P<line>[0-9]+)`;
}

/// Parse a MacOS string frame
Frame toDarwinFrame(string line)
{
  Frame frame;

  auto darwinPattern = index ~ `(\s+)` ~ moduleName ~ `(\s+)` ~ address ~ `(\s+)`
    ~ name ~ `\s\+\s` ~ offset;

  auto matched = matchFirst(line, darwinPattern);

  frame.index = matched["index"].to!int;
  frame.moduleName = matched["module"];
  frame.address = matched["address"];
  frame.name = matched["name"];
  frame.offset = matched["offset"];

  return frame;
}

/// Parse a Windows string frame
Frame toWindows1Frame(string line)
{
  Frame frame;

  auto matched = matchFirst(line,
      address ~ `(\s+)in(\s+)` ~ name ~ `(\s+)at(\s+)` ~ file ~ `\(` ~ linePattern ~ `\)`); // ~ );

  frame.address = matched["address"];
  frame.name = matched["name"];
  frame.file = matched["file"];
  frame.line = matched["line"].to!int;

  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");
  enforce(frame.file != "", "file not found");

  return frame;
}

/// ditto
Frame toWindows2Frame(string line)
{
  Frame frame;

  auto matched = matchFirst(line, address ~ `(\s+)in(\s+)` ~ name);
  frame.address = matched["address"];
  frame.name = matched["name"];

  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");

  return frame;
}

/// Parse a GLibC string frame
Frame toGLibCFrame(string line)
{
  Frame frame;

  auto matched = matchFirst(line, moduleName ~ `\(` ~ name ~ `\)\s+\[` ~ address ~ `\]`);

  frame.address = matched["address"];
  frame.name = matched["name"];
  frame.moduleName = matched["module"];

  auto plusSign = frame.name.indexOf("+");

  if (plusSign != -1)
  {
    frame.offset = frame.name[plusSign + 1 .. $];
    frame.name = frame.name[0 .. plusSign];
  }

  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");
  enforce(frame.name.indexOf("(") == -1, "name should not contain `(`");
  enforce(frame.moduleName != "", "module not found");

  return frame;
}

/// Parse a NetBsd string frame
Frame toNetBsdFrame(string line)
{
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

/// Parse a Linux frame
Frame toLinuxFrame(string line) {
  Frame frame;

  auto matched = matchFirst(line, file ~ `:` ~ linePattern ~ `\s+` ~ name ~ `\s+\[` ~ address ~ `\]`);

  frame.file = matched["file"];
  frame.name = matched["name"];
  frame.address = matched["address"];
  frame.line = matched["line"].to!int;

  enforce(frame.address != "", "address not found");
  enforce(frame.name != "", "name not found");
  enforce(frame.file != "", "file not found");
  enforce(frame.line > 0, "line not found");

  return frame;
}

/// Converts a stack trace line to a Frame structure
Frame toFrame(string line)
{
  Frame frame;

  try
  {
    return line.toDarwinFrame;
  }
  catch (Exception e)
  {
  }

  try
  {
    return line.toWindows1Frame;
  }
  catch (Exception e)
  {
  }

  try
  {
    return line.toWindows2Frame;
  }
  catch (Exception e)
  {
  }

  try
  {
    return line.toGLibCFrame;
  }
  catch (Exception e)
  {
  }

  try
  {
    return line.toNetBsdFrame;
  }
  catch (Exception e)
  {
  }

  try
  {
    return line.toLinuxFrame;
  }
  catch (Exception e)
  {
  }

  return frame;
}







/// Get the main frame info from linux format


/// Get a function frame info from linux format


/// Get an external function frame info from linux format


/// Get an external function frame info from linux format




}
  int main(string[] arguments) {
      setupLifecycle(Settings(["spec", "result"], ["trial.discovery.unit.UnitTestDiscovery"], false, 0, GlyphSettings(SpecGlyphs(`✓`), SpecStepsGlyphs(`┌`, `└`, `│`), ResultGlyphs(`✖`), DotMatrixGlyphs(`.`,`!`,`?`), LandingGlyphs(`✈`,`━`,`⋅`), ProgressGlyphs(`░`,`▓`))));

      auto testDiscovery0 = new UnitTestDiscovery;
      testDiscovery0.addModule!(`/Users/gedaiu/workspace/should/vibe/fluentasserts/vibe/json.d`, `fluentasserts.vibe.json`);
      testDiscovery0.addModule!(`/Users/gedaiu/workspace/should/vibe/fluentasserts/vibe/request.d`, `fluentasserts.vibe.request`);

      LifeCycleListeners.instance.add(testDiscovery0);


      if(arguments.length > 1 && arguments[1] == "describe") {
        import std.stdio;
        describeTests.toJSONHierarchy.write;
        return 0;
      } else {
        return runTests("").isSuccess ? 0 : 1;
      }
  }

  version (unittest) shared static this()
  {
      import core.runtime;
      Runtime.moduleUnitTester = () => true;
  }