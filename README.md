# Fluent Asserts [![Build Status](https://travis-ci.org/gedaiu/fluent-asserts.svg?branch=master)](https://travis-ci.org/gedaiu/fluent-asserts)

[Writing unit tests it's easy with Dlang](https://dlang.org/spec/unittest.html). The `unittest` block allows you to start writing tests and to be productive with no special setup. Unfortunely the [assert expresion](https://dlang.org/spec/expression.html#AssertExpression) does not help you to write expressive asserts, and in case of a failure it's hard to find why an assert failed. The `fluent-assert` allow you to more naturally specify the expected outcome of a TDD or BDD-style test.

## Getting started using DUB 

[https://code.dlang.org/packages/fluent-asserts](https://code.dlang.org/packages/fluent-asserts)
Add this project as a dependency inside the `package.json` or `package.sdl` file:

```
    ...

    "dependencies": {
            "fluent-asserts": "~>0.3.0"
    }

    ...
```

Write a failing test:
```
    import std.stdio;
    import fluent.asserts;

    void main()
    {
        writeln("Edit source/app.d to start your project.");
    }


    unittest {
        true.should.equal(false);
    }
```

Run the tests and notice the failing assert:
```
➜  dub test --compiler=ldc2
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