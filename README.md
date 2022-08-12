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

## Built in operations

- [above](api/above.md)
- [approximately](api/approximately.md)
- [beNull](api/beNull.md)
- [below](api/below.md)
- [between](api/between.md)
- [containOnly](api/containOnly.md)
- [contain](api/contain.md)
- [endWith](api/endWith.md)
- [equal](api/equal.md)
- [greaterOrEqualTo](api/greaterOrEqualTo.md)
- [greaterThan](api/greaterThan.md)
- [instanceOf](api/instanceOf.md)
- [lessOrEqualTo](api/lessOrEqualTo.md)
- [lessThan](api/lessThan.md)
- [startWith](api/startWith.md)
- [throwAnyException](api/throwAnyException.md)
- [throwException](api/throwException.md)
- [throwSomething](api/throwSomething.md)
- [within](api/within.md)

# Extend the library

## Registering new operations

Even though this library has an extensive set of operations, sometimes a new operation might be needed to test your code. Operations are functions that recieve an `Evaluation` and returns an `IResult` list in case there was a failure. You can check any of the built in operations for a refference implementation.

```d
IResult[] customOperation(ref Evaluation evaluation) @safe nothrow {
    ...
}
```

Once the operation is ready to use, it has to be registered with the global registry:

```d
static this() {
    /// bind the type to different matchers
    Registry.instance.register!(SysTime, SysTime)("between", &customOperation);
    Registry.instance.register!(SysTime, SysTime)("within", &customOperation);

    /// or use * to match any type
    Registry.instance.register("*", "*", "customOperation", &customOperation);
}

```

## Registering new serializers

In order to setup an `Evaluation`, the actual and expected values need to be converted to a string. Most of the time, the default serializer will do a great job, but sometimes you might want to add a custom serializer for your types.

```d
static this() {
    SerializerRegistry.instance.register(&jsonToString);
}

string jsonToString(Json value) {
    /// you can add here your custom serializer for Jsons
}
```


# License

MIT. See LICENSE for details.
