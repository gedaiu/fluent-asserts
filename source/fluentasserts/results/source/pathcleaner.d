/// Path cleaning for mixin-generated files.
module fluentasserts.results.source.pathcleaner;

@safe:

/// Cleans up mixin paths by removing the `-mixin-N` suffix.
/// When D uses string mixins, __FILE__ produces paths like `file.d-mixin-113`
/// instead of `file.d`. This function returns the actual file path.
/// Params:
///   path = The file path, possibly with mixin suffix
/// Returns: The cleaned path with `.d` extension, or original path if not a mixin path
string cleanMixinPath(string path) pure nothrow @nogc {
    // Look for pattern: .d-mixin-N at the end
    enum suffix = ".d-mixin-";

    // Find the last occurrence of ".d-mixin-"
    size_t suffixPos = size_t.max;
    if (path.length > suffix.length) {
        foreach_reverse (i; 0 .. path.length - suffix.length + 1) {
            bool match = true;
            foreach (j; 0 .. suffix.length) {
                if (path[i + j] != suffix[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                suffixPos = i;
                break;
            }
        }
    }

    if (suffixPos == size_t.max) {
        return path;
    }

    // Verify the rest is digits (valid line number)
    size_t numStart = suffixPos + suffix.length;
    foreach (i; numStart .. path.length) {
        char c = path[i];
        if (c < '0' || c > '9') {
            return path;
        }
    }

    if (numStart >= path.length) {
        return path;
    }

    // Return cleaned path (up to and including .d)
    return path[0 .. suffixPos + 2];
}

version(unittest) {
  import fluent.asserts;
}

@("cleanMixinPath returns original path for regular .d file")
unittest {
  cleanMixinPath("source/test.d").should.equal("source/test.d");
}

@("cleanMixinPath removes mixin suffix from path")
unittest {
  cleanMixinPath("source/test.d-mixin-113").should.equal("source/test.d");
}

@("cleanMixinPath handles paths with multiple dots")
unittest {
  cleanMixinPath("source/my.module.test.d-mixin-55").should.equal("source/my.module.test.d");
}

@("cleanMixinPath returns original for invalid mixin suffix with letters")
unittest {
  cleanMixinPath("source/test.d-mixin-abc").should.equal("source/test.d-mixin-abc");
}

@("cleanMixinPath returns original for empty line number")
unittest {
  cleanMixinPath("source/test.d-mixin-").should.equal("source/test.d-mixin-");
}
