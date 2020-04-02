[![Build Status](https://travis-ci.org/gedaiu/fluent-asserts.svg?branch=master)](https://travis-ci.org/gedaiu/fluent-asserts)
[![Line Coverage](https://szabobogdan3.gitlab.io/fluent-asserts-coverage/coverage-shield.svg)](https://szabobogdan3.gitlab.io/fluent-asserts-coverage/)
[![DUB Version](https://img.shields.io/dub/v/fluent-asserts.svg)](https://code.dlang.org/packages/fluent-asserts)
[![DUB Installs](https://img.shields.io/dub/dt/fluent-asserts.svg)](https://code.dlang.org/packages/fluent-asserts)
[![Percentage of issues still open](http://isitmaintained.com/badge/open/gedaiu/fluent-asserts.svg)](http://isitmaintained.com/project/gedaiu/fluent-asserts "Percentage of issues still open")
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/gedaiu/fluent-asserts.svg)](http://isitmaintained.com/project/gedaiu/fluent-asserts "Average time to resolve an issue")

[Writing unit tests is easy with Dlang](https://dlang.org/spec/unittest.html). The `unittest` block allows you to start writing tests and to be productive with no special setup.

Unfortunately the [assert expression](https://dlang.org/spec/expression.html#AssertExpression) does not help you to write expressive asserts, and in case of a failure it's hard to find why an assert failed. The `fluent-asserts` library allows you to more naturally specify the expected outcome of a TDD or BDD-style test.

## To begin

1. Add the DUB dependency:
[https://code.dlang.org/packages/fluent-asserts](https://code.dlang.org/packages/fluent-asserts)

2. Import it:

    in `dub.json`:
    ```json
        ...
        "configurations": [
            ...
            {
                "name": "unittest",
                "dependencies": {
                    "fluent-asserts": "~>0.12.3",
                    ...
                }
            },
            ...
        ]
        ...
    ```

    in your source files:
    ```D
    version(unittest) import fluent.asserts;
    ```

3. Use it:
```D
    unittest {
        true.should.equal(false).because("this is a failing assert");
    }

    unittest {
        Assert.equal(true, false, "this is a failing assert");
    }
```

4. Run the tests:
```D
➜  dub test --compiler=ldc2
```

[![asciicast](https://asciinema.org/a/9x0suc3hanpe67uegtster7o1.png)](https://asciinema.org/a/9x0suc3hanpe67uegtster7o1)

# API Docs

The library provides the `should` template and the `Assert` struct.

## Should

`should` can be used in combination with [Uniform Function Call Syntax (UFCS)](https://dlang.org/spec/function.html#pseudo-member)

```D
auto should(T)(lazy const T testData);
```

So the following statements are equivalent

```D
testedValue.should.equal(42);
should(testedValue).equal(42);
```

In addition, the library provides the `not` and `because` modifiers that allow to improve your asserts.

`not` negates the assert condition:

```D
testedValue.should.not.equal(42);
```

`because` allows you to add a custom message:

```D
    true.should.equal(false).because("of test reasons");
    ///will output this message: Because of test reasons, true should equal `false`.
```

## Assert

`Assert` is a wrapper for the should struct that allows you to use the asserts with a different syntax.

For example, the following lines are equivalent:
```D
    testedValue.should.equal(42);
    Assert.equal(testedValue, 42);
```

All the asserts that are available using the `should` syntax are available with `Assert`. If you want to negate the check,
just add `not` before the assert name:

```D
    Assert.notEqual(testedValue, 42);
```

You can use fluent asserts with:

- [Basic Data Types](api/basic.md)
- [Objects](api/objects.md)
- [Strings](api/strings.md)
- [Ranges and Arrays](api/ranges.md)
- [Callable](api/callable.md)
- [Vibe.d Json](api/vibe-json.md)
- [Vibe.d requests](api/vibe-requests.md)

# Do you already have a lot of tests?

If you want to get the failure location for failing tests written using the `Dlang's assert` you can use the
fluent assert handler which will add extra information to the default assert message.

```D
    shared static this() {
        import fluent.asserts;
        setupFluentHandler;
    }
```

# Too much verbosity in the assert messages?

If you want to get less informations when an assert fails, you can use several versions:


- `DisableDiffResult` - will not show a diff for the string equal assert
- `DisableSourceResult` - will not show the source code where the test failed
- `DisableMessageResult` - will not show the defaul message for the assert

In dub.json:
```json
    "versions": [
        "DisableDiffResult",
        "DisableSourceResult",
        "DisableMessageResult"
    ],
```

# License

MIT. See LICENSE for details.
