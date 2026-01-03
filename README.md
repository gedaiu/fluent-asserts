[![Line Coverage](https://szabobogdan3.gitlab.io/fluent-asserts-coverage/coverage-shield.svg)](https://szabobogdan3.gitlab.io/fluent-asserts-coverage/)
[![DUB Version](https://img.shields.io/dub/v/fluent-asserts.svg)](https://code.dlang.org/packages/fluent-asserts)
[![DUB Installs](https://img.shields.io/dub/dt/fluent-asserts.svg)](https://code.dlang.org/packages/fluent-asserts)

[Writing unit tests is easy with Dlang](https://dlang.org/spec/unittest.html). The `unittest` block allows you to start writing tests and to be productive with no special setup.

Unfortunately the [assert expression](https://dlang.org/spec/expression.html#AssertExpression) does not help you to write expressive asserts, and in case of a failure it's hard to find why an assert failed. The `fluent-asserts` library allows you to more naturally specify the expected outcome of a TDD or BDD-style test.

## To begin

1. Add the DUB dependency:
[https://code.dlang.org/packages/fluent-asserts](https://code.dlang.org/packages/fluent-asserts)

```bash
$ dub add fluent-asserts
```

2. Use it:
```D
    unittest {
        true.should.equal(false).because("this is a failing assert");
    }

    unittest {
        Assert.equal(true, false, "this is a failing assert");
    }
```

3. Run the tests:
```D
➜  dub test --compiler=ldc2
```

[![asciicast](https://asciinema.org/a/9x0suc3hanpe67uegtster7o1.png)](https://asciinema.org/a/9x0suc3hanpe67uegtster7o1)

# API Docs

The library provides the `expect`, `should` templates and the `Assert` struct.


## Expect

`expect` is the main assert function exposed by this library. It takes a parameter which is the value that is tested. You can
use any assert operation provided by the base library or any other operations that was registered by a third party library.

```D
Expect expect(T)(lazy T testedValue, ...);
Expect expect(void delegate() callable, ...);
...

expect(testedValue).to.equal(42);
```

In addition, the library provides the `not` and `because` modifiers that allow to improve your asserts.

`not` negates the assert condition:

```D
expect(testedValue).to.not.equal(42);
```

`because` allows you to add a custom message:

```D
    expect(true).to.equal(false).because("of test reasons");
    /// will output this message: Because of test reasons, true should equal `false`.
```

`because` also supports format strings for dynamic messages:

```D
    foreach (i; 0..100) {
        result.should.equal(expected).because("at iteration %s", i);
    }
```

`withContext` attaches key-value debugging data:

```D
    result.should.equal(expected)
        .withContext("userId", 42)
        .withContext("input", testInput);
    /// On failure, displays: CONTEXT: userId = 42, input = ...
```

## Should

`should` is designed to be used in combination with [Uniform Function Call Syntax (UFCS)](https://dlang.org/spec/function.html#pseudo-member), and
is an alias for `expect`.

```D
    auto should(T)(lazy T testData, ...);
```

So the following statements are equivalent

```D
testedValue.should.equal(42);
expect(testedValue).to.equal(42);
```

In addition, you can use `not` and `because` modifiers with `should`.

`not` negates the assert condition:

```D
    testedValue.should.not.equal(42);
    true.should.equal(false).because("of test reasons");
```

## Assert

`Assert` is a wrapper for the expect function, that allows you to use the asserts with a different syntax.

For example, the following lines are equivalent:
```D
    expect(testedValue).to.equal(42);
    Assert.equal(testedValue, 42);
```

All the asserts that are available using the `expect` syntax are available with `Assert`. If you want to negate the check,
just add `not` before the assert name:

```D
    Assert.notEqual(testedValue, 42);
```

## Recording Evaluations

The `recordEvaluation` function allows you to capture the result of an assertion without throwing an exception on failure. This is useful for testing assertion behavior itself, or for inspecting the evaluation result programmatically.

```D
import fluentasserts.core.lifecycle : recordEvaluation;

unittest {
    auto evaluation = ({
        expect(5).to.equal(10);
    }).recordEvaluation;

    // Inspect the evaluation result
    assert(evaluation.result.expected == "10");
    assert(evaluation.result.actual == "5");
}
```

The function:
1. Takes a delegate containing the assertion to execute
2. Temporarily disables failure handling so the test doesn't abort
3. Returns the `Evaluation` struct containing the result

The `Evaluation.result` provides access to:
- `expected` - the expected value as a string
- `actual` - the actual value as a string
- `negated` - whether the assertion was negated with `.not`
- `missing` - array of missing elements (for collection comparisons)
- `extra` - array of extra elements (for collection comparisons)

This is particularly useful when writing tests for custom assertion operations or when you need to verify that assertions produce the correct error messages.

## Assertion Statistics

fluent-asserts tracks assertion counts for monitoring test behavior:

```D
import fluentasserts.core.lifecycle : Lifecycle;

// Run some assertions
expect(1).to.equal(1);
expect("hello").to.contain("ell");

// Access statistics
auto stats = Lifecycle.instance.statistics;
writeln("Total: ", stats.totalAssertions);
writeln("Passed: ", stats.passedAssertions);
writeln("Failed: ", stats.failedAssertions);

// Reset statistics
Lifecycle.instance.resetStatistics();
```

The `AssertionStatistics` struct contains:
- `totalAssertions` - Total number of assertions executed
- `passedAssertions` - Number of assertions that passed
- `failedAssertions` - Number of assertions that failed
- `reset()` - Resets all counters to zero

## Release Build Configuration

By default, fluent-asserts behaves like D's built-in `assert`: assertions are enabled in debug builds and disabled (become no-ops) in release builds. This allows you to use fluent-asserts as a replacement for `assert` in your production code without any runtime overhead in release builds.

**Default behavior:**
- Debug build: assertions enabled
- Release build (`dub build -b release` or `-release` flag): assertions disabled (no-op)

**Force enable in release builds:**

dub.sdl:
```sdl
versions "FluentAssertsDebug"
```

dub.json:
```json
{
    "versions": ["FluentAssertsDebug"]
}
```

**Force disable in all builds:**

dub.sdl:
```sdl
versions "D_Disable_FluentAsserts"
```

dub.json:
```json
{
    "versions": ["D_Disable_FluentAsserts"]
}
```

**Check at compile-time:**
```D
import fluent.asserts;

static if (fluentAssertsEnabled) {
    // assertions are active
} else {
    // assertions are disabled (release build)
}
```

## Custom Assert Handler

During unittest builds, the library automatically installs a custom handler for D's built-in `assert` statements. This provides fluent-asserts style error messages even when using standard `assert`:

```D
unittest {
    assert(1 == 2, "math is broken");
    // Output includes ACTUAL/EXPECTED formatting and source location
}
```

The handler is only active during `version(unittest)` builds, so it won't affect release builds. It is installed using `pragma(crt_constructor)`, which runs before druntime initialization. This approach avoids cyclic module dependency issues that would occur with `static this()`.

If you need to temporarily disable this handler during tests:

```D
import core.exception;

// Save and restore the handler
auto savedHandler = core.exception.assertHandler;
scope(exit) core.exception.assertHandler = savedHandler;

// Disable fluent handler
core.exception.assertHandler = null;
```

## Built in operations



### Memory Assertions

The library provides assertions for checking memory allocations:

```D
// Check GC allocations
({ auto arr = new int[100]; }).should.allocateGCMemory();
({ int x = 5; }).should.not.allocateGCMemory();

// Check non-GC allocations (malloc, etc.)
({
    import core.stdc.stdlib : malloc, free;
    auto p = malloc(1024);
    free(p);
}).should.allocateNonGCMemory();
```

**Note:** Non-GC memory measurement uses process-wide metrics (`mallinfo` on Linux, `phys_footprint` on macOS). This is inherently unreliable during parallel test execution because allocations from other threads are included. For accurate non-GC memory testing, run tests single-threaded with `dub test -- -j1`.

# Extension Libraries

fluent-asserts supports extension libraries that add custom assertions for specific frameworks or types. Extension libraries register their operations automatically when imported.

## Using Extension Libraries

To use an extension library like `fluent-asserts-vibe`:

1. Add the extension library as a dependency in your `dub.json`:

```json
{
    "configurations": [
        {
            "name": "unittest",
            "dependencies": {
                "fluent-asserts": "*",
                "fluent-asserts-vibe": "*"
            }
        }
    ]
}
```

2. Import the extension module in your test file or a shared test fixtures module:

```d
import fluentasserts.vibe.json;
```

The import triggers the extension's `static this()` constructor, which registers its custom operations with the global registry.

3. Use the enhanced assertions:

```d
import vibe.data.json;
import fluentasserts.vibe.json;

unittest {
    auto json1 = `{"key": "value"}`.parseJsonString;
    auto json2 = `{  "key"  :  "value"  }`.parseJsonString;

    // JSON equality ignores whitespace differences
    json1.should.equal(json2);
}
```

## Available Extension Libraries

- **fluent-asserts-vibe** - Adds JSON comparison operations for `vibe.data.json.Json` types with whitespace-insensitive equality, better diff output, and support for comparing `Json` with `Json[]` arrays.

## Creating Extension Libraries

Extension libraries follow a simple pattern:

1. Create operation functions that work with your types
2. Register them in a `static this()` module constructor
3. Optionally register custom serializers for better error output

See the "Registering new operations" section below for details.

# Extend the library

## Registering new operations

Even though this library has an extensive set of operations, sometimes a new operation might be needed to test your code. Operations are functions that receive an `Evaluation` and modify it to indicate success or failure. The operation sets the `expected` and `actual` fields on `evaluation.result` when there is a failure. You can check any of the built in operations for a reference implementation.

```d
void customOperation(ref Evaluation evaluation) @safe nothrow {
    // Perform your check
    bool success = /* your logic */;

    if (!success) {
        evaluation.result.expected = "expected value description";
        evaluation.result.actual = "actual value description";
    }
}
```

Once the operation is ready to use, it has to be registered with the global registry:

```d
static this() {
    // bind the type to different matchers
    Registry.instance.register!(SysTime, SysTime)("between", &customOperation);
    Registry.instance.register!(SysTime, SysTime)("within", &customOperation);

    // or use * to match any type
    Registry.instance.register("*", "*", "customOperation", &customOperation);
}
```

## Registering new serializers

In order to setup an `Evaluation`, the actual and expected values need to be converted to a string. Most of the time, the default serializer will do a great job, but sometimes you might want to add a custom serializer for your types.

```d
static this() {
    HeapSerializerRegistry.instance.register(&jsonToString);
}

string jsonToString(Json value) {
    /// you can add here your custom serializer for Jsons
}
```

# Contributing

Areas for potential improvement:

- **Reduce Evaluator duplication** - `Evaluator`, `TrustedEvaluator`, and `ThrowableEvaluator` share similar code that could be consolidated with templates or mixins.
- **Simplify the Registry** - The type generalization logic could benefit from clearer naming or documentation.
- **Remove ddmp dependency** - For simpler diffs or no diffs, removing the ddmp dependency would simplify the build.
- **Consistent error messages** - Standardize error message patterns across operations for more predictable output.
- **Make source extraction optional** - Source code tokenization runs on every assertion; making it opt-in could improve performance.
- **GC allocation optimization** - Several hot paths use string/array concatenation that could be optimized with `Appender` or pre-allocation.

# License

MIT. See LICENSE for details.
