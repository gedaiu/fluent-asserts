# Strings API

[up](../README.md)

Here are the examples of how you can use the `should` template with [strings](https://dlang.org/spec/arrays.html#strings).

## Summary

- [Equal](#equal)
- [Contain](#contain)
- [Start with](#start-with)
- [End with](#end-with)

## Examples

### Equal

Success expectations
```D
    "test string".should.equal("test string");
    "test string".should.not.equal("test");

    /// or using the Assert utility
    Assert.equal("test string", "test string");
    Assert.notEqual("test string", "test");
```

Failing expectations
```D
     "test string".should.equal("test");
     "test string".should.not.equal("test string");
```

### Contain

Success expectations
```D
    "test string".should.contain(["string", "test"]);
    "test string".should.not.contain(["other", "value"]);

    "test string".should.contain("string");
    "test string".should.not.contain("other");

    "test string".should.contain('s');
    "test string".should.not.contain('z');

    /// or using the Assert utility
    Assert.contain("test string", ["string", "test"]);
    Assert.notContain("test string", ["other", "value"]);

    Assert.contain("test string", "test");
    Assert.notContain("test string", "other");

    Assert.contain("test string", 't');
    Assert.notContain("test string", 'z');
```

Failing expectations
```D
    "test string".should.contain(["other", "message"]);
    "test string".should.contain("other");
    "test string".should.contain('o');
```

### Start with

Success expectations
```D
    "test string".should.startWith("test");
    "test string".should.not.startWith("other");

    "test string".should.startWith('t');
    "test string".should.not.startWith('o');

    /// or using the Assert utility
    Assert.startWith(test string", "test");
    Assert.notStartWith("test string", "other");

    Assert.startWith("test string", 't');
    Assert.notStartWith(test string", 'o');
```

Failing expectations
```D
    "test string".should.startWith("other");
    "test string".should.not.startWith("test");

    "test string".should.startWith('o');
    "test string".should.not.startWith('t');
```

### End with

Success expectations
```D
   "test string".should.endWith("string");
   "test string".should.not.endWith("other");

   "test string".should.endWith('g');
   "test string".should.not.endWith('w');

    /// or using the Assert utility
    Assert.endWith(test string", "string");
    Assert.notEndWith("test string", "other");

    Assert.endWith("test string", 'g');
    Assert.notEndWith(test string", 'o');
```

Failing expectations
```D
    "test string".should.endWith("other");
    "test string".should.not.endWith("string");

    "test string".should.endWith('t');
    "test string".should.not.endWith('g');
```
