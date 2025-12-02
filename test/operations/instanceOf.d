module test.operations.instanceOf;

import fluentasserts.core.expect;
import fluent.asserts;

import trial.discovery.spec;

import std.string;
import std.conv;
import std.meta;

alias s = Spec!({
  alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);


  it("should not throw when comparing an object", {
    auto value = new Object();

    expect(value).to.be.instanceOf!Object;
    expect(value).to.not.be.instanceOf!string;
  });

  it("should not throw when comparing an Exception with an Object", {
    auto value = new Exception("some test");

    expect(value).to.be.instanceOf!Exception;
    expect(value).to.be.instanceOf!Object;
    expect(value).to.not.be.instanceOf!string;
  });

  static foreach(Type; NumericTypes) {
    describe("using " ~ Type.stringof ~ " values", {
      Type value;

      before({
        value = cast(Type) 40;
      });

      it("should be able to compare two types", {
        expect(value).to.be.instanceOf!Type;
        expect(value).to.not.be.instanceOf!string;
      });

      it("should throw a detailed error when the types do not match", {
        auto msg = ({
          expect(value).to.be.instanceOf!string;
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(value.to!string ~ ` should be instance of "string". ` ~ value.to!string ~ " is instance of " ~ Type.stringof ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:typeof string");
        msg.split("\n")[2].strip.should.equal("Actual:typeof " ~ Type.stringof);
      });

      it("should throw a detailed error when the types match and they should not", {
        auto msg = ({
          expect(value).to.not.be.instanceOf!Type;
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(value.to!string ~ ` should not be instance of "` ~ Type.stringof ~ `". ` ~ value.to!string ~ " is instance of " ~ Type.stringof ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:not typeof " ~ Type.stringof);
        msg.split("\n")[2].strip.should.equal("Actual:typeof " ~ Type.stringof);
      });
    });
  }
});
