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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
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
   214:version (unittest) {
   215:  /// Helper to run a positive test and return output string.
   216:  string runPosAndGetOutput(string code)() {
>  217:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   218:    return normalizeSnapshot(eval.toString());
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
   223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
   226:
   227:  /// Generates snapshot content for a single test at compile time.
   228:  mixin template GenerateSnapshotContent(size_t idx, Appender) {
   229:    enum test = snapshotTests[idx];
   230:
   231:    static void appendContent(ref Appender output) {
   232:      output.put("\n## ");
   233:      output.put(test.name);
   234:      output.put("\n\n### Positive fail\n\n```d\n");
   235:      output.put(test.posCode);
   236:      output.put(";\n```\n\n```\n");
   237:      output.put(runPosAndGetOutput!(test.posCode)());
   238:      output.put("```\n\n### Negated fail\n\n```d\n");
   239:      output.put(test.negCode);
   240:      output.put(";\n```\n\n```\n");
   241:      output.put(runNegAndGetOutput!(test.negCode)());
   242:      output.put("```\n");
   243:    }
   244:  }
   245:
   246:  /// Generates snapshot markdown files for all output formats.
   247:  void generateSnapshotFiles() {
   248:    import std.array : Appender;
   249:
   250:    auto previousFormat = config.output.format;
   251:    scope(exit) config.output.setFormat(previousFormat);
   252:
   253:    foreach (format; [OutputFormat.verbose, OutputFormat.compact, OutputFormat.tap]) {
   254:      config.output.setFormat(format);
   255:
   256:      Appender!string output;
   257:      string formatName;
   258:      string description;
   259:
   260:      final switch (format) {
   261:        case OutputFormat.verbose:
   262:          formatName = "verbose";
   263:          description = "This file contains snapshots of all assertion operations with both positive and negated failure variants.";
   264:          break;
   265:        case OutputFormat.compact:
   266:          formatName = "compact";
   267:          description = "This file contains snapshots in compact format (default when CLAUDECODE=1).";
   268:          break;
   269:        case OutputFormat.tap:
   270:          formatName = "tap";
   271:          description = "This file contains snapshots in TAP (Test Anything Protocol) format.";
   272:          break;
   273:      }
   274:
   275:      output.put("# Operation Snapshots");
   276:      if (format != OutputFormat.verbose) {
   277:        output.put(" (");
   278:        output.put(formatName);
   279:        output.put(")");
   280:      }
   281:      output.put("\n\n");
   282:      output.put(description);
   283:      output.put("\n");
   284:
   285:      static foreach (i; 0 .. snapshotTests.length) {
   286:        {
   287:          enum test = snapshotTests[i];
   288:          output.put("\n## ");
   289:          output.put(test.name);
   290:          output.put("\n\n### Positive fail\n\n```d\n");
   291:          output.put(test.posCode);
   292:          output.put(";\n```\n\n```\n");
   293:          output.put(runPosAndGetOutput!(test.posCode)());
   294:          output.put("```\n\n### Negated fail\n\n```d\n");
   295:          output.put(test.negCode);
   296:          output.put(";\n```\n\n```\n");
   297:          output.put(runNegAndGetOutput!(test.negCode)());
   298:          output.put("```\n");
   299:        }
   300:      }
   301:
   302:      string filename = format == OutputFormat.verbose
   303:        ? "operation-snapshots.md"
   304:        : "operation-snapshots-" ~ formatName ~ ".md";
   305:
   306:      std.file.write(filename, output[]);
   307:    }
   308:  }
   309:
   310:  @("generate snapshot markdown files")
   311:  unittest {
   312:    generateSnapshotFiles();
   313:  }
   314:}
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
   219:  }
   220:
   221:  /// Helper to run a negated test and return output string.
   222:  string runNegAndGetOutput(string code)() {
>  223:    mixin("auto eval = recordEvaluation({ " ~ code ~ "; });");
   224:    return normalizeSnapshot(eval.toString());
   225:  }
```
