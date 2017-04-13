# Fluent Asserts [![Build Status](https://travis-ci.org/gedaiu/fluent-asserts.svg?branch=master)](https://travis-ci.org/gedaiu/fluent-asserts)

[Writing unit tests is easy with Dlang](https://dlang.org/spec/unittest.html). The `unittest` block allows you to start writing tests and to be productive with no special setup. 

Unfortunately the [assert expresion](https://dlang.org/spec/expression.html#AssertExpression) does not help you to write expressive asserts, and in case of a failure it's hard to find why an assert failed. The `fluent-assert` allows you to more naturally specify the expected outcome of a TDD or BDD-style test.

## To begin

1. Add the DUB dependency:
[https://code.dlang.org/packages/fluent-asserts](https://code.dlang.org/packages/fluent-asserts)

2. Import it:
```
import fluent.asserts;
```

3. Use it:
```
    unittest {
        true.should.equal(false);
    }
```

4. Run the tests:
```
➜  dub test --compiler=ldc2
```

```
No source files found in configuration 'library'. Falling back to "dub -b unittest".
Performing "unittest" build using ldc2 for x86_64.
fluent-asserts:core 0.2.0+commit.16.g05678db: target for configuration "library" is up to date.
fluent-asserts 0.2.0+commit.16.g05678db: target for configuration "library" is up to date.
fluent-test ~master: building configuration "application"...
To force a rebuild of up-to-date targets, run again with --force.
Running ./fluent-test 
fluentasserts.core.base.TestException@source/app.d(11): true should equal `false`. `true` is not equal to `false`.
 --------------------
 source/app.d
 --------------------
     6: 	writeln("Edit source/app.d to start your project.");
     7: }
     8: 
     9: 
    10: unittest {
>   11: 	true.should.equal(false);
    12: }

----------------
Program exited with code 1
```

# API Docs

The library uses the `should` template in combination with 
[Uniform Function Call Syntax (UFCS)](https://dlang.org/spec/function.html#pseudo-member)

```
auto should(T)(lazy const T testData);
```

So the following statements are equivalent

```
exepectedValue.should.equal(42);
should(expectedValue).equal(42);
```

In addition, the library provides a `not` modifier that negates the assert condition:

```
exepectedValue.should.not.equal(42);
```

You can use fluent asserts with:

- [Basic Data Types](api/basic.md)
- [Strings](api/strings.md)
- [Arrays](api/arrays.md)
- [Exceptions](api/exceptions.md)
- [Vibe.d Json](api/vibe-json.md)
- [Vibe.d requests](api/vibe-requests.md)

# License

MIT. See LICENSE for details.
