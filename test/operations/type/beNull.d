module test.operations.type.beNull;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;

alias s = Spec!({
  describe("using delegates", {
    void delegate() value;
    describe("when the delegate is set", {
      beforeEach({
        void test() {}
        value = &test;
      });

      it("should not throw when it is expected not to be null", {
        expect(value).not.to.beNull;
      });

      it("should throw when it is expected to be null", {
        auto msg = expect({
          expect(value).to.beNull;
        }).to.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(" should be null.");
        msg.split("\n")[1].strip.should.equal("Expected:null");
        msg.split("\n")[2].strip.should.equal("Actual:callable");
      });
    });

    describe("when the delegate is not set", {
      beforeEach({
        value = null;
      });

      it("should not throw when it is expected to be null", {
        expect(value).to.beNull;
      });

      it("should throw when it is expected not to be null", {
        auto msg = expect({
          expect(value).not.to.beNull;
        }).to.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(" should not be null.");
        msg.split("\n")[1].strip.should.equal("Expected:not null");
        msg.split("\n")[2].strip.should.equal("Actual:null");
      });
    });
  });
});
