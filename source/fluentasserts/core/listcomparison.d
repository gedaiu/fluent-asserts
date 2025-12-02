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

  private long findIndex(T[] list, T element) {
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

  T[] missing() @trusted {
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

  T[] extra() @trusted {
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

  T[] common() @trusted {
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

@("ListComparison gets missing elements")
unittest {
  auto comparison = ListComparison!int([1, 2, 3], [4]);

  auto missing = comparison.missing;

  assert(missing.length == 3);
  assert(missing[0] == 1);
  assert(missing[1] == 2);
  assert(missing[2] == 3);
}

@("ListComparison gets missing elements with duplicates")
unittest {
  auto comparison = ListComparison!int([2, 2], [2]);

  auto missing = comparison.missing;

  assert(missing.length == 1);
  assert(missing[0] == 2);
}

@("ListComparison gets extra elements")
unittest {
  auto comparison = ListComparison!int([4], [1, 2, 3]);

  auto extra = comparison.extra;

  assert(extra.length == 3);
  assert(extra[0] == 1);
  assert(extra[1] == 2);
  assert(extra[2] == 3);
}

@("ListComparison gets extra elements with duplicates")
unittest {
  auto comparison = ListComparison!int([2], [2, 2]);

  auto extra = comparison.extra;

  assert(extra.length == 1);
  assert(extra[0] == 2);
}

@("ListComparison gets common elements")
unittest {
  auto comparison = ListComparison!int([1, 2, 3, 4], [2, 3]);

  auto common = comparison.common;

  assert(common.length == 2);
  assert(common[0] == 2);
  assert(common[1] == 3);
}

@("ListComparison gets common elements with duplicates")
unittest {
  auto comparison = ListComparison!int([2, 2, 2, 2], [2, 2]);

  auto common = comparison.common;

  assert(common.length == 2);
  assert(common[0] == 2);
  assert(common[1] == 2);
}
