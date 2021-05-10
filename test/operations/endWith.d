module test.operations.endWith;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;

alias s = Spec!({
  describe("special cases", {
    it("should check that a multi line string ends with a certain substring", {
      expect("str\ning").to.endWith("ing");
    });
  });

  alias StringTypes = AliasSeq!(string, wstring, dstring);

  static foreach(Type; StringTypes) {
    describe("using " ~ Type.stringof ~ " values", {
      Type testValue;

      before({
        testValue = "test string".to!Type;
      });

      it("should check that a string ends with a certain substring", {
        expect(testValue).to.endWith("string");
      });

      it("should check that a string ends with a certain char", {
        expect(testValue).to.endWith('g');
      });

      it("should check that a string does not end with a certain substring", {
        expect(testValue).to.not.endWith("other");
      });

      it("should check that a string does not end with a certain char", {
        expect(testValue).to.not.endWith('o');
      });

      it("should throw a detailed error when the string does not end with the substring what was expected", {
        auto msg = ({
          expect(testValue).to.endWith("other");
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should end with "other". "test string" does not end with "other".`);
        msg.split("\n")[2].strip.should.equal(`Expected:to end with "other"`);
        msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);
      });

      it("should throw a detailed error when the string does not end with the char what was expected", {
        auto msg = ({
          expect(testValue).to.endWith('o');
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should end with 'o'. "test string" does not end with 'o'.`);
        msg.split("\n")[2].strip.should.equal(`Expected:to end with 'o'`);
        msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);
      });

      it("should throw a detailed error when the string does end with the unexpected substring", {
        auto msg = ({
          expect(testValue).to.not.endWith("string");
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should not end with "string". "test string" ends with "string".`);
        msg.split("\n")[2].strip.should.equal(`Expected:to not end with "string"`);
        msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);
      });

      it("should throw a detailed error when the string does end with the unexpected char", {
        auto msg = ({
          expect(testValue).to.not.endWith('g');
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should not end with 'g'. "test string" ends with 'g'.`);
        msg.split("\n")[2].strip.should.equal(`Expected:to not end with 'g'`);
        msg.split("\n")[3].strip.should.equal(`Actual:"test string"`);
      });
    });
  }
});
