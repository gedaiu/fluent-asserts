module test.operations.contain;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;
import std.algorithm;
import std.range;

alias s = Spec!({
  alias StringTypes = AliasSeq!(string, wstring, dstring);

  static foreach(Type; StringTypes) {
    describe("using " ~ Type.stringof ~ " values", {
      Type testValue;

      Type[] listOfOtherValues;
      Type[] listOfValues;

      before({
        testValue = "test string".to!Type;
        listOfOtherValues = ["string".to!Type, "test".to!Type];
        listOfOtherValues = ["other".to!Type, "message".to!Type];
      });

      it("should find two substrings", {
        expect(testValue).to.contain(["string", "test"]);
      });

      it("should not find matches from a list of strings", {
        expect(testValue).to.not.contain(["other", "message"]);
      });

      it("should find a char", {
        expect(testValue).to.contain('s');
      });

      it("should not find a char that is not in the string", {
        expect(testValue).to.not.contain('z');
      });

      it("should show a detailed error message when the strings are not found", {
        auto msg = ({
          expect(testValue).to.contain(["other", "message"]);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should contain ["other", "message"]. ["other", "message"] are missing from "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to contain all [\"other\", \"message\"]");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });

      it("should throw an error when the string contains substrings that it should not", {
        auto msg = ({
          expect(testValue).to.not.contain(["test", "string"]);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should not contain ["test", "string"]. ["test", "string"] are present in "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to not contain any [\"test\", \"string\"]");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });

      it("should throw an error when the string does not contains a substring", {
        auto msg = ({
          expect(testValue).to.contain("other");
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should contain "other". other is missing from "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to contain \"other\"");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });

      it("should throw an error when the string contains a substring that it should not", {
        auto msg = ({
          expect(testValue).to.not.contain("test");
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should not contain "test". test is present in "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to not contain \"test\"");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });

      it("should throw an error when the string does not contains a char", {
        auto msg = ({
          expect(testValue).to.contain('o');
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should contain 'o'. o is missing from "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to contain 'o'");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });

      it("should throw an error when the string contains a char that it should not", {
        auto msg = ({
          expect(testValue).to.not.contain('t');
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should not contain 't'. t is present in "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to not contain 't'");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });
    });

    describe("using a range of " ~ Type.stringof ~ " values", {
      Type testValue;

      Type[] listOfOtherValues;
      Type[] listOfValues;

      before({
        testValue = "test string".to!Type;
      });

      it("should find two substrings", {
        expect(testValue).to.contain(["string", "test"].inputRangeObject);
      });

      it("should not find matches from a list of strings", {
        expect(testValue).to.not.contain(["other", "message"].inputRangeObject);
      });

      it("should show a detailed error message when the strings are not found", {
        auto msg = ({
          expect(testValue).to.contain(["other", "message"].inputRangeObject);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should contain ["other", "message"]. ["other", "message"] are missing from "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to contain all [\"other\", \"message\"]");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });

      it("should throw an error when the string contains substrings that it should not", {
        auto msg = ({
          expect(testValue).to.not.contain(["test", "string"].inputRangeObject);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(`"test string" should not contain ["test", "string"]. ["test", "string"] are present in "test string".`);
        msg.split("\n")[2].strip.should.equal("Expected:to not contain any [\"test\", \"string\"]");
        msg.split("\n")[3].strip.should.equal("Actual:test string");
      });
    });
  }
});
