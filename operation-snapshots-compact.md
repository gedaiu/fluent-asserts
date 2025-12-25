# Operation Snapshots (compact)

This file contains snapshots in compact format (default when CLAUDECODE=1).

## equal scalar

### Positive fail

```d
expect(5).to.equal(3);
```

```
FAIL: 5 should equal 3. | actual=5 expected=3 | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(5).to.not.equal(5);
```

```
FAIL: 5 should not equal 5. | actual=5 expected=not 5 | source/fluentasserts/operations/snapshot.d:XXX
```

## equal string

### Positive fail

```d
expect("hello").to.equal("world");
```

```
FAIL: hello should equal world. | actual=hello expected=world | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect("hello").to.not.equal("hello");
```

```
FAIL: hello should not equal hello. | actual=hello expected=not hello | source/fluentasserts/operations/snapshot.d:XXX
```

## equal array

### Positive fail

```d
expect([1,2,3]).to.equal([1,2,4]);
```

```
FAIL: [1, 2, 3] should equal [1, 2, 4]. | actual=[1, 2, 3] expected=[1, 2, 4] | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect([1,2,3]).to.not.equal([1,2,3]);
```

```
FAIL: [1, 2, 3] should not equal [1, 2, 3]. | actual=[1, 2, 3] expected=not [1, 2, 3] | source/fluentasserts/operations/snapshot.d:XXX
```

## contain string

### Positive fail

```d
expect("hello").to.contain("xyz");
```

```
FAIL: hello should contain xyz xyz is missing from hello. | actual=hello expected=to contain xyz | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect("hello").to.not.contain("ell");
```

```
FAIL: hello should not contain ell ell is present in hello. | actual=hello expected=not to contain ell | source/fluentasserts/operations/snapshot.d:XXX
```

## contain array

### Positive fail

```d
expect([1,2,3]).to.contain(5);
```

```
FAIL: [1, 2, 3] should contain 5. 5 is missing from [1, 2, 3]. | actual=[1, 2, 3] expected=to contain 5 | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect([1,2,3]).to.not.contain(2);
```

```
FAIL: [1, 2, 3] should not contain 2. 2 is present in [1, 2, 3]. | actual=[1, 2, 3] expected=not to contain 2 | source/fluentasserts/operations/snapshot.d:XXX
```

## containOnly

### Positive fail

```d
expect([1,2,3]).to.containOnly([1,2]);
```

```
FAIL: [1, 2, 3] should contain only [1, 2]. | actual=[1, 2, 3] expected=to contain only [1, 2] | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect([1,2,3]).to.not.containOnly([1,2,3]);
```

```
FAIL: [1, 2, 3] should not contain only [1, 2, 3]. | actual=[1, 2, 3] expected=not to contain only [1, 2, 3] | source/fluentasserts/operations/snapshot.d:XXX
```

## startWith

### Positive fail

```d
expect("hello").to.startWith("xyz");
```

```
FAIL: hello should start with xyz hello does not starts with xyz. | actual=hello expected=to start with xyz | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect("hello").to.not.startWith("hel");
```

```
FAIL: hello should not start with hel hello starts with hel. | actual=hello expected=not to start with hel | source/fluentasserts/operations/snapshot.d:XXX
```

## endWith

### Positive fail

```d
expect("hello").to.endWith("xyz");
```

```
FAIL: hello should end with xyz hello does not ends with xyz. | actual=hello expected=to end with xyz | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect("hello").to.not.endWith("llo");
```

```
FAIL: hello should not end with llo hello ends with llo. | actual=hello expected=not to end with llo | source/fluentasserts/operations/snapshot.d:XXX
```

## approximately scalar

### Positive fail

```d
expect(0.5).to.be.approximately(0.3, 0.1);
```

```
FAIL: 0.5 should be approximately 0.3±0.1 0.5 is not approximately 0.3±0.1. | actual=0.5 expected=0.3±0.1 | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(0.351).to.not.be.approximately(0.35, 0.01);
```

```
FAIL: 0.351 should not be approximately 0.35±0.01 0.351 is approximately 0.35±0.01. | actual=0.351 expected=0.35±0.01 | source/fluentasserts/operations/snapshot.d:XXX
```

## approximately array

### Positive fail

```d
expect([0.5]).to.be.approximately([0.3], 0.1);
```

```
FAIL: [0.5] should be approximately [0.3]±0.1. | actual=[0.5] expected=[0.3±0.1] | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect([0.35]).to.not.be.approximately([0.35], 0.01);
```

```
FAIL: [0.35] should not be approximately [0.35]±0.01. | actual=[0.35] expected=[0.35±0.01] | source/fluentasserts/operations/snapshot.d:XXX
```

## greaterThan

### Positive fail

```d
expect(3).to.be.greaterThan(5);
```

```
FAIL: 3 should be greater than 5. | actual=3 expected=greater than 5 | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(5).to.not.be.greaterThan(3);
```

```
FAIL: 5 should not be greater than 3. | actual=5 expected=less than or equal to 3 | source/fluentasserts/operations/snapshot.d:XXX
```

## lessThan

### Positive fail

```d
expect(5).to.be.lessThan(3);
```

```
FAIL: 5 should be less than 3. | actual=5 expected=less than 3 | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(3).to.not.be.lessThan(5);
```

```
FAIL: 3 should not be less than 5. | actual=3 expected=greater than or equal to 5 | source/fluentasserts/operations/snapshot.d:XXX
```

## between

### Positive fail

```d
expect(10).to.be.between(1, 5);
```

```
FAIL: 10 should be between 1 and 510 is greater than or equal to 5. | actual=10 expected=a value inside (1, 5) interval | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(3).to.not.be.between(1, 5);
```

```
FAIL: 3 should not be between 1 and 5. | actual=3 expected=a value outside (1, 5) interval | source/fluentasserts/operations/snapshot.d:XXX
```

## greaterOrEqualTo

### Positive fail

```d
expect(3).to.be.greaterOrEqualTo(5);
```

```
FAIL: 3 should be greater or equal to 5. | actual=3 expected=greater or equal than 5 | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(5).to.not.be.greaterOrEqualTo(3);
```

```
FAIL: 5 should not be greater or equal to 3. | actual=5 expected=less than 3 | source/fluentasserts/operations/snapshot.d:XXX
```

## lessOrEqualTo

### Positive fail

```d
expect(5).to.be.lessOrEqualTo(3);
```

```
FAIL: 5 should be less or equal to 3. | actual=5 expected=less or equal to 3 | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(3).to.not.be.lessOrEqualTo(5);
```

```
FAIL: 3 should not be less or equal to 5. | actual=3 expected=greater than 5 | source/fluentasserts/operations/snapshot.d:XXX
```

## instanceOf

### Positive fail

```d
expect(new Object()).to.be.instanceOf!Exception;
```

```
FAIL: Object(XXX) should be instance of "object.Exception". Object(XXX) is instance of object.Object. | actual=typeof object.Object expected=typeof object.Exception | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(new Exception("test")).to.not.be.instanceOf!Object;
```

```
FAIL: Exception(XXX) should not be instance of "object.Object". Exception(XXX) is instance of object.Exception. | actual=typeof object.Exception expected=not typeof object.Object | source/fluentasserts/operations/snapshot.d:XXX
```

## beNull

### Positive fail

```d
expect(new Object()).to.beNull;
```

```
FAIL: Object(XXX) should be null. | actual=object.Object expected=null | source/fluentasserts/operations/snapshot.d:XXX
```

### Negated fail

```d
expect(null).to.not.beNull;
```

```
FAIL:  should not be null. | actual=null expected=not null | source/fluentasserts/operations/snapshot.d:XXX
```
