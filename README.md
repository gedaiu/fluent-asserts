# Fluent Asserts
[![Build Status](https://travis-ci.org/gedaiu/fluent-asserts.svg?branch=master)](https://travis-ci.org/gedaiu/fluent-asserts)
[![DUB Version](https://img.shields.io/dub/v/fluent-asserts.svg)](https://code.dlang.org/packages/fluent-asserts)
[![DUB Installs](https://img.shields.io/dub/dt/fluent-asserts.svg)](https://code.dlang.org/packages/fluent-asserts)
[![Percentage of issues still open](http://isitmaintained.com/badge/open/gedaiu/fluent-asserts.svg)](http://isitmaintained.com/project/gedaiu/fluent-asserts "Percentage of issues still open")
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/gedaiu/fluent-asserts.svg)](http://isitmaintained.com/project/gedaiu/fluent-asserts "Average time to resolve an issue")

[Writing unit tests is easy with Dlang](https://dlang.org/spec/unittest.html). The `unittest` block allows you to start writing tests and to be productive with no special setup.

Unfortunately the [assert expresion](https://dlang.org/spec/expression.html#AssertExpression) does not help you to write expressive asserts, and in case of a failure it's hard to find why an assert failed. The `fluent-asserts` library allows you to more naturally specify the expected outcome of a TDD or BDD-style test.

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

[![asciicast](https://asciinema.org/a/9x0suc3hanpe67uegtster7o1.png)](https://asciinema.org/a/9x0suc3hanpe67uegtster7o1)

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
- [Objects](api/objects.md)
- [Strings](api/strings.md)
- [Arrays](api/arrays.md)
- [Exceptions](api/exceptions.md)
- [Vibe.d Json](api/vibe-json.md)
- [Vibe.d requests](api/vibe-requests.md)

# License

MIT. See LICENSE for details.
