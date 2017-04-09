# Arrays API

[up](../README.md)

Here are the examples of how you can use the `should` template with [arrays](https://dlang.org/spec/arrays.html).

## Summary

- [Equal](#equal)
- [Contain](#contain)

## Examples

### Equal

Success expectations
```
    [1, 2, 3].should.equal([1, 2, 3]);
    [1, 2, 3].should.not.equal([2, 1, 3]);
```

Failing expectations
```
    [1, 2, 3].should.equal([4, 5]);
    [1, 2, 3].should.equal([2, 3, 1]);
```

### Contain

Success expectations
```
    [1, 2, 3].should.contain([2, 1]);
    [1, 2, 3].should.contain(1);
```

Failing expectations
```
    [1, 2, 3].should.contain([4, 5]);
    [1, 2, 3].should.contain(4);
```