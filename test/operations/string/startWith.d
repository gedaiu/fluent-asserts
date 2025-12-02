module test.operations.string.startWith;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;

alias s = Spec!({

  alias StringTypes = AliasSeq!(string, wstring, dstring);

  static foreach(Type; StringTypes) {
    describe("using " ~ Type.stringof ~ " values", {
      Type testValue;

      before({
        testValue = "test string".to!Type;
      });

      it("should check that a string starts with a certain substring", {
        expect(testValue).to.startWith("test");
      });

      it("should check that a string starts with a certain char", {
        expect(testValue).to.startWith('t');
      });

      it("should check that a string does not start with a certain substring", {
        expect(testValue).to.not.startWith("other");
      });

      it("should check that a string does not start with a certain char", {
        expect(testValue).to.not.startWith('o');
      });

      it("should throw a detailed error when the string does not start with the substring what was expected", {
        auto msg = ({
          expect(testValue).to.startWith("other");
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should start with "other". "test string" does not start with "other".`);
        msg.split("\n")[1].strip.should.equal(`Expected:to start with "other"`);
        msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
      });

      it("should throw a detailed error when the string does not start with the char what was expected", {
        auto msg = ({
          expect(testValue).to.startWith('o');
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should start with 'o'. "test string" does not start with 'o'.`);
        msg.split("\n")[1].strip.should.equal(`Expected:to start with 'o'`);
        msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
      });

      it("should throw a detailed error when the string does start with the unexpected substring", {
        auto msg = ({
          expect(testValue).to.not.startWith("test");
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should not start with "test". "test string" starts with "test".`);
        msg.split("\n")[1].strip.should.equal(`Expected:to not start with "test"`);
        msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
      });

      it("should throw a detailed error when the string does start with the unexpected char", {
        auto msg = ({
          expect(testValue).to.not.startWith('t');
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.contain(`"test string" should not start with 't'. "test string" starts with 't'.`);
        msg.split("\n")[1].strip.should.equal(`Expected:to not start with 't'`);
        msg.split("\n")[2].strip.should.equal(`Actual:"test string"`);
      });
    });
  }
});
