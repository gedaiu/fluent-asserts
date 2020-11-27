module test.operations.lessThan;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;

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
        expect(smallValue).to.be.lessThan(largeValue);
        expect(smallValue).to.be.below(largeValue);
      });

      it("should be able to compare two values using negation", {
        expect(largeValue).not.to.be.lessThan(smallValue);
        expect(largeValue).not.to.be.below(smallValue);
      });

      it("should throw a detailed error when the number is compared with itself", {
        auto msg = ({
          expect(smallValue).to.be.lessThan(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be less than " ~ smallValue.to!string ~ ". " ~ smallValue.to!string ~ " is greater than or equal to " ~ smallValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:less than " ~ smallValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
      });

      it("should throw a detailed error when the negated coparison fails", {
        auto msg = ({
          expect(smallValue).not.to.be.lessThan(largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should not be less than " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than " ~ largeValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:greater than or equal to " ~ largeValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
      });
    });
  }
});
