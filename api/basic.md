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
- [Within](#within)
- [Approximately](#approximately)

## Examples

### Equal

Success expectations
```D
  5.should.equal(5);
  5.should.not.equal(6);

  true.should.equal(true);
  true.should.not.equal(false);

  /// or using the Assert utility
  Assert.equal(5, 5);
  Assert.notEqual(5, 6);
```

Failing expectations
```D
  5.should.equal(6);
  5.should.not.equal(5);

  true.should.equal(false);
  true.should.not.equal(true);

  /// or using the Assert utility
  Assert.equal(5, 6);
  Assert.notEqual(5, 5);
```

### Greater than

Success expectations
```D
  5.should.be.greaterThan(4);
  5.should.not.be.greaterThan(6);

  /// or using the Assert utility
  Assert.greaterThan(5, 4);
  Assert.notGreaterThan(5, 6);
```

Failing expectations
```D
  5.should.be.greaterThan(5);
  5.should.not.be.greaterThan(4);

  /// or using the Assert utility
  Assert.greaterThan(5, 5);
  Assert.notGreaterThan(5, 4);
```

### Above

Success expectations
```D
  5.should.be.above(4);
  5.should.not.be.above(6);

  /// or using the Assert utility
  Assert.above(5, 4);
  Assert.notAbove(5, 6);
```

Failing expectations
```D
  5.should.be.above(5);
  5.should.not.be.above(4);

  /// or using the Assert utility
  Assert.above(5, 5);
  Assert.notAbove(5, 4);
```

### Less than

Success expectations
```D
  5.should.be.lessThan(6);
  5.should.not.be.lessThan(4);

  /// or using the Assert utility
  Assert.lessThan(5, 6);
  Assert.notLessThan(5, 4);
```

Failing expectations
```D
  5.should.be.lessThan(4);
  5.should.not.be.lessThan(5);

  /// or using the Assert utility
  Assert.lessThan(5, 4);
  Assert.notLessThan(5, 5);
```

### Below

Success expectations
```D
  5.should.be.below(6);
  5.should.not.be.below(4);

  /// or using the Assert utility
  Assert.below(5, 6);
  Assert.notBelow(5, 4);
```

Failing expectations
```D
  5.should.be.below(4);
  5.should.not.be.below(5);

  /// or using the Assert utility
  Assert.below(5, 4);
  Assert.notBelow(5, 5);
```

### Between

Success expectations
```D
  5.should.be.between(4, 6);
  5.should.be.between(6, 4);
  5.should.not.be.between(5, 6);
  5.should.not.be.between(4, 5);

  /// or using the Assert utility
  Assert.between(5, 4, 6);
  Assert.notBetween(5, 5, 6);
```

Failing expectations
```D
  5.should.be.between(5, 6);
  5.should.be.between(4, 5);
  5.should.not.be.between(4, 6);
  5.should.not.be.between(6, 4);

  /// or using the Assert utility
  Assert.between(5, 4, 5);
  Assert.notBetween(5, 4, 6);
```

### Within

Success expectations
```D
  5.should.be.within(4, 6);
  5.should.be.within(6, 4);
  5.should.not.be.within(5, 6);
  5.should.not.be.within(4, 5);

  /// or using the Assert utility
  Assert.within(5, 4, 6);
  Assert.notWithin(5, 5, 6);
```

Failing expectations
```D
  5.should.be.within(5, 6);
  5.should.be.within(4, 5);
  5.should.not.be.within(4, 6);
  5.should.not.be.within(6, 4);

  /// or using the Assert utility
  Assert.within(5, 5, 6);
  Assert.notWithin(5, 4, 6);
```

### Approximately

Success expectations
```D
  (10f/3f).should.be.approximately(3, 0.34);
  (10f/3f).should.not.be.approximately(3, 0.24);

  /// or using the Assert utility
  Assert.approximately(10f/3f, 3, 0.34);
  Assert.notApproximately(10f/3f, 3, 0.24);
```

Failing expectations
```D
  (10f/3f).should.be.approximately(3, 0.3);
  (10f/3f).should.not.be.approximately(3, 0.34);

  /// or using the Assert utility
  Assert.approximately(10f/3f, 3, 0.3);
  Assert.notApproximately(10f/3f, 3, 0.34);
```
