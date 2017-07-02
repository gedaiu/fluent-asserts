# Callable API

[up](../README.md)

Here are the examples of how you can use the `should` function with [exceptions](https://dlang.org/phobos/object.html#.Exception).

## Summary

- [Throw exception](#throw-exception)
- [Throw any exception](#throw-any-exception)
- [Throw something](#throw-something)
- [Execution time](#execution-time)

## Examples

### Throw exception

You can check if some code throws or not Exceptions. The `throwException` template will return a `ThrowableProxy` which for
convience it has all the [Throwable](https://dlang.org/phobos/object.html#.Throwable) properties. A simple way of checking an
exception message is:

```D
    ({
        throw new CustomException("test");
    }).should.throwException!CustomException.msg.should.equal("test");
```

The `ThrowableProxy` it also have a `withMessage` method that returns a new `should` structure, initialized with the exception message:

```D
    ({
        throw new CustomException("test");
    }).should.throwException!CustomException.withMessage.equal("test");
```

Success expectations
```D
    ({
        throw new CustomException("test");
    }).should.throwException!CustomException;

    ({ }).should.not.throwException!CustomException;
```

Failing expectations
```D
    ({
        throw new Exception("test");
    }).should.not.throwException!CustomException;

    ({ }).should.throwException!CustomException;
```

### Throw any exception

The `throwAnyException` assert is an alias for `throwException!Exception`

Success expectations
```D
    ({
        throw new Exception("test");
    }).should.throwAnyException;

    ({ }).should.not.throwAnyException;
```

Failing expectations
```D
    ({
        throw new Exception("test");
    }).should.not.throwAnyException;

    ({ }).should.throwAnyException;
```


### Throw something

The `throwSomething` assert is an alias for `throwException!Throwable`

```D
  ({
    assert(false, "test");
  }).should.throwSomething.withMessage.equal("test");
```

### Execution time

Success expectations
```D
    ({ }).should.haveExecutionTime.lessThan(1.msecs);
```

Failing expectations
```D
    ({
      Thread.sleep(2.msecs);
    }).should.haveExecutionTime.lessThan(1.msecs);
```