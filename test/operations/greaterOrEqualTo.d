module test.operations.greaterOrEqualTo;

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
        expect(largeValue).to.be.greaterOrEqualTo(smallValue);
        expect(largeValue).to.be.greaterOrEqualTo(largeValue);
      });

      it("should be able to compare two values using negation", {
        expect(smallValue).not.to.be.greaterOrEqualTo(largeValue);
      });

      it("should throw a detailed error when the comparison fails", {
        auto msg = ({
          expect(smallValue).to.be.greaterOrEqualTo(largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be greater or equal to " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than " ~ largeValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:greater or equal than " ~ largeValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
      });

      it("should throw a detailed error when the negated coparison fails", {
        auto msg = ({
          expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(largeValue.to!string ~ " should not be greater or equal to " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater or equal than " ~ smallValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:less than " ~ smallValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ largeValue.to!string);
      });
    });
  }
});
