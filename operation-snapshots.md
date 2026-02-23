# Operation Snapshots

This file contains snapshots of all assertion operations with both positive and negated failure variants.

## equal scalar

### Positive fail

```d
expect(5).to.equal(3);
```

```
ASSERTION FAILED: 5 should equal 3.
OPERATION: equal

  ACTUAL: <int> 5
EXPECTED: <int> 3

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(5).to.not.equal(5);
```

```
ASSERTION FAILED: 5 should not equal 5.
OPERATION: not equal

  ACTUAL: <int> 5
EXPECTED: <int> not 5

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## equal string

### Positive fail

```d
expect("hello").to.equal("world");
```

```
ASSERTION FAILED: hello should equal world.
OPERATION: equal

  ACTUAL: <string> hello
EXPECTED: <string> world

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect("hello").to.not.equal("hello");
```

```
ASSERTION FAILED: hello should not equal hello.
OPERATION: not equal

  ACTUAL: <string> hello
EXPECTED: <string> not hello

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## equal array

### Positive fail

```d
expect([1,2,3]).to.equal([1,2,4]);
```

```
ASSERTION FAILED: [1, 2, 3] should equal [1, 2, 4].
OPERATION: equal

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> [1, 2, 4]

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect([1,2,3]).to.not.equal([1,2,3]);
```

```
ASSERTION FAILED: [1, 2, 3] should not equal [1, 2, 3].
OPERATION: not equal

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> not [1, 2, 3]

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## contain string

### Positive fail

```d
expect("hello").to.contain("xyz");
```

```
ASSERTION FAILED: hello should contain xyz xyz is missing from hello.
OPERATION: contain

  ACTUAL: <string> hello
EXPECTED: <string> to contain xyz

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect("hello").to.not.contain("ell");
```

```
ASSERTION FAILED: hello should not contain ell ell is present in hello.
OPERATION: not contain

  ACTUAL: <string> hello
EXPECTED: <string> not to contain ell

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## contain array

### Positive fail

```d
expect([1,2,3]).to.contain(5);
```

```
ASSERTION FAILED: [1, 2, 3] should contain 5. 5 is missing from [1, 2, 3].
OPERATION: contain

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int> to contain 5

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect([1,2,3]).to.not.contain(2);
```

```
ASSERTION FAILED: [1, 2, 3] should not contain 2. 2 is present in [1, 2, 3].
OPERATION: not contain

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int> not to contain 2

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## containOnly

### Positive fail

```d
expect([1,2,3]).to.containOnly([1,2]);
```

```
ASSERTION FAILED: [1, 2, 3] should contain only [1, 2].
OPERATION: containOnly

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> to contain only [1, 2]

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect([1,2,3]).to.not.containOnly([1,2,3]);
```

```
ASSERTION FAILED: [1, 2, 3] should not contain only [1, 2, 3].
OPERATION: not containOnly

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> not to contain only [1, 2, 3]

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## startWith

### Positive fail

```d
expect("hello").to.startWith("xyz");
```

```
ASSERTION FAILED: hello should start with xyz hello does not starts with xyz.
OPERATION: startWith

  ACTUAL: <string> hello
EXPECTED: <string> to start with xyz

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect("hello").to.not.startWith("hel");
```

```
ASSERTION FAILED: hello should not start with hel hello starts with hel.
OPERATION: not startWith

  ACTUAL: <string> hello
EXPECTED: <string> not to start with hel

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## endWith

### Positive fail

```d
expect("hello").to.endWith("xyz");
```

```
ASSERTION FAILED: hello should end with xyz hello does not ends with xyz.
OPERATION: endWith

  ACTUAL: <string> hello
EXPECTED: <string> to end with xyz

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect("hello").to.not.endWith("llo");
```

```
ASSERTION FAILED: hello should not end with llo hello ends with llo.
OPERATION: not endWith

  ACTUAL: <string> hello
EXPECTED: <string> not to end with llo

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## approximately scalar

### Positive fail

```d
expect(0.5).to.be.approximately(0.3, 0.1);
```

```
ASSERTION FAILED: 0.5 should be approximately 0.3±0.1 0.5 is not approximately 0.3±0.1.
OPERATION: approximately

  ACTUAL: <double> 0.5
EXPECTED: <double> 0.3±0.1

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(0.351).to.not.be.approximately(0.35, 0.01);
```

```
ASSERTION FAILED: 0.351 should not be approximately 0.35±0.01 0.351 is approximately 0.35±0.01.
OPERATION: not approximately

  ACTUAL: <double> 0.351
EXPECTED: <double> 0.35±0.01

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## approximately array

### Positive fail

```d
expect([0.5]).to.be.approximately([0.3], 0.1);
```

```
ASSERTION FAILED: [0.5] should be approximately [0.3]±0.1.
OPERATION: approximately

  ACTUAL: <double[]> [0.5]
EXPECTED: <double[]> [0.3±0.1]

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect([0.35]).to.not.be.approximately([0.35], 0.01);
```

```
ASSERTION FAILED: [0.35] should not be approximately [0.35]±0.01.
OPERATION: not approximately

  ACTUAL: <double[]> [0.35]
EXPECTED: <double[]> [0.35±0.01]

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## greaterThan

### Positive fail

```d
expect(3).to.be.greaterThan(5);
```

```
ASSERTION FAILED: 3 should be greater than 5.
OPERATION: greaterThan

  ACTUAL: <int> 3
EXPECTED: <int> greater than 5

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(5).to.not.be.greaterThan(3);
```

```
ASSERTION FAILED: 5 should not be greater than 3.
OPERATION: not greaterThan

  ACTUAL: <int> 5
EXPECTED: <int> less than or equal to 3

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## lessThan

### Positive fail

```d
expect(5).to.be.lessThan(3);
```

```
ASSERTION FAILED: 5 should be less than 3.
OPERATION: lessThan

  ACTUAL: <int> 5
EXPECTED: <int> less than 3

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(3).to.not.be.lessThan(5);
```

```
ASSERTION FAILED: 3 should not be less than 5.
OPERATION: not lessThan

  ACTUAL: <int> 3
EXPECTED: <int> greater than or equal to 5

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## between

### Positive fail

```d
expect(10).to.be.between(1, 5);
```

```
ASSERTION FAILED: 10 should be between 1 and 510 is greater than or equal to 5.
OPERATION: between

  ACTUAL: <int> 10
EXPECTED: <int> a value inside (1, 5) interval

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(3).to.not.be.between(1, 5);
```

```
ASSERTION FAILED: 3 should not be between 1 and 5.
OPERATION: not between

  ACTUAL: <int> 3
EXPECTED: <int> a value outside (1, 5) interval

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## greaterOrEqualTo

### Positive fail

```d
expect(3).to.be.greaterOrEqualTo(5);
```

```
ASSERTION FAILED: 3 should be greater or equal to 5.
OPERATION: greaterOrEqualTo

  ACTUAL: <int> 3
EXPECTED: <int> greater or equal than 5

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(5).to.not.be.greaterOrEqualTo(3);
```

```
ASSERTION FAILED: 5 should not be greater or equal to 3.
OPERATION: not greaterOrEqualTo

  ACTUAL: <int> 5
EXPECTED: <int> less than 3

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## lessOrEqualTo

### Positive fail

```d
expect(5).to.be.lessOrEqualTo(3);
```

```
ASSERTION FAILED: 5 should be less or equal to 3.
OPERATION: lessOrEqualTo

  ACTUAL: <int> 5
EXPECTED: <int> less or equal to 3

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(3).to.not.be.lessOrEqualTo(5);
```

```
ASSERTION FAILED: 3 should not be less or equal to 5.
OPERATION: not lessOrEqualTo

  ACTUAL: <int> 3
EXPECTED: <int> greater than 5

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## instanceOf

### Positive fail

```d
expect(new Object()).to.be.instanceOf!Exception;
```

```
ASSERTION FAILED: Object(XXX) should be instance of "object.Exception". Object(XXX) is instance of object.Object.
OPERATION: instanceOf

  ACTUAL: <object.Object> typeof object.Object
EXPECTED: <object.Exception> typeof object.Exception

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(new Exception("test")).to.not.be.instanceOf!Object;
```

```
ASSERTION FAILED: Exception(XXX) should not be instance of "object.Object". Exception(XXX) is instance of object.Exception.
OPERATION: not instanceOf

  ACTUAL: <object.Exception> typeof object.Exception
EXPECTED: <object.Object> not typeof object.Object

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```

## beNull

### Positive fail

```d
expect(new Object()).to.beNull;
```

```
ASSERTION FAILED: Object(XXX) should be null.
OPERATION: beNull

  ACTUAL: <object.Object> object.Object
EXPECTED: <unknown> null

source/fluentasserts/operations/snapshot.d:XXX
   228:version (unittest) {
   229:  /// Helper to run a positive test and return output string.
   230:  string runPosAndGetOutput(string code)() {
>  231:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   232:    return normalizeSnapshot(eval.toString());
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
   237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
   240:
   241:  /// Helper to run a positive test and return output string for docs (no source location).
   242:  string runPosAndGetDocsOutput(string code)() {
   243:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   244:    return normalizeForDocs(eval.toString());
   245:  }
   246:
   247:  /// Helper to run a negated test and return output string for docs (no source location).
   248:  string runNegAndGetDocsOutput(string code)() {
   249:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   250:    return normalizeForDocs(eval.toString());
   251:  }
   252:
   253:  /// Generates snapshot content for a single test at compile time.
   254:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   255:    enum test = snapshotTests[idx];
   256:
   257:    static void appendContent(ref Appender output) {
   258:      output.put("\n## ");
   259:      output.put(test.name);
   260:      output.put("\n\n### Positive fail\n\n```d\n");
   261:      output.put(test.posCode);
   262:      output.put(";\n```\n\n```\n");
   263:      output.put(runPosAndGetOutput!(test.posCode)());
   264:      output.put("```\n\n### Negated fail\n\n```d\n");
   265:      output.put(test.negCode);
   266:      output.put(";\n```\n\n```\n");
   267:      output.put(runNegAndGetOutput!(test.negCode)());
   268:      output.put("```\n");
   269:    }
   270:  }
   271:
   272:  /// Generates snapshot markdown files for all output formats.
   273:  void generateSnapshotFiles() {
   274:    import std.array : Appender;
   275:
   276:    auto previousFormat = config.output.format;
   277:    scope(exit) config.output.setFormat(previousFormat);
   278:
   279:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   280:      config.output.setFormat(format);
   281:
   282:      Appender!string output;
   283:      string formatName;
   284:      string description;
   285:
   286:      final switch (format) {
   287:        case OutputFormat.verbose:
   288:          formatName = "verbose";
   289:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   290:          break;
   291:        case OutputFormat.compact:
   292:          formatName = "compact";
   293:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   294:          break;
   295:        case OutputFormat.tap:
   296:          formatName = "tap";
   297:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   298:          break;
   299:      }
   300:
   301:      output.put("# Operation Snapshots");
   302:      if (format != OutputFormat.verbose) {
   303:        output.put(" (");
   304:        output.put(formatName);
   305:        output.put(")");
   306:      }
   307:      output.put("\n\n");
   308:      output.put(description);
   309:      output.put("\n");
   310:
   311:      static foreach (i; 0 .. snapshotTests.length) {
   312:        {
   313:          enum test = snapshotTests[i];
   314:          output.put("\n## ");
   315:          output.put(test.name);
   316:          output.put("\n\n### Positive fail\n\n```d\n");
   317:          output.put(test.posCode);
   318:          output.put(";\n```\n\n```\n");
   319:          output.put(runPosAndGetOutput!(test.posCode)());
   320:          output.put("```\n\n### Negated fail\n\n```d\n");
   321:          output.put(test.negCode);
   322:          output.put(";\n```\n\n```\n");
   323:          output.put(runNegAndGetOutput!(test.negCode)());
   324:          output.put("```\n");
   325:        }
   326:      }
   327:
   328:      string filename = format == OutputFormat.verbose
   329:        ? "operation-snapshots.md"
   330:        : "operation-snapshots-" ~ formatName ~ ".md";
   331:
   332:      std.file.write(filename, output[]);
   333:    }
   334:
   335:    generateDocsMdx();
   336:  }
   337:
   338:  /// Generates the MDX documentation file for the docs site.
   339:  void generateDocsMdx() {
   340:    import std.array : Appender;
   341:
   342:    auto previousFormat = config.output.format;
   343:    scope(exit) config.output.setFormat(previousFormat);
   344:
   345:    config.output.setFormat(OutputFormat.verbose);
   346:
   347:    Appender!string output;
   348:
   349:    output.put(`---
   350:title: Operation Snapshots
   351:description: Reference of assertion failure messages for all operations
   352:---
   353:stringLiteral
   354:This page shows what assertion failure messages look like for each operation.
   355:Use this as a reference to understand the output format when tests fail.
   356:stringLiteral
   357:This file is auto-generated from test runs. Do not edit manually.
   358:`);
   359:
   360:    static foreach (i; 0 .. snapshotTests.length) {
   361:      {
   362:        enum test = snapshotTests[i];
   363:        output.put("\n## ");
   364:        output.put(test.name);
   365:        output.put("\n\n### Positive failure\n\n```d\n");
   366:        output.put(test.posCode);
   367:        output.put(";\n```\n\n```\n");
   368:        output.put(runPosAndGetDocsOutput!(test.posCode)());
   369:        output.put("```\n\n### Negated failure\n\n```d\n");
   370:        output.put(test.negCode);
   371:        output.put(";\n```\n\n```\n");
   372:        output.put(runNegAndGetDocsOutput!(test.negCode)());
   373:        output.put("```\n");
   374:      }
   375:    }
   376:
   377:    std.file.write("docs/src/content/docs/api/other/snapshot.mdx", output[]);
   378:  }
   379:
   380:  @("generate snapshot markdown files")
   381:  unittest {
   382:    generateSnapshotFiles();
   383:  }
   384:}
```

### Negated fail

```d
expect(null).to.not.beNull;
```

```
ASSERTION FAILED:  should not be null.
OPERATION: not beNull

  ACTUAL: <null> null
EXPECTED: <unknown> not null

source/fluentasserts/operations/snapshot.d:XXX
   233:  }
   234:
   235:  /// Helper to run a negated test and return output string.
   236:  string runNegAndGetOutput(string code)() {
>  237:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   238:    return normalizeSnapshot(eval.toString());
   239:  }
```
