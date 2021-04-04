module test.operations.between;

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
      Type middleValue;

      before({
        smallValue = cast(Type) 40;
        largeValue = cast(Type) 50;
        middleValue = cast(Type) 45;
      });

      it("should be able to check if a value is inside an interval", {
        expect(middleValue).to.be.between(smallValue, largeValue);
        expect(middleValue).to.be.between(largeValue, smallValue);
        expect(middleValue).to.be.within(smallValue, largeValue);
      });

      it("should be able to check if a value is outside an interval", {
        expect(largeValue).to.not.be.between(smallValue, largeValue);
        expect(largeValue).to.not.be.between(largeValue, smallValue);
        expect(largeValue).to.not.be.within(smallValue, largeValue);
      });

      it("should throw a detailed error when the value equal to the max value of the interval", {
        auto msg = ({
          expect(largeValue).to.be.between(smallValue, largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
        msg.split("\n")[3].strip.should.equal("Actual:" ~ largeValue.to!string);
      });

      it("should throw a detailed error when the value equal to the min value of the interval", {
        auto msg = ({
          expect(smallValue).to.be.between(smallValue, largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
        msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
      });

      it("should throw a detailed error when the negated assert fails", {
        auto msg = ({
          expect(middleValue).to.not.be.between(smallValue, largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.startWith(middleValue.to!string ~ " should not be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ".");
        msg.split("\n")[2].strip.should.equal("Expected:a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
        msg.split("\n")[3].strip.should.equal("Actual:" ~ middleValue.to!string);
      });
    });
  }

  describe("using Duration values", {
    Duration smallValue;
    Duration largeValue;
    Duration middleValue;

    before({
      smallValue = 40.seconds;
      largeValue = 50.seconds;
      middleValue = 45.seconds;
    });

    it("should be able to check if a value is inside an interval", {
      expect(middleValue).to.be.between(smallValue, largeValue);
      expect(middleValue).to.be.between(largeValue, smallValue);
      expect(middleValue).to.be.within(smallValue, largeValue);
    });

    it("should be able to check if a value is outside an interval", {
      expect(largeValue).to.not.be.between(smallValue, largeValue);
      expect(largeValue).to.not.be.between(largeValue, smallValue);
      expect(largeValue).to.not.be.within(smallValue, largeValue);
    });

    it("should throw a detailed error when the value equal to the max value of the interval", {
      auto msg = ({
        expect(largeValue).to.be.between(smallValue, largeValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
      msg.split("\n")[2].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
      msg.split("\n")[3].strip.should.equal("Actual:" ~ largeValue.to!string);
    });

    it("should throw a detailed error when the value equal to the min value of the interval", {
      auto msg = ({
        expect(smallValue).to.be.between(smallValue, largeValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
      msg.split("\n")[2].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
      msg.split("\n")[3].strip.should.equal("Actual:" ~ smallValue.to!string);
    });

    it("should throw a detailed error when the negated assert fails", {
      auto msg = ({
        expect(middleValue).to.not.be.between(smallValue, largeValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.startWith(middleValue.to!string ~ " should not be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ".");
      msg.split("\n")[2].strip.should.equal("Expected:a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
      msg.split("\n")[3].strip.should.equal("Actual:" ~ middleValue.to!string);
    });
  });

  describe("using SysTime values", {
    SysTime smallValue;
    SysTime largeValue;
    SysTime middleValue;

    before({
      smallValue = Clock.currTime;
      largeValue = Clock.currTime + 40.seconds;
      middleValue = Clock.currTime + 35.seconds;
    });

    it("should be able to check if a value is inside an interval", {
      expect(middleValue).to.be.between(smallValue, largeValue);
      expect(middleValue).to.be.between(largeValue, smallValue);
      expect(middleValue).to.be.within(smallValue, largeValue);
    });

    it("should be able to check if a value is outside an interval", {
      expect(largeValue).to.not.be.between(smallValue, largeValue);
      expect(largeValue).to.not.be.between(largeValue, smallValue);
      expect(largeValue).to.not.be.within(smallValue, largeValue);
    });

    it("should throw a detailed error when the value equal to the max value of the interval", {
      auto msg = ({
        expect(largeValue).to.be.between(smallValue, largeValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(largeValue.toISOExtString ~ " should be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ". " ~ largeValue.toISOExtString ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
    });

    it("should throw a detailed error when the value equal to the min value of the interval", {
      auto msg = ({
        expect(smallValue).to.be.between(smallValue, largeValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(smallValue.toISOExtString ~ " should be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ". " ~ smallValue.toISOExtString ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
    });

    it("should throw a detailed error when the negated assert fails", {
      auto msg = ({
        expect(middleValue).to.not.be.between(smallValue, largeValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.startWith(middleValue.toISOExtString ~ " should not be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ".");
    });
  });
});
