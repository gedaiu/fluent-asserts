# The `throwSomething` operation

[up](../README.md)

Asserts that a callable throws any `Throwable`, including `Error` and `AssertError`. Use this when you want to catch any thrown object, not just `Exception` subclasses.

## Usage

```D
// Assert that a callable throws something
({ throw new Exception("error"); }).should.throwSomething;

// Works with Error types too
({ assert(false); }).should.throwSomething;

// Negated form
({ /* no throw */ }).should.not.throwSomething;

// Chain with withMessage to check the message
({ throw new Exception("specific error"); }).should.throwSomething.withMessage("specific error");

// Access the thrown object
auto thrown = ({ throw new Exception("test"); }).should.throwSomething.thrown;
```

## Difference from throwAnyException

- `throwSomething` catches any `Throwable` (including `Error`, `AssertError`)
- `throwAnyException` only catches `Exception` and its subclasses

Works with:
  - expect(`callable`).[to].throwSomething
