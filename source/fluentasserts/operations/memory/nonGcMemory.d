module fluentasserts.operations.memory.nonGcMemory;

import fluentasserts.core.evaluation.eval : Evaluation;
import fluentasserts.operations.memory.gcMemory : formatBytes;

version(unittest) {
  import fluent.asserts;
  import core.stdc.stdlib : malloc, free;
}

void allocateNonGCMemory(ref Evaluation evaluation) @safe nothrow {
  evaluation.result.addText(". ");
  evaluation.currentValue.typeNames.put("event");
  evaluation.expectedValue.typeNames.put("event");

  auto didAllocate = evaluation.currentValue.nonGCMemoryUsed > 0;
  auto passed = evaluation.isNegated ? !didAllocate : didAllocate;

  if (passed) {
    return;
  }

  evaluation.result.addValue(evaluation.currentValue.strValue[]);
  evaluation.result.addText(evaluation.isNegated ? " did not allocate non-GC memory." : " allocated non-GC memory.");

  evaluation.result.expected.put(evaluation.isNegated ? "not to allocate non-GC memory" : "to allocate non-GC memory");
  evaluation.result.actual.put("allocated ");
  evaluation.result.actual.put(evaluation.currentValue.nonGCMemoryUsed.formatBytes);
}

// Non-GC memory tracking for large allocations works on Linux (using mallinfo).
// Note: mallinfo() reports total heap state, so small runtime allocations may be detected
// even when the tested code doesn't allocate. This is a platform limitation.
// macOS and Windows don't have reliable non-GC memory delta tracking.
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

// This test only runs on non-Linux platforms because mallinfo() picks up runtime noise.
// On Linux, even code that doesn't allocate may show allocations due to runtime activity.
version (linux) {} else {
  @("it fails when a callable does not allocate non-GC memory and it is expected to")
  unittest {
    auto evaluation = ({
      ({
        int[4] stackArray = [1,2,3,4];
        return stackArray.length;
      }).should.allocateNonGCMemory();
    }).recordEvaluation;

    expect(evaluation.result.expected[]).to.equal(`to allocate non-GC memory`);
    expect(evaluation.result.actual[]).to.startWith("allocated ");
  }
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

    expect(evaluation.result.expected[]).to.equal(`not to allocate non-GC memory`);
    expect(evaluation.result.actual[].idup).to.startWith("allocated ");
    expect(evaluation.result.actual[].idup).to.endWith("MB");
  }
}

// Non-GC memory tracking uses process-wide metrics (phys_footprint on macOS).
// This test is disabled because parallel test execution causes false positives -
// other threads' allocations are included in the measurement.
// To run this test accurately, use: dub test -- -j1 (single-threaded)
version (none) {
  @("it does not fail when a callable does not allocate non-GC memory and it is not expected to")
  unittest {
    ({
      int[4] stackArray = [1,2,3,4];
      return stackArray.length;
    }).should.not.allocateNonGCMemory();
  }
}
