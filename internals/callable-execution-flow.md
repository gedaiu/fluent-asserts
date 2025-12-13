# Callable Execution Flow

This document describes how callables (delegates, lambdas, function pointers) are executed in the fluent-asserts library.

## Overview

There are two distinct code paths for handling callables, selected by D's overload resolution:

1. **Void delegate path** - for `void delegate()` types
2. **Template path** - for callables with return values

## Code Paths

### Path 1: Void Delegate (`expect.d:507-530`)

```d
Expect expect(void delegate() callable, ...) @trusted {
  // ...
  try {
    if (callable !is null) {
      callable();  // Direct invocation at line 513
    }
  } catch (Exception e) {
    value.throwable = e;
  }
  // ...
}
```

**Characteristics:**
- Explicit overload for `void delegate()`
- Calls callable directly
- Captures exceptions/throwables
- No memory tracking

### Path 2: Template with evaluate() (`expect.d:539-541` + `evaluation.d:196-227`)

```d
Expect expect(T)(lazy T testedValue, ...) @trusted {
  return Expect(testedValue.evaluate(...).evaluation);
}
```

The `evaluate()` function in `evaluation.d` handles callables:

```d
auto evaluate(T)(lazy T testData, ...) @trusted {
  // ...
  auto value = testData;

  static if (isCallable!T) {
    if (value !is null) {
      gcMemoryUsed = GC.stats().usedSize;
      nonGCMemoryUsed = getNonGCMemory();
      begin = Clock.currTime;
      value();  // Invocation at line 214
      nonGCMemoryUsed = getNonGCMemory() - nonGCMemoryUsed;
      gcMemoryUsed = GC.stats().usedSize - gcMemoryUsed;
    }
  }
  // ...
}
```

**Characteristics:**
- Template-based, works with any callable type
- Routes through `evaluate()` function
- Tracks GC and non-GC memory usage before/after execution
- Tracks execution time
- Captures exceptions/throwables

## Overload Resolution

D's overload resolution determines which path is used:

| Callable Type | Path Used | Memory Tracking |
|--------------|-----------|-----------------|
| `void delegate()` | Path 1 (expect.d:507) | No |
| `() => value` (returns non-void) | Path 2 (evaluate) | Yes |
| `int function()` | Path 2 (evaluate) | Yes |
| Named function returning void | Path 1 (expect.d:507) | No |
| Named function returning value | Path 2 (evaluate) | Yes |

## Example

```d
// Path 1: void delegate - no memory tracking
({ doSomething(); }).should.not.throwAnyException();

// Path 2: returns value - memory tracking enabled
({
  auto arr = new int[1000];
  return arr.length;
}).should.allocateGCMemory();
```

## Memory Tracking (Path 2 only)

When a callable goes through the template path, the following metrics are captured in `ValueEvaluation`:

- `gcMemoryUsed` - bytes allocated via GC during execution
- `nonGCMemoryUsed` - bytes allocated via malloc/non-GC during execution
- `duration` - execution time

These values are available to operations like `allocateGCMemory` for assertions.

## File References

- `source/fluentasserts/core/expect.d:507-530` - void delegate overload
- `source/fluentasserts/core/expect.d:539-541` - template overload
- `source/fluentasserts/core/evaluation.d:196-227` - evaluate() with callable handling
- `source/fluentasserts/core/evaluation.d:209-218` - memory tracking block
