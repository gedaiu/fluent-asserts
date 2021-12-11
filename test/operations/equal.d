module test.operations.equal;

import fluentasserts.core.serializers;
import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;
import std.datetime;

alias s = Spec!({

  alias StringTypes = AliasSeq!(string, wstring, dstring);

  static foreach(Type; StringTypes) {
    describe("using " ~ Type.stringof ~ " values", {
      Type testValue;
      Type otherTestValue;

      before({
        testValue = "test string".to!Type;
        otherTestValue = "test".to!Type;
      });

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
          expect(data.assumeUTF.to!Type).to.equal("some data");
        }).should.throwException!TestException.msg;

        msg.should.contain(`Actual:"some data\0\0"`);
        msg.should.contain(`some data[+\0\0]`);
      });
    });
  }

  alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real /*, ifloat, idouble, ireal, cfloat, cdouble, creal*/);

  static foreach(Type; NumericTypes) {
    describe("using " ~ Type.stringof ~ " values", {
      Type testValue;
      Type otherTestValue;

      static if(is(ifloat == Type) || is(idouble == Type) || is(ireal == Type)) {
        before({
          testValue = 40i;
          otherTestValue = 50i;
        });
      } else {
        before({
          testValue = cast(Type) 40;
          otherTestValue = cast(Type) 50;
        });
      }

      it("should be able to compare two exact values", {
        expect(testValue).to.equal(testValue);
      });

      it("should be able to check if two values are not equal", {
        expect(testValue).to.not.equal(otherTestValue);
      });

      it("should throw an exception with a detailed message when the strings are not equal", {
        auto msg = ({
          expect(testValue).to.equal(otherTestValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(testValue.to!string ~ ` should equal ` ~ otherTestValue.to!string ~ `. ` ~ testValue.to!string ~ ` is not equal to ` ~ otherTestValue.to!string ~ `.`);
      });

      it("should throw an exception with a detailed message when the strings should not be equal", {
        auto msg = ({
          expect(testValue).to.not.equal(testValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(testValue.to!string ~ ` should not equal ` ~ testValue.to!string ~ `. ` ~ testValue.to!string ~ ` is equal to ` ~ testValue.to!string ~ `.`);
      });
    });
  }

  describe("using booleans", {
    it("should compare two true values", {
      expect(true).to.equal(true);
    });

    it("should compare two false values", {
      expect(false).to.equal(false);
    });

    it("should be able to compare that two bools that are not equal", {
      expect(true).to.not.equal(false);
      expect(false).to.not.equal(true);
    });

    it("should throw a detailed error message when the two bools are not equal", {
      auto msg = ({
        expect(true).to.equal(false);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.equal("true should equal false.");
      msg[2].strip.should.equal("Expected:false");
      msg[3].strip.should.equal("Actual:true");
    });
  });

  describe("using durations", {
    it("should compare two true values", {
      expect(2.seconds).to.equal(2.seconds);
    });

    it("should be able to compare that two bools that are not equal", {
      expect(2.seconds).to.not.equal(3.seconds);
      expect(3.seconds).to.not.equal(2.seconds);
    });

    it("should throw a detailed error message when the two bools are not equal", {
      auto msg = ({
        expect(3.seconds).to.equal(2.seconds);
      }).should.throwException!TestException.msg.split("\n");

      msg[0].strip.should.equal("3 secs should equal 2 secs. 3000000000 is not equal to 2000000000.");
    });
  });

  describe("using objects without custom opEquals", {
    Object testValue;
    Object otherTestValue;
    string niceTestValue;
    string niceOtherTestValue;

    before({
      testValue = new Object();
      otherTestValue = new Object();

      niceTestValue = SerializerRegistry.instance.niceValue(testValue);
      niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);
    });

    it("should be able to compare two exact values", {
      expect(testValue).to.equal(testValue);
    });

    it("should be able to check if two values are not equal", {
      expect(testValue).to.not.equal(otherTestValue);
    });

    it("should throw an exception with a detailed message when the strings are not equal", {
      auto msg = ({
        expect(testValue).to.equal(otherTestValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should equal ` ~ niceOtherTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is not equal to ` ~ niceOtherTestValue.to!string ~ `.`);
    });

    it("should throw an exception with a detailed message when the strings should not be equal", {
      auto msg = ({
        expect(testValue).to.not.equal(testValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should not equal ` ~ niceTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is equal to ` ~ niceTestValue.to!string ~ `.`);
    });
  });

  describe("using objects with custom opEquals", {
    Thing testValue;
    Thing sameTestValue;
    Thing otherTestValue;

    string niceTestValue;
    string niceSameTestValue;
    string niceOtherTestValue;

    before({
      testValue = new Thing(1);
      sameTestValue = new Thing(1);
      otherTestValue = new Thing(2);

      niceTestValue = SerializerRegistry.instance.niceValue(testValue);
      niceSameTestValue = SerializerRegistry.instance.niceValue(sameTestValue);
      niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);
    });

    it("should be able to compare two exact values", {
      expect(testValue).to.equal(testValue);
    });


    it("should be able to compare two objects with the same fields", {
      expect(testValue).to.equal(sameTestValue);
      expect(testValue).to.equal(cast(Object) sameTestValue);
    });

    it("should be able to check if two values are not equal", {
      expect(testValue).to.not.equal(otherTestValue);
    });

    it("should throw an exception with a detailed message when the strings are not equal", {
      auto msg = ({
        expect(testValue).to.equal(otherTestValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should equal ` ~ niceOtherTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is not equal to ` ~ niceOtherTestValue.to!string ~ `.`);
    });

    it("should throw an exception with a detailed message when the strings should not be equal", {
      auto msg = ({
        expect(testValue).to.not.equal(testValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should not equal ` ~ niceTestValue.to!string ~ `. ` ~ niceTestValue.to!string ~ ` is equal to ` ~ niceTestValue.to!string ~ `.`);
    });
  });

  describe("using assoc arrays", {
    string[string] testValue;
    string[string] sameTestValue;
    string[string] otherTestValue;

    string niceTestValue;
    string niceSameTestValue;
    string niceOtherTestValue;

    before({
      testValue = ["b": "2", "a": "1", "c": "3"];
      sameTestValue = ["a": "1", "b": "2", "c": "3"];
      otherTestValue = ["a": "3", "b": "2", "c": "1"];

      niceTestValue = SerializerRegistry.instance.niceValue(testValue);
      niceSameTestValue = SerializerRegistry.instance.niceValue(sameTestValue);
      niceOtherTestValue = SerializerRegistry.instance.niceValue(otherTestValue);
    });

    it("should be able to compare two exact values", {
      expect(testValue).to.equal(testValue);
    });


    it("should be able to compare two objects with the same fields", {
      expect(testValue).to.equal(sameTestValue);
    });

    it("should be able to check if two values are not equal", {
      expect(testValue).to.not.equal(otherTestValue);
    });

    it("should throw an exception with a detailed message when the strings are not equal", {
      auto msg = ({
        expect(testValue).to.equal(otherTestValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should equal ` ~ niceOtherTestValue.to!string ~ `.`);
    });

    it("should throw an exception with a detailed message when the strings should not be equal", {
      auto msg = ({
        expect(testValue).to.not.equal(testValue);
      }).should.throwException!TestException.msg;

      msg.split("\n")[0].should.equal(niceTestValue.to!string ~ ` should not equal ` ~ niceTestValue.to!string ~ `.`);
    });
  });
});

version(unittest) :
class Thing {
	int x;
	this(int x) { this.x = x; }
	override bool opEquals(Object o) {
		if(typeid(this) != typeid(o)) return false;
		alias a = this;
		auto b = cast(typeof(this)) o;
		return a.x == b.x;
	}
}