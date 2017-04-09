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
```
    should.throwAnyException({
        throw new Exception("test");
    });

    should.not.throwAnyException({ });
```

Failing expectations
```
    should.not.throwAnyException({
        throw new Exception("test");
    });

    should.throwAnyException({ });
```

### Throw exception

Success expectations
```
    should.throwException!CustomException({
        throw new CustomException("test");
    });

    should.not.throwException!CustomException({ });
```

Failing expectations
```
    should.not.throwException!CustomException({
        throw new Exception("test");
    });

    should.throwException!CustomException({ });
```