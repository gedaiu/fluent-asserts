module fluentasserts.operations.memory.nonGcMemory;

import fluentasserts.core.evaluation : Evaluation;
import fluentasserts.operations.memory.gcMemory : formatBytes;

version(unittest) {
  import fluent.asserts;
  import core.stdc.stdlib : malloc, free;
}

void allocateNonGCMemory(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(". ");
  evaluation.currentValue.typeNames = ["event"];
  evaluation.expectedValue.typeNames = ["event"];

  auto isSuccess = evaluation.currentValue.nonGCMemoryUsed > 0;

  if(evaluation.isNegated) {
    isSuccess = !isSuccess;
  }

  if(!isSuccess && !evaluation.isNegated) {
    evaluation.result.addValue(evaluation.currentValue.strValue);
    evaluation.result.addText(" allocated non-GC memory.");

    evaluation.result.expected = "to allocate non-GC memory";
    evaluation.result.actual = "allocated " ~ evaluation.currentValue.nonGCMemoryUsed.formatBytes;
  }

  if(!isSuccess && evaluation.isNegated) {
    evaluation.result.addValue(evaluation.currentValue.strValue);
    evaluation.result.addText(" did not allocate non-GC memory.");

    evaluation.result.expected = "not to allocate non-GC memory";
    evaluation.result.actual = "allocated " ~ evaluation.currentValue.nonGCMemoryUsed.formatBytes;
  }
}

// Non-GC memory tracking is only reliable on Linux (using mallinfo).
// macOS phys_footprint and Windows process memory are too noisy for reliable delta measurement.
version (linux) {
  @("it does not fail when a callable allocates non-GC memory and it is expected to")
  unittest {
    void* leaked;
    ({
      auto p = (() @trusted => malloc(10 * 1024 * 1024))();
      if (p !is null) {
        (() @trusted => (cast(ubyte*)p)[0] = 1)();
      }
      leaked = p;
      return p !is null;
    }).should.allocateNonGCMemory();
    (() @trusted => free(leaked))();
  }
}

@("it fails when a callable does not allocate non-GC memory and it is expected to")
unittest {
  auto evaluation = ({
    ({
      int[4] stackArray = [1,2,3,4];
      return stackArray.length;
    }).should.allocateNonGCMemory();
  }).recordEvaluation;

  expect(evaluation.result.expected).to.equal(`to allocate non-GC memory`);
  expect(evaluation.result.actual).to.equal("allocated 0 bytes");
}

version (linux) {
  @("it fails when a callable allocates non-GC memory and it is not expected to")
  unittest {
    void* leaked;
    auto evaluation = ({
      ({
        auto p = (() @trusted => malloc(10 * 1024 * 1024))();
        if (p !is null) {
          (() @trusted => (cast(ubyte*)p)[0] = 1)();
        }
        leaked = p;
        return p !is null;
      }).should.not.allocateNonGCMemory();
    }).recordEvaluation;
    (() @trusted => free(leaked))();

    expect(evaluation.result.expected).to.equal(`not to allocate non-GC memory`);
    expect(evaluation.result.actual).to.startWith("allocated ");
    expect(evaluation.result.actual).to.contain("MB");
  }
}

@("it does not fail when a callable does not allocate non-GC memory and it is not expected to")
unittest {
  ({
    int[4] stackArray = [1,2,3,4];
    return stackArray.length;
  }).should.not.allocateNonGCMemory();
}
