# Basic data types API

[up](../README.md)

Here are the examples of how you can use the `should` template with [basic data types](https://dlang.org/spec/type.html#basic-data-types).

## Summary

- [Equal](#equal)
- [Greater than](#greater-than)
- [Above](#above)
- [Less than](#less-than)
- [Below](#below)
- [Between](#between)

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

### Above

Success expectations
```
    5.should.be.above(4);
    5.should.not.be.above(6);
```

Failing expectations
```
    5.should.be.above(5);
    5.should.not.be.above(4);
```

### Less than

Success expectations
```
    5.should.be.lessThan(6);
    5.should.not.be.lessThan(4);
```

Failing expectations
```
    5.should.be.lessThan(4);
    5.should.not.be.lessThan(5);
```


### Below

Success expectations
```
    5.should.be.below(6);
    5.should.not.be.below(4);
```

Failing expectations
```
    5.should.be.below(4);
    5.should.not.be.below(5);
```

### Between

Success expectations
```
  5.should.be.between(4, 6);
  5.should.be.between(6, 4);
  5.should.not.be.between(5, 6);
  5.should.not.be.between(4, 5);
```

Failing expectations
```
  5.should.be.between(5, 6);
  5.should.be.between(4, 5);   
  5.should.not.be.between(4, 6);
  5.should.not.be.between(6, 4);
```
