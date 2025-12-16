# Operation Snapshots

This file contains snapshots of all assertion operations with both positive and negated failure variants.

## equal (scalar)

### Positive fail

```d
expect(5).to.equal(3);
```

```
ASSERTION FAILED: 5 should equal 3.
OPERATION: equal

  ACTUAL: <int> 5
EXPECTED: <int> 3

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## equal (string)

### Positive fail

```d
expect("hello").to.equal("world");
```

```
ASSERTION FAILED: hello should equal world.
OPERATION: equal

  ACTUAL: <string> hello
EXPECTED: <string> world

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## equal (array)

### Positive fail

```d
expect([1,2,3]).to.equal([1,2,4]);
```

```
ASSERTION FAILED: [1, 2, 3] should equal [1, 2, 4].
OPERATION: equal

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int[]> [1, 2, 4]

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## contain (string)

### Positive fail

```d
expect("hello").to.contain("xyz");
```

```
ASSERTION FAILED: hello should contain xyz. xyz is missing from hello.
OPERATION: contain

  ACTUAL: <string> hello
EXPECTED: <string> to contain xyz

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect("hello").to.not.contain("ell");
```

```
ASSERTION FAILED: hello should not contain ell. ell is present in hello.
OPERATION: not contain

  ACTUAL: <string> hello
EXPECTED: <string> not to contain ell

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## contain (array)

### Positive fail

```d
expect([1,2,3]).to.contain(5);
```

```
ASSERTION FAILED: [1, 2, 3] should contain 5. 5 is missing from [1, 2, 3].
OPERATION: contain

  ACTUAL: <int[]> [1, 2, 3]
EXPECTED: <int> to contain 5

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## startWith

### Positive fail

```d
expect("hello").to.startWith("xyz");
```

```
ASSERTION FAILED: hello should start with xyz. hello does not start with xyz.
OPERATION: startWith

  ACTUAL: <string> hello
EXPECTED: <string> to start with xyz

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect("hello").to.not.startWith("hel");
```

```
ASSERTION FAILED: hello should not start with hel. hello starts with hel.
OPERATION: not startWith

  ACTUAL: <string> hello
EXPECTED: <string> not to start with hel

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## endWith

### Positive fail

```d
expect("hello").to.endWith("xyz");
```

```
ASSERTION FAILED: hello should end with xyz. hello does not end with xyz.
OPERATION: endWith

  ACTUAL: <string> hello
EXPECTED: <string> to end with xyz

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect("hello").to.not.endWith("llo");
```

```
ASSERTION FAILED: hello should not end with llo. hello ends with llo.
OPERATION: not endWith

  ACTUAL: <string> hello
EXPECTED: <string> not to end with llo

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## beNull

### Positive fail

```d
Object obj = new Object(); expect(obj).to.beNull;
```

```
ASSERTION FAILED: Object(4763046377) should be null.
OPERATION: beNull

  ACTUAL: <object.Object> object.Object
EXPECTED: <unknown> null

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
Object obj = null; expect(obj).to.not.beNull;
```

```
ASSERTION FAILED: null should not be null.
OPERATION: not beNull

  ACTUAL: <object.Object> object.Object
EXPECTED: <unknown> not null

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## approximately (scalar)

### Positive fail

```d
expect(0.5).to.be.approximately(0.3, 0.1);
```

```
ASSERTION FAILED: 0.5 should be approximately 0.3±0.1. 0.5 is not approximately 0.3±0.1.
OPERATION: approximately

  ACTUAL: <double> 0.5
EXPECTED: <double> 0.3±0.1

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect(0.351).to.not.be.approximately(0.35, 0.01);
```

```
ASSERTION FAILED: 0.351 should not be approximately 0.35±0.01. 0.351 is approximately 0.35±0.01.
OPERATION: not approximately

  ACTUAL: <double> 0.351
EXPECTED: <double> 0.35±0.01

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## approximately (array)

### Positive fail

```d
expect([0.5]).to.be.approximately([0.3], 0.1);
```

```
ASSERTION FAILED: [0.5] should be approximately [0.3]±0.1.
OPERATION: approximately

  ACTUAL: <double[]> [0.5]
EXPECTED: <double[]> [0.3±0.1]

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## greaterThan

### Positive fail

```d
expect(3).to.be.greaterThan(5);
```

```
ASSERTION FAILED: 3 should be greater than 5. 3 is less than or equal to 5.
OPERATION: greaterThan

  ACTUAL: <int> 3
EXPECTED: <int> greater than 5

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect(5).to.not.be.greaterThan(3);
```

```
ASSERTION FAILED: 5 should not be greater than 3. 5 is greater than 3.
OPERATION: not greaterThan

  ACTUAL: <int> 5
EXPECTED: <int> less than or equal to 3

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## lessThan

### Positive fail

```d
expect(5).to.be.lessThan(3);
```

```
ASSERTION FAILED: 5 should be less than 3. 5 is greater than or equal to 3.
OPERATION: lessThan

  ACTUAL: <int> 5
EXPECTED: <int> less than 3

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect(3).to.not.be.lessThan(5);
```

```
ASSERTION FAILED: 3 should not be less than 5. 3 is less than 5.
OPERATION: not lessThan

  ACTUAL: <int> 3
EXPECTED: <int> greater than or equal to 5

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## between

### Positive fail

```d
expect(10).to.be.between(1, 5);
```

```
ASSERTION FAILED: 10 should be between 1 and 5. 10 is greater than or equal to 5.
OPERATION: between

  ACTUAL: <int> 10
EXPECTED: <int> a value inside (1, 5) interval

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
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

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## greaterOrEqualTo

### Positive fail

```d
expect(3).to.be.greaterOrEqualTo(5);
```

```
ASSERTION FAILED: 3 should be greater or equal to 5. 3 is less than 5.
OPERATION: greaterOrEqualTo

  ACTUAL: <int> 3
EXPECTED: <int> greater or equal than 5

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect(5).to.not.be.greaterOrEqualTo(3);
```

```
ASSERTION FAILED: 5 should not be greater or equal to 3. 5 is greater or equal than 3.
OPERATION: not greaterOrEqualTo

  ACTUAL: <int> 5
EXPECTED: <int> less than 3

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## lessOrEqualTo

### Positive fail

```d
expect(5).to.be.lessOrEqualTo(3);
```

```
ASSERTION FAILED: 5 should be less or equal to 3. 5 is greater than 3.
OPERATION: lessOrEqualTo

  ACTUAL: <int> 5
EXPECTED: <int> less or equal to 3

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect(3).to.not.be.lessOrEqualTo(5);
```

```
ASSERTION FAILED: 3 should not be less or equal to 5. 3 is less or equal to 5.
OPERATION: not lessOrEqualTo

  ACTUAL: <int> 3
EXPECTED: <int> greater than 5

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

## instanceOf

### Positive fail

```d
expect(new Object()).to.be.instanceOf!Exception;
```

```
ASSERTION FAILED: Object(4762940490) should be instance of "object.Exception". Object(4762940490) is instance of object.Object.
OPERATION: instanceOf

  ACTUAL: <object.Object> typeof object.Object
EXPECTED: <object.Exception> typeof object.Exception

source/fluentasserts/operations/snapshot.d:107
>  107:        auto posEval = ({ mixin(c.code ~ ";"); }).recordEvaluation;
```

### Negated fail

```d
expect(new Exception("test")).to.not.be.instanceOf!Object;
```

```
ASSERTION FAILED: Exception(4763114072) should not be instance of "object.Object". Exception(4763114072) is instance of object.Exception.
OPERATION: not instanceOf

  ACTUAL: <object.Exception> typeof object.Exception
EXPECTED: <object.Object> not typeof object.Object

source/fluentasserts/operations/snapshot.d:122
>  122:        auto negEval = ({ mixin(c.negCode ~ ";"); }).recordEvaluation;
```

