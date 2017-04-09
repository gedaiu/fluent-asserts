# Basic data types API

[up](../README.md)

Here are the examples of how you can use the `should` template with [basic data types](https://dlang.org/spec/type.html#basic-data-types).

## Summary

- [Equal](#equal)
- [Greater than](#greater-than)

## Examples

### Equal

Success expectations
```
    5.should.equal(5);
    5.should.not.equal(6);

    true.should.equal(true);
    true.should.not.equal(false);
```

Failing expectations
```
    5.should.equal(6);
    5.should.not.equal(5);

    true.should.equal(false);
    true.should.not.equal(true);
```

### Greater than

Success expectations
```
    5.should.be.greaterThan(4);
    5.should.not.be.greaterThan(6);
```

Failing expectations
```
    5.should.be.greaterThan(5);
    5.should.not.be.greaterThan(4); 
```