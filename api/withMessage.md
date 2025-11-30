# The `withMessage` operation

[up](../README.md)

Chains with exception assertions to verify that the thrown exception has a specific message.

## Usage

```D
// Check exception message
({ throw new Exception("expected message"); }).should.throwException!Exception.withMessage("expected message");

// Works with throwAnyException
({ throw new Exception("error"); }).should.throwAnyException.withMessage("error");

// Works with throwSomething
({ throw new Exception("error"); }).should.throwSomething.withMessage("error");

// Negated form - check that message does NOT match
({ throw new Exception("actual"); }).should.throwException!Exception.not.withMessage("different");
```

## Note

`withMessage` must be chained after a throw assertion. It cannot be used standalone.

Works with:
  - throwException!T.withMessage(string)
  - throwAnyException.withMessage(string)
  - throwSomething.withMessage(string)

