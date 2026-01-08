# Operation Snapshots

This file contains snapshots of all assertion operations with both positive and negated failure variants.

## equal scalar

### Positive fail

```d
expect(5).to.equal(3);
```

```
ASSERTION FAILED: 5 should equal 3.
OPERATION: equal

  ACTUAL: <int> 5
EXPECTED: <int> 3

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(5).to.not.equal(5);
```

```
ASSERTION FAILED: 5 should not equal 5.
OPERATION: not equal

  ACTUAL: <int> 5
EXPECTED: <int> not 5

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## equal string

### Positive fail

```d
expect("hello").to.equal("world");
```

```
ASSERTION FAILED: hello should equal world.
OPERATION: equal

  ACTUAL: <string> hello
EXPECTED: <string> world

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect("hello").to.not.equal("hello");
```

```
ASSERTION FAILED: hello should not equal hello.
OPERATION: not equal

  ACTUAL: <string> hello
EXPECTED: <string> not hello

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## equal array

### Positive fail

```d
expect([1,2,3]).to.equal([1,2,4]);
```

```
ASSERTION FAILED: [1, 2, 3] should equal [1, 2, 4].
OPERATION: equal

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> [1, 2, 4]

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect([1,2,3]).to.not.equal([1,2,3]);
```

```
ASSERTION FAILED: [1, 2, 3] should not equal [1, 2, 3].
OPERATION: not equal

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> not [1, 2, 3]

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## contain string

### Positive fail

```d
expect("hello").to.contain("xyz");
```

```
ASSERTION FAILED: hello should contain xyz xyz is missing from hello.
OPERATION: contain

  ACTUAL: <string> hello
EXPECTED: <string> to contain xyz

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect("hello").to.not.contain("ell");
```

```
ASSERTION FAILED: hello should not contain ell ell is present in hello.
OPERATION: not contain

  ACTUAL: <string> hello
EXPECTED: <string> not to contain ell

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## contain array

### Positive fail

```d
expect([1,2,3]).to.contain(5);
```

```
ASSERTION FAILED: [1, 2, 3] should contain 5. 5 is missing from [1, 2, 3].
OPERATION: contain

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int> to contain 5

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect([1,2,3]).to.not.contain(2);
```

```
ASSERTION FAILED: [1, 2, 3] should not contain 2. 2 is present in [1, 2, 3].
OPERATION: not contain

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int> not to contain 2

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## containOnly

### Positive fail

```d
expect([1,2,3]).to.containOnly([1,2]);
```

```
ASSERTION FAILED: [1, 2, 3] should contain only [1, 2].
OPERATION: containOnly

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> to contain only [1, 2]

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect([1,2,3]).to.not.containOnly([1,2,3]);
```

```
ASSERTION FAILED: [1, 2, 3] should not contain only [1, 2, 3].
OPERATION: not containOnly

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> not to contain only [1, 2, 3]

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## startWith

### Positive fail

```d
expect("hello").to.startWith("xyz");
```

```
ASSERTION FAILED: hello should start with xyz hello does not starts with xyz.
OPERATION: startWith

  ACTUAL: <string> hello
EXPECTED: <string> to start with xyz

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect("hello").to.not.startWith("hel");
```

```
ASSERTION FAILED: hello should not start with hel hello starts with hel.
OPERATION: not startWith

  ACTUAL: <string> hello
EXPECTED: <string> not to start with hel

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## endWith

### Positive fail

```d
expect("hello").to.endWith("xyz");
```

```
ASSERTION FAILED: hello should end with xyz hello does not ends with xyz.
OPERATION: endWith

  ACTUAL: <string> hello
EXPECTED: <string> to end with xyz

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect("hello").to.not.endWith("llo");
```

```
ASSERTION FAILED: hello should not end with llo hello ends with llo.
OPERATION: not endWith

  ACTUAL: <string> hello
EXPECTED: <string> not to end with llo

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## approximately scalar

### Positive fail

```d
expect(0.5).to.be.approximately(0.3, 0.1);
```

```
ASSERTION FAILED: 0.5 should be approximately 0.3±0.1 0.5 is not approximately 0.3±0.1.
OPERATION: approximately

  ACTUAL: <double> 0.5
EXPECTED: <double> 0.3±0.1

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(0.351).to.not.be.approximately(0.35, 0.01);
```

```
ASSERTION FAILED: 0.351 should not be approximately 0.35±0.01 0.351 is approximately 0.35±0.01.
OPERATION: not approximately

  ACTUAL: <double> 0.351
EXPECTED: <double> 0.35±0.01

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## approximately array

### Positive fail

```d
expect([0.5]).to.be.approximately([0.3], 0.1);
```

```
ASSERTION FAILED: [0.5] should be approximately [0.3]±0.1.
OPERATION: approximately

  ACTUAL: <double[]> [0.5]
EXPECTED: <double[]> [0.3±0.1]

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect([0.35]).to.not.be.approximately([0.35], 0.01);
```

```
ASSERTION FAILED: [0.35] should not be approximately [0.35]±0.01.
OPERATION: not approximately

  ACTUAL: <double[]> [0.35]
EXPECTED: <double[]> [0.35±0.01]

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## greaterThan

### Positive fail

```d
expect(3).to.be.greaterThan(5);
```

```
ASSERTION FAILED: 3 should be greater than 5.
OPERATION: greaterThan

  ACTUAL: <int> 3
EXPECTED: <int> greater than 5

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(5).to.not.be.greaterThan(3);
```

```
ASSERTION FAILED: 5 should not be greater than 3.
OPERATION: not greaterThan

  ACTUAL: <int> 5
EXPECTED: <int> less than or equal to 3

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## lessThan

### Positive fail

```d
expect(5).to.be.lessThan(3);
```

```
ASSERTION FAILED: 5 should be less than 3.
OPERATION: lessThan

  ACTUAL: <int> 5
EXPECTED: <int> less than 3

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(3).to.not.be.lessThan(5);
```

```
ASSERTION FAILED: 3 should not be less than 5.
OPERATION: not lessThan

  ACTUAL: <int> 3
EXPECTED: <int> greater than or equal to 5

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## between

### Positive fail

```d
expect(10).to.be.between(1, 5);
```

```
ASSERTION FAILED: 10 should be between 1 and 510 is greater than or equal to 5.
OPERATION: between

  ACTUAL: <int> 10
EXPECTED: <int> a value inside (1, 5) interval

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(3).to.not.be.between(1, 5);
```

```
ASSERTION FAILED: 3 should not be between 1 and 5.
OPERATION: not between

  ACTUAL: <int> 3
EXPECTED: <int> a value outside (1, 5) interval

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## greaterOrEqualTo

### Positive fail

```d
expect(3).to.be.greaterOrEqualTo(5);
```

```
ASSERTION FAILED: 3 should be greater or equal to 5.
OPERATION: greaterOrEqualTo

  ACTUAL: <int> 3
EXPECTED: <int> greater or equal than 5

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(5).to.not.be.greaterOrEqualTo(3);
```

```
ASSERTION FAILED: 5 should not be greater or equal to 3.
OPERATION: not greaterOrEqualTo

  ACTUAL: <int> 5
EXPECTED: <int> less than 3

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## lessOrEqualTo

### Positive fail

```d
expect(5).to.be.lessOrEqualTo(3);
```

```
ASSERTION FAILED: 5 should be less or equal to 3.
OPERATION: lessOrEqualTo

  ACTUAL: <int> 5
EXPECTED: <int> less or equal to 3

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(3).to.not.be.lessOrEqualTo(5);
```

```
ASSERTION FAILED: 3 should not be less or equal to 5.
OPERATION: not lessOrEqualTo

  ACTUAL: <int> 3
EXPECTED: <int> greater than 5

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## instanceOf

### Positive fail

```d
expect(new Object()).to.be.instanceOf!Exception;
```

```
ASSERTION FAILED: Object(XXX) should be instance of "object.Exception". Object(XXX) is instance of object.Object.
OPERATION: instanceOf

  ACTUAL: <object.Object> typeof object.Object
EXPECTED: <object.Exception> typeof object.Exception

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(new Exception("test")).to.not.be.instanceOf!Object;
```

```
ASSERTION FAILED: Exception(XXX) should not be instance of "object.Object". Exception(XXX) is instance of object.Exception.
OPERATION: not instanceOf

  ACTUAL: <object.Exception> typeof object.Exception
EXPECTED: <object.Object> not typeof object.Object

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```

## beNull

### Positive fail

```d
expect(new Object()).to.beNull;
```

```
ASSERTION FAILED: Object(XXX) should be null.
OPERATION: beNull

  ACTUAL: <object.Object> object.Object
EXPECTED: <unknown> null

source/fluentasserts/operations/snapshot.d:XXX
>  219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
```

### Negated fail

```d
expect(null).to.not.beNull;
```

```
ASSERTION FAILED:  should not be null.
OPERATION: not beNull

  ACTUAL: <null> null
EXPECTED: <unknown> not null

source/fluentasserts/operations/snapshot.d:XXX
   213:unittest {
   214:  auto previousFormat = config.output.format;
   215:  scope(exit) config.output.setFormat(previousFormat);
   216:
   217:  config.output.setFormat(OutputFormat.verbose);
   218:
   219:  auto eval = recordEvaluation({ expect(5).to.equal(3); });
   220:  auto output = eval.toString();
   221:
   222:  assert(output.canFind("ASSERTION FAILED:"), "Verbose format should contain ASSERTION FAILED:");
>  223:  assert(output.canFind("OPERATION:"), "Verbose format should contain OPERATION:");
   224:  assert(output.canFind("ACTUAL:"), "Verbose format should contain ACTUAL:");
   225:  assert(output.canFind("EXPECTED:"), "Verbose format should contain EXPECTED:");
   226:}
```
