module test.operations.containOnly;

import fluentasserts.core.expect;
import fluentasserts.core.serializers;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;
import std.algorithm;
import std.range;

alias s = Spec!({
  alias StringTypes = AliasSeq!(string, wstring, dstring);

  static foreach(Type; StringTypes) {
    describe("using a range of " ~ Type.stringof, {
      Type[] testValues;
      Type[] testValuesWithOtherOrder;
      Type[] otherTestValues;

      before({
        testValues = [ "40".to!Type, "41".to!Type, "42".to!Type ];
        testValuesWithOtherOrder = [ "42".to!Type, "41".to!Type, "40".to!Type ];
        otherTestValues = [ "50".to!Type, "51".to!Type ];
      });

      it("should find all items in the expected list", {
        expect(testValues).to.containOnly(testValuesWithOtherOrder);
      });

      it("should not fail on checking if the list contains only a substring", {
        expect(testValues).not.to.containOnly(testValues[0..2]);
      });

      it("should find all duplicated items", {
        expect(testValues ~ testValues).to.containOnly(testValuesWithOtherOrder ~ testValuesWithOtherOrder);
      });

      it("should not fail on checking if the list contains only a substring of unique values", {
        expect(testValues ~ testValues).not.to.containOnly(testValues);
      });

      it("should throw a detailed error when the array does not contain only the provided values", {
        auto msg = ({
          expect(testValues).to.containOnly(testValues[0..2]);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should contain only " ~ testValues[0..2].to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Actual:" ~ testValues.to!string);
        msg.split('\n')[4].strip.should.equal("Missing:" ~ testValues[$-1..$].to!string);
      });

      it("should throw a detailed error when the list shoul not contain some values", {
        auto msg = ({
          expect(testValues).to.not.containOnly(testValuesWithOtherOrder);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should not contain only " ~ testValuesWithOtherOrder.to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Expected:to not contain " ~ testValuesWithOtherOrder.to!string);
        msg.split('\n')[3].strip.should.equal("Actual:" ~ testValues.to!string);
      });
    });
  }

  alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real/*, ifloat, idouble, ireal, cfloat, cdouble, creal*/);
  static foreach(Type; NumericTypes) {
    describe("using a range of " ~ Type.stringof, {
      Type[] testValues;
      Type[] testValuesWithOtherOrder;
      Type[] otherTestValues;

      static if(is(ifloat == Type) || is(idouble == Type) || is(ireal == Type)) {
        before({
          testValues = [ 40i, 41i, 42i];
          testValuesWithOtherOrder = [ 42i, 41i, 40i];
          otherTestValues = [ 50i, 51i ];
        });
      } else {
        before({
          testValues = [ cast(Type) 40, cast(Type) 41, cast(Type) 42 ];
          testValuesWithOtherOrder = [ cast(Type) 42, cast(Type) 41, cast(Type) 40 ];
          otherTestValues = [ cast(Type) 50, cast(Type) 51 ];
        });
      }

      it("should find all items in the expected list", {
        expect(testValues).to.containOnly(testValuesWithOtherOrder);
      });

      it("should not fail on checking if the list contains only a substring", {
        expect(testValues).not.to.containOnly(testValues[0..2]);
      });

      it("should find all duplicated items", {
        expect(testValues ~ testValues).to.containOnly(testValuesWithOtherOrder ~ testValuesWithOtherOrder);
      });

      it("should not fail on checking if the list contains only a substring of unique values", {
        expect(testValues ~ testValues).not.to.containOnly(testValues);
      });

      it("should throw a detailed error when the array does not contain only the provided values", {
        auto msg = ({
          expect(testValues).to.containOnly(testValues[0..2]);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should contain only " ~ testValues[0..2].to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Actual:" ~ testValues.to!string);
        msg.split('\n')[4].strip.should.equal("Missing:" ~ testValues[$-1..$].to!string);
      });

      it("should throw a detailed error when the list shoul not contain some values", {
        auto msg = ({
          expect(testValues).to.not.containOnly(testValuesWithOtherOrder);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should not contain only " ~ testValuesWithOtherOrder.to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Expected:to not contain " ~ testValuesWithOtherOrder.to!string);
        msg.split('\n')[3].strip.should.equal("Actual:" ~ testValues.to!string);
      });
    });
  }

  describe("using an array of arrays", {
    int[][] testValues;
    int[][] testValuesWithOtherOrder;
    int[][] otherTestValues;

    before({
      testValues = [ [40], [41, 41], [42,42,42] ];
      testValuesWithOtherOrder = [ [42,42,42], [41, 41], [40] ];
      otherTestValues = [ [50], [51] ];
    });

    it("should find all items in the expected list", {
      expect(testValues).to.containOnly(testValuesWithOtherOrder);
    });

    it("should not fail on checking if the list contains only a substring", {
      expect(testValues).not.to.containOnly(testValues[0..2]);
    });

    it("should find all duplicated items", {
      expect(testValues ~ testValues).to.containOnly(testValuesWithOtherOrder ~ testValuesWithOtherOrder);
    });

    it("should not fail on checking if the list contains only a substring of unique values", {
      expect(testValues ~ testValues).not.to.containOnly(testValues);
    });

    it("should throw a detailed error when the array does not contain only the provided values", {
      auto msg = ({
        expect(testValues).to.containOnly(testValues[0..2]);
      }).should.throwException!TestException.msg;

      msg.split('\n')[0].should.equal(testValues.to!string ~ " should contain only " ~ testValues[0..2].to!string ~ ".");
      msg.split('\n')[2].strip.should.equal("Actual:" ~ testValues.to!string);
      msg.split('\n')[4].strip.should.equal("Missing:" ~ testValues[$-1..$].to!string);
    });

    it("should throw a detailed error when the list shoul not contain some values", {
      auto msg = ({
        expect(testValues).to.not.containOnly(testValuesWithOtherOrder);
      }).should.throwException!TestException.msg;

      msg.split('\n')[0].should.equal(testValues.to!string ~ " should not contain only " ~ testValuesWithOtherOrder.to!string ~ ".");
      msg.split('\n')[2].strip.should.equal("Expected:to not contain " ~ testValuesWithOtherOrder.to!string);
      msg.split('\n')[3].strip.should.equal("Actual:" ~ testValues.to!string);
    });
  });

  describe("using a range of Objects without opEquals", {
    Object[] testValues;
    Object[] testValuesWithOtherOrder;
    Object[] otherTestValues;

    before({
      testValues = [new Object(), new Object()];
      testValuesWithOtherOrder = [testValues[1], testValues[0]];
      otherTestValues = [new Object(), new Object()];
    });

    it("should find all items in the expected list", {
      expect(testValues).to.containOnly(testValuesWithOtherOrder);
    });

    it("should not fail on checking if the list contains only a subset", {
      expect(testValues).not.to.containOnly([testValues[0]]);
    });

    it("should find all duplicated items", {
      expect(testValues ~ testValues).to.containOnly(testValuesWithOtherOrder ~ testValuesWithOtherOrder);
    });

    it("should not fail on checking if the list contains only a substring of unique values", {
      expect(testValues ~ testValues).not.to.containOnly(testValues);
    });

    it("should throw a detailed error when the array does not contain only the provided values", {
      auto msg = ({
        expect(testValues).to.containOnly([testValues[0]]);
      }).should.throwException!TestException.msg;

      msg.split('\n')[0].should.contain(")] should contain only [Object(");
      msg.split('\n')[2].strip.should.startWith("Actual:[Object(");
      msg.split('\n')[4].strip.should.startWith("Missing:[Object(");
    });

    it("should throw a detailed error when the list shoul not contain some values", {
      auto msg = ({
        expect(testValues).to.not.containOnly(testValuesWithOtherOrder);
      }).should.throwException!TestException.msg;

      msg.split('\n')[0].should.contain(")] should not contain only [Object(");
      msg.split('\n')[2].strip.should.startWith("Expected:to not contain [Object(");
      msg.split('\n')[3].strip.should.startWith("Actual:[Object(");
    });
  });

  describe("using a range of Objects with opEquals", {
      Thing[] testValues;
      Thing[] testValuesWithOtherOrder;
      Thing[] otherTestValues;

      string strTestValues;
      string strTestValuesWithOtherOrder;
      string strOtherTestValues;

      before({
        testValues = [ new Thing(40), new Thing(41), new Thing(42) ];
        testValuesWithOtherOrder = [ new Thing(42), new Thing(41), new Thing(40) ];
        otherTestValues = [ new Thing(50), new Thing(51) ];

        strTestValues = SerializerRegistry.instance.niceValue(testValues);
        strTestValuesWithOtherOrder = SerializerRegistry.instance.niceValue(testValuesWithOtherOrder);
        strOtherTestValues = SerializerRegistry.instance.niceValue(otherTestValues);
      });

      it("should find all items in the expected list", {
        expect(testValues).to.containOnly(testValuesWithOtherOrder);
      });

      it("should not fail on checking if the list contains only a substring", {
        expect(testValues).not.to.containOnly(testValues[0..2]);
      });

      it("should find all duplicated items", {
        expect(testValues ~ testValues).to.containOnly(testValuesWithOtherOrder ~ testValuesWithOtherOrder);
      });

      it("should not fail on checking if the list contains only a substring of unique values", {
        expect(testValues ~ testValues).not.to.containOnly(testValues);
      });

      it("should throw a detailed error when the array does not contain only the provided values", {
        auto msg = ({
          expect(testValues).to.containOnly(testValues[0..2]);
        }).should.throwException!TestException.msg;

        msg.split('\n')[2].strip.should.equal("Actual:" ~ strTestValues);
        msg.split('\n')[4].strip.should.equal("Missing:" ~ SerializerRegistry.instance.niceValue(testValues[$-1..$]));
      });

      it("should throw a detailed error when the list shoul not contain some values", {
        auto msg = ({
          expect(testValues).to.not.containOnly(testValuesWithOtherOrder);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(strTestValues ~ " should not contain only " ~ strTestValuesWithOtherOrder ~ ".");
        msg.split('\n')[2].strip.should.equal("Expected:to not contain " ~ strTestValuesWithOtherOrder);
        msg.split('\n')[3].strip.should.equal("Actual:" ~ strTestValues);
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
}
