module fluentasserts.operations.memory.gcMemory;

import fluentasserts.core.evaluation : Evaluation;
import std.conv;

version(unittest) {
  import fluent.asserts;
}

string formatBytes(size_t bytes) @safe nothrow {
  static immutable string[] units = ["bytes", "KB", "MB", "GB", "TB"];

  if (bytes == 0) return "0 bytes";
  if (bytes == 1) return "1 byte";

  double size = bytes;
  size_t unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }

  try {
    if (unitIndex == 0) {
      return bytes.to!string ~ " bytes";
    }
    return format!"%.2f %s"(size, units[unitIndex]);
  } catch (Exception) {
    return "? bytes";
  }
}

private string format(string fmt, Args...)(Args args) @safe nothrow {
  import std.format : format;
  try {
    return format!fmt(args);
  } catch (Exception) {
    return "";
  }
}

void allocateGCMemory(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(". ");
  evaluation.currentValue.typeNames = ["event"];
  evaluation.expectedValue.typeNames = ["event"];

  auto isSuccess = evaluation.currentValue.gcMemoryUsed > 0;

  if(evaluation.isNegated) {
    isSuccess = !isSuccess;
  }

  if(!isSuccess && !evaluation.isNegated) {
    evaluation.result.addValue(evaluation.currentValue.strValue);
    evaluation.result.addText(" allocated GC memory.");

    evaluation.result.expected = "to allocate GC memory";
    evaluation.result.actual = "allocated " ~ evaluation.currentValue.gcMemoryUsed.formatBytes;
  }

  if(!isSuccess && evaluation.isNegated) {
    evaluation.result.addValue(evaluation.currentValue.strValue);
    evaluation.result.addText(" did not allocated GC memory.");

    evaluation.result.expected = "not to allocate GC memory";
    evaluation.result.actual = "allocated " ~ evaluation.currentValue.gcMemoryUsed.formatBytes;
  }
}

@("it does not fail when a callable allocates memory and it is expected to")
unittest {
  ({
    auto heapArray = new int[1000];
    return heapArray.length;
  }).should.allocateGCMemory();
}

@("updateDocs it fails when a callable does not allocate memory and it is expected to")
unittest {
  auto evaluation = ({
    ({
      int[4] stackArray = [1,2,3,4];
      return stackArray.length;
    }).should.allocateGCMemory();
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal(`to allocate GC memory`);
  expect(evaluation.result.actual).to.equal("allocated 0 bytes");
}

@("it fails when a callable allocates memory and it is not expected to")
unittest {
  auto evaluation = ({
    ({
      auto heapArray = new int[1000];
      return heapArray.length;
    }).should.not.allocateGCMemory();
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal(`not to allocate GC memory`);
  expect(evaluation.result.actual).to.startWith("allocated ");
  expect(evaluation.result.actual).to.contain("KB");
}

@("it does not fail when a callable does not allocate memory and it is not expected to")
unittest {
  auto evaluation = ({
    ({
      int[4] stackArray = [1,2,3,4];
      return stackArray.length;
    }).should.not.allocateGCMemory();
  }).recordEvaluation;

  expect(evaluation.result.hasContent()).to.equal(false);
}