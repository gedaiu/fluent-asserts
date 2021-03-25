module test.operations.approximately;


import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;
import std.algorithm;
import std.range;

alias s = Spec!({
  alias IntTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong);

  alias FPTypes = AliasSeq!(float, double, real);

  static foreach(Type; FPTypes) {
    describe("using floats casted to " ~ Type.stringof, {
      Type testValue;

      before({
        testValue = cast(Type) 10f/3f;
      });

      it("should check for valid values", {
        testValue.should.be.approximately(3, 0.34);
        [testValue].should.be.approximately([3], 0.34);
      });

      it("should check for invalid values", {
        testValue.should.not.be.approximately(3, 0.24);
        [testValue].should.not.be.approximately([3], 0.24);
      });

      it("should not compare a string with a ", {
        auto msg = ({
          "".should.be.approximately(3, 0.34);
        }).should.throwSomething.msg;

        msg.split("\n")[0].should.equal("There is no `string.int.approximately` or `*.*.approximately` registered to the assert operations.");
      });
    });

    describe("using " ~ Type.stringof ~ " values", {
      Type testValue;

      before({
        testValue = cast(Type) 0.351;
      });

      it("should check approximately compare two numbers", {
        expect(testValue).to.be.approximately(0.35, 0.01);
      });

      it("should check approximately with a delta of 0.00001", {
        expect(testValue).to.not.be.approximately(0.35, 0.00001);
      });

      it("should check approximately with a delta of 0.001", {
        expect(testValue).to.not.be.approximately(0.35, 0.001);
      });

      it("should show a detailed error message when two numbers should be approximately equal but they are not", {
        auto msg = ({
          expect(testValue).to.be.approximately(0.35, 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:0.35±0.0001");
        msg.should.contain("Actual:0.351");
        msg.should.not.contain("Missing:");
      });

      it("should show a detailed error message when two numbers are approximately equal but they should not", {
        auto msg = ({
          expect(testValue).to.not.be.approximately(testValue, 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:not " ~ testValue.to!string ~ "±0.0001");
      });
    });

    describe("using " ~ Type.stringof ~ " lists", {
      Type[] testValues;

      before({
        testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
      });

      it("should approximately compare two lists", {
        expect(testValues).to.be.approximately([0.35, 0.50, 0.34], 0.01);
      });

      it("should approximately with a range of 0.00001 compare two lists that are not equal", {
        expect(testValues).to.not.be.approximately([0.35, 0.50, 0.34], 0.00001);
      });

      it("should approximately with a range of 0.001 compare two lists that are not equal", {
        expect(testValues).to.not.be.approximately([0.35, 0.50, 0.34], 0.0001);
      });

      it("should approximately with a range of 0.001 compare two lists with different lengths", {
        expect(testValues).to.not.be.approximately([0.35, 0.50], 0.001);
      });

      it("should show a detailed error message when two lists should be approximately equal but they are not", {
        auto msg = ({
          expect(testValues).to.be.approximately([0.35, 0.50, 0.34], 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
        msg.should.contain("Missing:[0.501±0.0001, 0.341±0.0001]");
      });

      it("should show a detailed error message when two lists are approximately equal but they should not", {
        auto msg = ({
          expect(testValues).to.not.be.approximately(testValues, 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:not [0.35±0.0001, 0.501±0.0001, 0.341±0.0001]");
      });
    });
  }
});
