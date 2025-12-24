# Callable API

[up](../README.md)

Here are the examples of how you can use the `should` function with [exceptions](https://dlang.org/phobos/object.html#.Exception).

## Summary

- [Throw exception](#throw-exception)
- [Throw any exception](#throw-any-exception)
- [Throw something](#throw-something)
- [Execution time](#execution-time)
- [Be null](#be-null)
- [Memory allocations](#memory-allocations)

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

or

```D
    void myFunction() {
        throw new CustomException("test");
    }

    /// This way of testing exceptions does not work with
    /// functions that return arrays or ranges
    myFunction.should.throwException!CustomException.msg.should.equal("test");
```

The `ThrowableProxy` it also have a `withMessage` method that returns a new `should` structure, initialized with the exception message:

```D
    ({
        throw new CustomException("test");
    }).should.throwException!CustomException.withMessage.equal("test");
```

or

```D
    void myFunction() {
        throw new CustomException("test");
    }

    myFunction.should.throwException!CustomException.withMessage.equal("test");
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

### Be null

Success expectations
```D
    void delegate() action;
    action.should.beNull;

    ({ }).should.not.beNull;
```

Failing expectations
```D
    void delegate() action;
    action.should.not.beNull;

    ({ }).should.beNull;
```

### Memory allocations

You can check if a callable allocates memory.

#### GC Memory

Check if a callable allocates memory managed by the garbage collector:

```D
    // Success expectations
    ({ auto arr = new int[100]; }).should.allocateGCMemory();
    ({ int x = 5; }).should.not.allocateGCMemory();

    // Failing expectations
    ({ int x = 5; }).should.allocateGCMemory();
    ({ auto arr = new int[100]; }).should.not.allocateGCMemory();
```

#### Non-GC Memory

Check if a callable allocates memory outside the garbage collector (malloc, C allocators, etc.):

```D
    import core.stdc.stdlib : malloc, free;

    // Success expectations
    ({
        auto p = malloc(1024);
        free(p);
    }).should.allocateNonGCMemory();

    ({ int x = 5; }).should.not.allocateNonGCMemory();
```

**Note:** Non-GC memory measurement uses process-wide metrics:
- **Linux**: `mallinfo()` for malloc arena statistics
- **macOS**: `phys_footprint` from `TASK_VM_INFO`
- **Windows**: Falls back to process memory estimation

This is inherently unreliable during parallel test execution because allocations from other threads are included in the measurement. For accurate non-GC memory testing, run tests single-threaded:

```bash
dub test -- -j1
```
