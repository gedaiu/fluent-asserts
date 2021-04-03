module test.operations.lessOrEqualTo;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;
import std.datetime;

alias s = Spec!({
  alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

  static foreach(Type; NumericTypes) {
    describe("using " ~ Type.stringof ~ " values", {
      Type smallValue;
      Type largeValue;

      before({
        smallValue = cast(Type) 40;
        largeValue = cast(Type) 50;
      });

      it("should be able to compare two values", {
        expect(smallValue).to.be.lessOrEqualTo(largeValue);
        expect(smallValue).to.be.lessOrEqualTo(smallValue);
      });

      it("should be able to compare two values using negation", {
        expect(largeValue).not.to.be.lessOrEqualTo(smallValue);
      });

      it("should throw a detailed error when the comparison fails", {
        auto msg = ({
          expect(largeValue).to.be.lessOrEqualTo(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be less or equal to " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than " ~ smallValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:less or equal to " ~ smallValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ largeValue.to!string);
      });

      it("should throw a detailed error when the negated comparison fails", {
        auto msg = ({
          expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should not be less or equal to " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less or equal to " ~ largeValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:greater than " ~ largeValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
      });
    });
  }
});
