module test.operations.comparison.lessOrEqualTo;

import fluentasserts.core.expect;
import fluent.asserts;

import std.string;
import std.conv;
import std.meta;
import std.datetime;

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
    @(Type.stringof ~ " compares two values")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        expect(smallValue).to.be.lessOrEqualTo(largeValue);
        expect(smallValue).to.be.lessOrEqualTo(smallValue);
    }

    @(Type.stringof ~ " compares two values using negation")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        expect(largeValue).not.to.be.lessOrEqualTo(smallValue);
    }

    @(Type.stringof ~ " throws error when comparison fails")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        auto msg = ({
            expect(largeValue).to.be.lessOrEqualTo(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be less or equal to " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than " ~ smallValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:less or equal to " ~ smallValue.to!string);
        msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
    }

    @(Type.stringof ~ " throws error when negated comparison fails")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        auto msg = ({
            expect(smallValue).not.to.be.lessOrEqualTo(largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should not be less or equal to " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less or equal to " ~ largeValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:greater than " ~ largeValue.to!string);
        msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
    }
}
