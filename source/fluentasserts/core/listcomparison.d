module fluentasserts.core.listcomparison;

import std.algorithm;
import std.array;
import std.traits;
import std.math;

import fluentasserts.core.evaluation : EquableValue;

U[] toValueList(U, V)(V expectedValueList) @trusted {
  import std.range : isInputRange, ElementType;

  static if(is(V == void[])) {
    return [];
  } else static if(is(V == U[])) {
    static if(is(U == immutable) || is(U == const)) {
      static if(is(U == class)) {
        return expectedValueList;
      } else {
        return expectedValueList.idup;
      }
    } else {
      return expectedValueList.dup;
    }
  } else static if(is(U == immutable) || is(U == const)) {
    static if(is(U == class)) {
      return expectedValueList.array;
    } else {
      return expectedValueList.array.idup;
    }
  } else {
    static if(is(U == class)) {
      return cast(U[]) expectedValueList.array;
    } else {
      return cast(U[]) expectedValueList.array.dup;
    }
  }
}

@trusted:

struct ListComparison(Type) {
  alias T = Unqual!Type;

  private {
    T[] referenceList;
    T[] list;
    double maxRelDiff;
  }

  this(U, V)(U reference, V list, double maxRelDiff = 0) {
    this.referenceList = toValueList!T(reference);
    this.list = toValueList!T(list);
    this.maxRelDiff = maxRelDiff;
  }

  private long findIndex(T[] list, T element) nothrow {
    static if(std.traits.isNumeric!(T)) {
        return list.countUntil!(a => approxEqual(element, a, maxRelDiff));
      } else static if(is(T == EquableValue)) {
        foreach(index, a; list) {
          if(a.isEqualTo(element)) {
            return index;
          }
        }

        return -1;
      } else {
        return list.countUntil(element);
      }
  }

  T[] missing() @trusted nothrow {
    T[] result;

    auto tmpList = list.dup;

    foreach(element; referenceList) {
      auto index = this.findIndex(tmpList, element);

      if(index == -1) {
        result ~= element;
      } else {
        tmpList = remove(tmpList, index);
      }
    }

    return result;
  }

  T[] extra() @trusted nothrow {
    T[] result;

    auto tmpReferenceList = referenceList.dup;

    foreach(element; list) {
      auto index = this.findIndex(tmpReferenceList, element);

      if(index == -1) {
        result ~= element;
      } else {
        tmpReferenceList = remove(tmpReferenceList, index);
      }
    }

    return result;
  }

  T[] common() @trusted nothrow {
    T[] result;

    auto tmpList = list.dup;

    foreach(element; referenceList) {
      if(tmpList.length == 0) {
        break;
      }

      auto index = this.findIndex(tmpList, element);

      if(index >= 0) {
        result ~= element;
        tmpList = std.algorithm.remove(tmpList, index);
      }
    }

    return result;
  }
}

version(unittest) {
  import fluentasserts.core.lifecycle;
}

@("ListComparison gets missing elements")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto comparison = ListComparison!int([1, 2, 3], [4]);

  auto missing = comparison.missing;

  import std.conv : to;
  assert(missing.length == 3, "Expected 3 missing elements, got " ~ missing.length.to!string);
  assert(missing[0] == 1, "Expected missing[0] == 1, got " ~ missing[0].to!string);
  assert(missing[1] == 2, "Expected missing[1] == 2, got " ~ missing[1].to!string);
  assert(missing[2] == 3, "Expected missing[2] == 3, got " ~ missing[2].to!string);
}

@("ListComparison gets missing elements with duplicates")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto comparison = ListComparison!int([2, 2], [2]);

  auto missing = comparison.missing;

  import std.conv : to;
  assert(missing.length == 1, "Expected 1 missing element, got " ~ missing.length.to!string);
  assert(missing[0] == 2, "Expected missing[0] == 2, got " ~ missing[0].to!string);
}

@("ListComparison gets extra elements")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto comparison = ListComparison!int([4], [1, 2, 3]);

  auto extra = comparison.extra;

  import std.conv : to;
  assert(extra.length == 3, "Expected 3 extra elements, got " ~ extra.length.to!string);
  assert(extra[0] == 1, "Expected extra[0] == 1, got " ~ extra[0].to!string);
  assert(extra[1] == 2, "Expected extra[1] == 2, got " ~ extra[1].to!string);
  assert(extra[2] == 3, "Expected extra[2] == 3, got " ~ extra[2].to!string);
}

@("ListComparison gets extra elements with duplicates")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto comparison = ListComparison!int([2], [2, 2]);

  auto extra = comparison.extra;

  import std.conv : to;
  assert(extra.length == 1, "Expected 1 extra element, got " ~ extra.length.to!string);
  assert(extra[0] == 2, "Expected extra[0] == 2, got " ~ extra[0].to!string);
}

@("ListComparison gets common elements")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto comparison = ListComparison!int([1, 2, 3, 4], [2, 3]);

  auto common = comparison.common;

  import std.conv : to;
  assert(common.length == 2, "Expected 2 common elements, got " ~ common.length.to!string);
  assert(common[0] == 2, "Expected common[0] == 2, got " ~ common[0].to!string);
  assert(common[1] == 3, "Expected common[1] == 3, got " ~ common[1].to!string);
}

@("ListComparison gets common elements with duplicates")
unittest {
  Lifecycle.instance.disableFailureHandling = false;
  auto comparison = ListComparison!int([2, 2, 2, 2], [2, 2]);

  auto common = comparison.common;

  import std.conv : to;
  assert(common.length == 2, "Expected 2 common elements, got " ~ common.length.to!string);
  assert(common[0] == 2, "Expected common[0] == 2, got " ~ common[0].to!string);
  assert(common[1] == 2, "Expected common[1] == 2, got " ~ common[1].to!string);
}
