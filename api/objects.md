# Objects API

[up](../README.md)

Here are the examples of how you can use the `should` template with [objects](http://dlang.org/spec/class.html).

## Summary

- [Be null](#be-null)

## Examples

### Be null

Success expectations
```D
    Object o = null;

    o.should.beNull;
    (new Object).should.not.beNull;
```

Failing expectations
```D
    Object o = null;

    o.should.not.beNull;
    (new Object).should.beNull;
```
