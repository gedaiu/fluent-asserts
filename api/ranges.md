# Arrays API

[up](../README.md)

Here are the examples of how you can use the `should` template with [ranges](http://dlang.org/phobos/std_range.html) and [arrays](https://dlang.org/spec/arrays.html).

## Summary

- [Equal](#equal)
- [Approximately](#approximately)
- [Contain](#contain)
- [ContainOnly](#containOnly)

## Examples

### Equal

Success expectations
```D
    [1, 2, 3].should.equal([1, 2, 3]);
    [1, 2, 3].should.not.equal([2, 1, 3]);

    /// or using the Assert utility
    Assert.equal([1, 2, 3], [1, 2, 3]);
    Assert.notEqual([1, 2, 3], [2, 1, 3]);
```

Failing expectations
```D
    [1, 2, 3].should.equal([4, 5]);
    [1, 2, 3].should.equal([2, 3, 1]);
    [1, 2, 3].should.not.equal([1, 2, 3]);

    /// or using the Assert utility
    Assert.equal([1, 2, 3], [1, 3, 1]);
    Assert.notEqual([1, 2, 3], [1, 2, 3]);
```

### Approximately

Success expectations
```D
    [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.01);

    [0.350, 0.501, 0.341].should.not.be.approximately([0.35, 0.50, 0.34], 0.00001);
    [0.350, 0.501, 0.341].should.not.be.approximately([0.501, 0.350, 0.341], 0.001);
    [0.350, 0.501, 0.341].should.not.be.approximately([0.350, 0.501], 0.001);

    /// or using the Assert utility
    Assert.approximately([0.350, 0.501, 0.341], [0.35, 0.50, 0.34], 0.01);
    Assert.notApproximately([0.350, 0.501, 0.341], [0.350, 0.501], 0.01);
```

Failing expectations
```D
    [0.350, 0.501, 0.341].should.be.approximately([0.35, 0.50, 0.34], 0.0001);

    /// or using the Assert utility
    Assert.approximately([0.350, 0.501, 0.341], [0.35, 0.50, 0.34], 0.0001);
```

### Contain

Success expectations
```D
    [1, 2, 3].should.contain([2, 1]);
    [1, 2, 3].should.not.contain([4, 5]);

    [1, 2, 3].should.contain(1);
    [1, 2, 3].should.not.contain(5);

    /// or using the Assert utility
    Assert.contain([1, 2, 3], [2, 1]);
    Assert.notContain([1, 2, 3], [3, 4]);

    Assert.contain([1, 2, 3], 1);
    Assert.notContain([1, 2, 3], 4);
```

Failing expectations
```D
    [1, 2, 3].should.contain([4, 5]);
    [1, 2, 3].should.not.contain([1, 2]);
    [1, 2, 3].should.not.contain([3, 4]);

    [1, 2, 3].should.contain(4);
    [1, 2, 3].should.not.contain(2);
```

### Contain only

Success expectations
```D
    [1, 2, 3].should.containOnly([3, 2, 1]);
    [1, 2, 3].should.not.containOnly([2, 1]);

    [1, 2, 2].should.containOnly([2, 1, 2]);
    [1, 2, 2].should.not.containOnly([2, 1]);

    [2, 2].should.containOnly([2, 2]);
    [2, 2, 2].should.not.containOnly([2, 2]);

    /// or using the Assert utility
    Assert.containOnly([1, 2, 3], [3, 2, 1]);
    Assert.notContainOnly([1, 2, 3], [2, 1]);
```

Failing expectations
```D
    [1, 2, 3].should.containOnly([2, 1]);
    [1, 2].should.not.containOnly([2, 1]);
    [2, 2].should.containOnly([2]);
    [3, 3].should.containOnly([2]);
    [2, 2].should.not.containOnly([2, 2]);
```
