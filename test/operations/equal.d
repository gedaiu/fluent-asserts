module test.operations.equal;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;

alias s = Spec!({
  describe("the equal operation", {
    it("should be able to compare two exact strings", {
      expect("test string").to.equal("test string");
    });

    it("should be able to check if two strings are not equal", {
      expect("test string").to.not.equal("test");
    });

    it("should throw an exception with a detailed message when the strings are not equal", {
      auto msg = ({
        expect("test string").to.equal("test");
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(`"test string" should equal "test". "test string" is not equal to "test".`);
    });

    it("should throw an exception with a detailed message when the strings should not be equal", {
      auto msg = ({
        expect("test string").to.not.equal("test string");
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(`"test string" should not equal "test string". "test string" is equal to "test string".`);
    });

    it("should show the null chars in the detailed message", {
      auto msg = ({
        ubyte[] data = [115, 111, 109, 101, 32, 100, 97, 116, 97, 0, 0];
        expect(data.assumeUTF.to!string).to.equal("some data");
      }).should.throwException!TestException.msg;

      msg.should.contain(`Actual:"some data\0\0"`);
      msg.should.contain(`some data[+\0\0]`);
    });
  });
});
