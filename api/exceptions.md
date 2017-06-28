# Exceptions API

[up](../README.md)

Here are the examples of how you can use the `should` function with [exceptions](https://dlang.org/phobos/object.html#.Exception).

## Summary

- [Throw any exception](#throw-any-exception)
- [Throw exception](#throw-exception)

## Examples

### Throw any exception

The `throwAnyException` exception is an alias for `throwException!Exception`

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

### Throw exception

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
