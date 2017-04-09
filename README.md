# Fluent Asserts [![Build Status](https://travis-ci.org/gedaiu/fluent-asserts.svg?branch=master)](https://travis-ci.org/gedaiu/fluent-asserts)

[Writing unit tests it's easy with Dlang](https://dlang.org/spec/unittest.html). The `unittest` block allows you to start writing tests and to be productive with no special setup. Unfortunely the [assert expresion](https://dlang.org/spec/expression.html#AssertExpression) does not help you to write expressive asserts, and in case of a failure it's hard to find why an assert failed. The `fluent-assert` allow you to more naturally specify the expected outcome of a TDD or BDD-style test.

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

You can use fluent asserts with:

- Basic Data Types
- Strings
- Arrays
- Exceptions
- Vibe.d Json
- Vibe.d requests (Experimental)

# License

MIT. See LICENSE for details.