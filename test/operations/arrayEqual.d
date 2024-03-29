module test.operations.arrayEqual;

import fluentasserts.core.expect;
import fluent.asserts;
import fluentasserts.core.serializers;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;

alias s = Spec!({

  alias StringTypes = AliasSeq!(string, wstring, dstring);
  alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real /*, ifloat, idouble, ireal, cfloat, cdouble, creal*/);

  static foreach(Type; StringTypes) {
    describe("using an array of " ~ Type.stringof, {
      Type[] aList;
      Type[] anotherList;
      Type[] aListInOtherOrder;

      before({
        aList = [ "a", "b", "c" ];
        aListInOtherOrder = [ "c", "b", "a" ];
        anotherList = [ "b", "c" ];
      });

      it("should compare two exact arrays", {
        expect(aList).to.equal(aList);
      });

      it("should be able to compare that two arrays are not equal", {
        expect(aList).to.not.equal(aListInOtherOrder);
        expect(aList).to.not.equal(anotherList);
        expect(anotherList).to.not.equal(aList);
      });

      it("should throw a detailed error message when the two arrays are not equal", {
        auto msg = ({
          expect(aList).to.equal(anotherList);
        }).should.throwException!TestException.msg.split("\n");

        msg[0].strip.should.equal(aList.to!string ~ " should equal " ~ anotherList.to!string ~ ".");
        msg[1].strip.should.equal("Diff:");
        msg[2].strip.should.equal(`["[+a", "]b", "c"]`);
        msg[4].strip.should.equal("Expected:" ~ anotherList.to!string);
        msg[5].strip.should.equal("Actual:" ~ aList.to!string);
      });

      it("should throw an error when the arrays have the same values in a different order", {
        auto msg = ({
          expect(aList).to.equal(aListInOtherOrder);
        }).should.throwException!TestException.msg.split("\n");

        msg[0].strip.should.equal(aList.to!string ~ " should equal " ~ aListInOtherOrder.to!string ~ ".");
        msg[1].strip.should.equal("Diff:");
        msg[2].strip.should.equal(`["[-c][+a]", "b", "[-a][+c]"]`);
        msg[4].strip.should.equal("Expected:" ~ aListInOtherOrder.to!string);
        msg[5].strip.should.equal("Actual:" ~ aList.to!string);
      });

      it("should throw an error when the arrays should not be equal", {
        auto msg = ({
          expect(aList).not.to.equal(aList);
        }).should.throwException!TestException.msg.split("\n");

        msg[0].strip.should.startWith(aList.to!string ~ " should not equal " ~ aList.to!string ~ ".");
        msg[2].strip.should.equal(`Expected:not ["a", "b", "c"]`);
        msg[3].strip.should.equal(`Actual:["a", "b", "c"]`);
      });
    });
  }

  describe("using an array of arrays", {
    int[][] aList;
    int[][] anotherList;
    int[][] aListInOtherOrder;

    before({
      aList = [ [1], [2,2], [3,3,3] ];
      aListInOtherOrder = [ [3,3,3], [2,2], [1] ];
      anotherList = [ [2], [3] ];
    });

    it("should compare two exact arrays", {
      expect(aList).to.equal(aList);
    });

    it("should be able to compare that two arrays are not equal", {
      expect(aList).to.not.equal(aListInOtherOrder);
      expect(aList).to.not.equal(anotherList);
      expect(anotherList).to.not.equal(aList);
    });

    it("should throw a detailed error message when the two arrays are not equal", {
      auto msg = ({
        expect(aList).to.equal(anotherList);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.equal(aList.to!string ~ " should equal " ~ anotherList.to!string ~ ".");
      msg[1].strip.should.equal("Diff:");
      msg[2].strip.should.equal(`[[[+1], [2, ]2], [[+3, 3, ]3]]`);
      msg[4].strip.should.equal("Expected:" ~ anotherList.to!string);
      msg[5].strip.should.equal("Actual:" ~ aList.to!string);
    });

    it("should throw an error when the arrays have the same values in a different order", {
      auto msg = ({
        expect(aList).to.equal(aListInOtherOrder);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.equal(aList.to!string ~ " should equal " ~ aListInOtherOrder.to!string ~ ".");
      msg[1].strip.should.equal("Diff:");
      msg[2].strip.should.equal(`[[[-3, 3, 3][+1]], [2, 2], [[-1][+3, 3, 3]]]`);
      msg[4].strip.should.equal("Expected:" ~ aListInOtherOrder.to!string);
      msg[5].strip.should.equal("Actual:" ~ aList.to!string);
    });

    it("should throw an error when the arrays should not be equal", {
      auto msg = ({
        expect(aList).not.to.equal(aList);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.startWith(aList.to!string ~ " should not equal " ~ aList.to!string ~ ".");
      msg[2].strip.should.equal(`Expected:not [[1], [2, 2], [3, 3, 3]]`);
      msg[3].strip.should.equal(`Actual:[[1], [2, 2], [3, 3, 3]]`);
    });
  });

  static foreach(Type; NumericTypes) {
    describe("using an array of " ~ Type.stringof, {
      Type[] aList;
      Type[] anotherList;
      Type[] aListInOtherOrder;

      before({
        static if(is(ifloat == Type) || is(idouble == Type) || is(ireal == Type)) {
          aList = [ cast(Type) 1i, cast(Type) 2i, cast(Type) 3i ];
          aListInOtherOrder = [ cast(Type) 3i, cast(Type) 2i, cast(Type) 1i ];
          anotherList = [ cast(Type) 2i, cast(Type) 3i ];
        } else {
          aList = [ cast(Type) 1, cast(Type) 2, cast(Type) 3 ];
          aListInOtherOrder = [ cast(Type) 3, cast(Type) 2, cast(Type) 1 ];
          anotherList = [ cast(Type) 2, cast(Type) 3 ];
        }
      });

      it("should compare two exact arrays", {
        expect(aList).to.equal(aList);
      });

      it("should be able to compare that two arrays are not equal", {
        expect(aList).to.not.equal(aListInOtherOrder);
        expect(aList).to.not.equal(anotherList);
        expect(anotherList).to.not.equal(aList);
      });

      it("should throw a detailed error message when the two arrays are not equal", {
        auto msg = ({
          expect(aList).to.equal(anotherList);
        }).should.throwException!TestException.msg.split("\n");

        msg[0].strip.should.equal(aList.to!string ~ " should equal " ~ anotherList.to!string ~ ".");
        msg[1].strip.should.equal("Diff:");

        static if(is(ifloat == Type) || is(idouble == Type) || is(ireal == Type)) {
          msg[2].strip.should.equal("[[+1i, ]2i, 3i]");
        } else static if(is(cfloat == Type) || is(cdouble == Type) || is(creal == Type)) {
          msg[2].strip.should.equal("[[+1+0i, ]2+0i, 3+0i]");
        } else {
          msg[2].strip.should.equal("[[+1, ]2, 3]");
        }

        msg[4].strip.should.equal("Expected:" ~ anotherList.to!string);
        msg[5].strip.should.equal("Actual:" ~ aList.to!string);
      });

      it("should throw an error when the arrays have the same values in a different order", {
        auto msg = ({
          expect(aList).to.equal(aListInOtherOrder);
        }).should.throwException!TestException.msg.split("\n");

        msg[0].strip.should.equal(aList.to!string ~ " should equal " ~ aListInOtherOrder.to!string ~ ".");
        msg[1].strip.should.equal("Diff:");

        static if(is(ifloat == Type) || is(idouble == Type) || is(ireal == Type)) {
          msg[2].strip.should.equal("[[-3][+1]i, 2i, [-1][+3]i]");
        } else static if(is(cfloat == Type) || is(cdouble == Type) || is(creal == Type)) {
          msg[2].strip.should.equal("[[-3][+1]+0i, 2+0i, [-1][+3]+0i]");
        } else {
          msg[2].strip.should.equal("[[-3][+1], 2, [-1][+3]]");
        }

        msg[4].strip.should.equal("Expected:" ~ aListInOtherOrder.to!string);
        msg[5].strip.should.equal("Actual:" ~ aList.to!string);
      });

      it("should throw an error when the arrays should not be equal", {
        auto msg = ({
          expect(aList).not.to.equal(aList);
        }).should.throwException!TestException.msg.split("\n");

        msg[0].strip.should.startWith(aList.to!string ~ " should not equal " ~ aList.to!string ~ ".");

        static if(is(ifloat == Type) || is(idouble == Type) || is(ireal == Type)) {
          msg[2].strip.should.equal("Expected:not [1i, 2i, 3i]");
          msg[3].strip.should.equal("Actual:[1i, 2i, 3i]");
        } else static if(is(cfloat == Type) || is(cdouble == Type) || is(creal == Type)) {
          msg[2].strip.should.equal("Expected:not [1+0i, 2+0i, 3+0i]");
          msg[3].strip.should.equal("Actual:[1+0i, 2+0i, 3+0i]");
        } else {
          msg[2].strip.should.equal("Expected:not [1, 2, 3]");
          msg[3].strip.should.equal("Actual:[1, 2, 3]");
        }
      });
    });
  }

  describe("using an array of objects with opEquals", {
    Thing[] aList;
    Thing[] anotherList;
    Thing[] aListInOtherOrder;

    string strAList;
    string strAnotherList;
    string strAListInOtherOrder;

    before({
        aList = [ new Thing(1), new Thing(2), new Thing(3) ];
        aListInOtherOrder = [ new Thing(3), new Thing(2), new Thing(1) ];
        anotherList = [ new Thing(2), new Thing(3) ];

        strAList = SerializerRegistry.instance.niceValue(aList);
        strAnotherList = SerializerRegistry.instance.niceValue(anotherList);
        strAListInOtherOrder = SerializerRegistry.instance.niceValue(aListInOtherOrder);
    });

    it("should compare two exact arrays", {
      expect(aList).to.equal(aList);
    });

    it("should be able to compare that two arrays are not equal", {
      expect(aList).to.not.equal(aListInOtherOrder);
      expect(aList).to.not.equal(anotherList);
      expect(anotherList).to.not.equal(aList);
    });

    it("should throw a detailed error message when the two arrays are not equal", {
      auto msg = ({
        expect(aList).to.equal(anotherList);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.equal(strAList.to!string ~ " should equal " ~ strAnotherList.to!string ~ ".");
      msg[1].strip.should.equal("Diff:");
      msg[4].strip.should.equal("Expected:" ~ strAnotherList.to!string);
      msg[5].strip.should.equal("Actual:" ~ strAList.to!string);
    });

    it("should throw an error when the arrays have the same values in a different order", {
      auto msg = ({
        expect(aList).to.equal(aListInOtherOrder);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.equal(strAList.to!string ~ " should equal " ~ strAListInOtherOrder ~ ".");
      msg[1].strip.should.equal("Diff:");
      msg[4].strip.should.equal("Expected:" ~ strAListInOtherOrder);
      msg[5].strip.should.equal("Actual:" ~ strAList.to!string);
    });

    it("should throw an error when the arrays should not be equal", {
      auto msg = ({
        expect(aList).not.to.equal(aList);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.startWith(strAList.to!string ~ " should not equal " ~ strAList.to!string ~ ".");
      msg[2].strip.should.equal("Expected:not " ~ strAList);
      msg[3].strip.should.equal("Actual:" ~ strAList);
    });
  });
});


version(unittest) :
class Thing {
	int x;

  this(int x) { this.x = x; }

	override bool opEquals(Object o) {
		if(typeid(this) != typeid(o)) return false;
		alias a = this;
		auto b = cast(typeof(this)) o;

		return a.x == b.x;
	}

  override string toString() {
    return x.to!string;
  }
}