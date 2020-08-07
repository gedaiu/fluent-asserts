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
    describe("using " ~ Type.stringof, {
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
        expect(testValues).to.not.be.approximately([0.35, 0.50, 0.34], 0.001);
      });

      it("should approximately with a range of 0.001 compare two lists with different lengths", {
        expect(testValues).to.not.be.approximately([0.35, 0.50], 0.001);
      });

      it("should show a detailed error message when two lists should be approximatly equal but they are not", {
        auto msg = ({
          expect(testValues).to.be.approximately([0.35, 0.50, 0.34], 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
        msg.should.contain("Missing:[0.501±0.0001, 0.341±0.0001]");
      });

      it("should show a detailed error message when two lists are approximatly equal but they should not", {
        auto msg = ({
          expect(testValues).to.not.be.approximately(testValues, 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:not [0.35±0.0001, 0.501±0.0001, 0.341±0.0001]");
      });
    });
  }
});
