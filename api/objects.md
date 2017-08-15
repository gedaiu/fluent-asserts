# Objects API

[up](../README.md)

Here are the examples of how you can use the `should` template with [objects](http://dlang.org/spec/class.html).

## Summary

- [Be null](#be-null)
- [Instance of](#instance-of)

## Examples

### Be null

Success expectations
```D
    Object o = null;

    o.should.beNull;
    (new Object).should.not.beNull;

    /// or using the Assert utility
    Assert.beNull(o);
    Assert.notNull(new Object);
```

Failing expectations
```D
    Object o = null;

    o.should.not.beNull;
    (new Object).should.beNull;
```


### Instance of

```D
  class BaseClass { }
  class ExtendedClass : BaseClass { }
  class SomeClass { }
  class OtherClass { }

  auto someObject = new SomeClass;
  auto otherObject = new OtherClass;
  auto extendedObject = new ExtendedClass;
```

Success expectations
```D
  someObject.should.be.instanceOf!SomeClass;
  extendedObject.should.be.instanceOf!BaseClass;

  someObject.should.not.be.instanceOf!OtherClass;
  someObject.should.not.be.instanceOf!BaseClass;
```

Failing expectations
```D
  otherObject.should.be.instanceOf!SomeClass;
  otherObject.should.not.be.instanceOf!OtherClass;
```
