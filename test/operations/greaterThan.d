module test.operations.greaterThan;

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
        expect(largeValue).to.be.greaterThan(smallValue);
        expect(largeValue).to.be.above(smallValue);
      });

      it("should be able to compare two values using negation", {
        expect(smallValue).not.to.be.greaterThan(largeValue);
        expect(smallValue).not.to.be.above(largeValue);
      });

      it("should throw a detailed error when the number is compared with itself", {
        auto msg = ({
          expect(smallValue).to.be.greaterThan(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be greaterThan " ~ smallValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:greater than " ~ smallValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
      });

      it("should throw a detailed error when the comparison fails", {
        auto msg = ({
          expect(smallValue).to.be.greaterThan(largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be greaterThan " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ largeValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:greater than " ~ largeValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
      });

      it("should throw a detailed error when the negated coparison fails", {
        auto msg = ({
          expect(largeValue).not.to.be.greaterThan(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(largeValue.to!string ~ " should not be greaterThan " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than " ~ smallValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:less than or equal to " ~ smallValue.to!string);
        msg.split("\n")[3].strip.should.equal("Actual:" ~ largeValue.to!string);
      });
    });
  }
});
