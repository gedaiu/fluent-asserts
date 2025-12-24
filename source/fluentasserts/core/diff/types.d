/// Core types for the diff algorithm.
module fluentasserts.core.diff.types;

import fluentasserts.core.memory.heapstring : HeapString, HeapData;

@safe:

/// Represents the type of a diff operation.
enum EditOp : ubyte {
  equal,
  insert,
  remove
}

/// A single diff segment containing operation, text, and line number.
struct DiffSegment {
  EditOp op;
  HeapString text;
  size_t line;
}

/// Result container for diff operations.
alias DiffResult = HeapData!DiffSegment;
