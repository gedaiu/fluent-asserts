# Basic Data Types API

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
```
    "test string".should.equal("test string");
    "test string".should.not.equal("test");
```

Failing expectations
```
     "test string".should.equal("test");
     "test string".should.not.equal("test string");
```

### Contain

Success expectations
```
    "test string".should.contain(["string", "test"]);
    "test string".should.contain("string");
    "test string".should.contain('s');
```

Failing expectations
```
    "test string".should.contain(["other", "message"]);
    "test string".should.contain("other");
    "test string".should.contain('o');
```

### Start with

Success expectations
```
    "test string".should.startWith("test");
    "test string".should.not.startWith("other");

    "test string".should.startWith('t');
    "test string".should.not.startWith('o');
```

Failing expectations
```
    "test string".should.startWith("other");
    "test string".should.not.startWith("test");

    "test string".should.startWith('o');
    "test string".should.not.startWith('t');
```

### End with

Success expectations
```
   "test string".should.endWith("string");
   "test string".should.not.endWith("other");

   "test string".should.endWith('g');
   "test string".should.not.endWith('w');
```

Failing expectations
```
    "test string".should.endWith("other");
    "test string".should.not.endWith("string");

    "test string".should.endWith('t');
    "test string".should.not.endWith('g');
```