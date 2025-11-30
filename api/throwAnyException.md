# The `throwAnyException` operation

[up](../README.md)

Asserts that a callable throws any `Exception` (or subclass). Use this when you want to verify that an exception is thrown but don't care about the specific type.

## Usage

```D
// Assert that any exception is thrown
({ throw new Exception("error"); }).should.throwAnyException;

// Works with any Exception subclass
({ throw new CustomException("error"); }).should.throwAnyException;

// Negated form
({ /* no throw */ }).should.not.throwAnyException;

// Chain with withMessage to check the message
({ throw new Exception("specific error"); }).should.throwAnyException.withMessage("specific error");

// Access the thrown exception
auto ex = ({ throw new Exception("test"); }).should.throwAnyException.thrown;
```

## Difference from throwSomething

- `throwAnyException` only catches `Exception` and its subclasses
- `throwSomething` catches any `Throwable` (including `Error`, `AssertError`)

Works with:
  - expect(`callable`).[to].throwAnyException
