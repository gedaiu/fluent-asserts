module test.operations.arrayContain;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;
import std.algorithm;
import std.range;

alias s = Spec!({
  alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real, ifloat, idouble, ireal, cfloat, cdouble, creal);
  static foreach(Type; NumericTypes) {
    describe("using a range of " ~ Type.stringof, {
      Type[] testValues;
      Type[] someTestValues;
      Type[] otherTestValues;

      static if(is(ifloat == Type) || is(idouble == Type) || is(ireal == Type)) {
        before({
          testValues = [ 40i, 41i, 42i];
          someTestValues = [ 42i, 41i];
          otherTestValues = [ 50i, 51i, 52i ];
        });
      } else {
        before({
          testValues = [ cast(Type) 40, cast(Type) 41, cast(Type) 42 ];
          someTestValues = [ cast(Type) 42, cast(Type) 41 ];
          otherTestValues = [ cast(Type) 50, cast(Type) 51 ];
        });
      }

      it("should find two values in a list", {
        expect(testValues.map!"a").to.contain(someTestValues);
      });

      it("should find a value in a list", {
        expect(testValues.map!"a").to.contain(someTestValues[0]);
      });

      it("should find other values in a list", {
        expect(testValues.map!"a").to.not.contain(otherTestValues);
      });

      it("should find other value in a list", {
        expect(testValues.map!"a").to.not.contain(otherTestValues[0]);
      });

      it("should show a detailed error message when the list does not contain 2 values", {
        auto msg = ({
          expect(testValues.map!"a").to.contain([4, 5]);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should contain [4, 5]. [4, 5] are missing from " ~ testValues.to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Expected:to contain all [4, 5]");
        msg.split('\n')[3].strip.should.equal("Actual:" ~ testValues.to!string);
      });

      it("should show a detailed error message when the list does not contain 2 values", {
        auto msg = ({
          expect(testValues.map!"a").to.not.contain(testValues[0..2]);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should not contain " ~ testValues[0..2].to!string ~ ". " ~ testValues[0..2].to!string ~ " are present in " ~ testValues.to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Expected:to not contain any " ~ testValues[0..2].to!string);
        msg.split('\n')[3].strip.should.equal("Actual:" ~ testValues.to!string);
      });

      it("should show a detailed error message when the list does not contain a value", {
        auto msg = ({
          expect(testValues.map!"a").to.contain(otherTestValues[0]);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should contain " ~ otherTestValues[0].to!string ~ ". " ~ otherTestValues[0].to!string ~ " is missing from " ~ testValues.to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Expected:to contain " ~ otherTestValues[0].to!string);
        msg.split('\n')[3].strip.should.equal("Actual:" ~ testValues.to!string);
      });

      it("should show a detailed error message when the list does contains a value", {
        auto msg = ({
          expect(testValues.map!"a").to.not.contain(testValues[0]);
        }).should.throwException!TestException.msg;

        msg.split('\n')[0].should.equal(testValues.to!string ~ " should not contain " ~ testValues[0].to!string ~ ". " ~ testValues[0].to!string ~ " is present in " ~ testValues.to!string ~ ".");
        msg.split('\n')[2].strip.should.equal("Expected:to not contain " ~ testValues[0].to!string);
        msg.split('\n')[3].strip.should.equal("Actual:" ~ testValues.to!string);
      });
    });
  }
});
