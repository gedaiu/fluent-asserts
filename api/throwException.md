# The `throwException` operation

[up](../README.md)

Asserts that a callable throws a specific exception type. The assertion fails if no exception is thrown or if a different exception type is thrown.

## Usage

```D
// Assert that a specific exception type is thrown
({ throw new CustomException("error"); }).should.throwException!CustomException;

// Fails if no exception is thrown
({ }).should.throwException!Exception; // This will fail

// Negated form - assert that a specific exception is NOT thrown
({ }).should.not.throwException!Exception; // This passes

// Chain with withMessage to check the message
({ throw new Exception("expected message"); }).should.throwException!Exception.withMessage("expected message");

// Access the thrown exception
auto ex = ({ throw new Exception("test"); }).should.throwException!Exception.thrown;

// Get just the message
string msg = ({ throw new Exception("test"); }).should.throwException!Exception.msg;
```

## Difference from throwAnyException

- `throwException!T` only matches the specific exception type `T`
- `throwAnyException` matches any `Exception` subclass

Works with:
  - expect(`callable`).[to].throwException!T
