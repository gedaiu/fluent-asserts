module test.operations.comparison.lessThan;

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
        expect(smallValue).to.be.lessThan(largeValue);
        expect(smallValue).to.be.below(largeValue);
    }

    @(Type.stringof ~ " compares two values using negation")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        expect(largeValue).not.to.be.lessThan(smallValue);
        expect(largeValue).not.to.be.below(smallValue);
    }

    @(Type.stringof ~ " throws error when compared with itself")
    unittest {
        Type smallValue = cast(Type) 40;
        auto msg = ({
            expect(smallValue).to.be.lessThan(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be less than " ~ smallValue.to!string ~ ". " ~ smallValue.to!string ~ " is greater than or equal to " ~ smallValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:less than " ~ smallValue.to!string);
        msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
    }

    @(Type.stringof ~ " throws error when negated comparison fails")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        auto msg = ({
            expect(smallValue).not.to.be.lessThan(largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should not be less than " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than " ~ largeValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:greater than or equal to " ~ largeValue.to!string);
        msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
    }
}

@("Duration compares two values")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 41.seconds;
    expect(smallValue).to.be.lessThan(largeValue);
    expect(smallValue).to.be.below(largeValue);
}

@("Duration compares two values using negation")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 41.seconds;
    expect(largeValue).not.to.be.lessThan(smallValue);
    expect(largeValue).not.to.be.below(smallValue);
}

@("Duration throws error when compared with itself")
unittest {
    Duration smallValue = 40.seconds;
    auto msg = ({
        expect(smallValue).to.be.lessThan(smallValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be less than " ~ smallValue.to!string ~ ". " ~ smallValue.to!string ~ " is greater than or equal to " ~ smallValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:less than " ~ smallValue.to!string);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
}

@("Duration throws error when negated comparison fails")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 41.seconds;
    auto msg = ({
        expect(smallValue).not.to.be.lessThan(largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.to!string ~ " should not be less than " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than " ~ largeValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:greater than or equal to " ~ largeValue.to!string);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
}

@("SysTime compares two values")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = smallValue + 4.seconds;
    expect(smallValue).to.be.lessThan(largeValue);
    expect(smallValue).to.be.below(largeValue);
}

@("SysTime compares two values using negation")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = smallValue + 4.seconds;
    expect(largeValue).not.to.be.lessThan(smallValue);
    expect(largeValue).not.to.be.below(smallValue);
}

@("SysTime throws error when compared with itself")
unittest {
    SysTime smallValue = Clock.currTime;
    auto msg = ({
        expect(smallValue).to.be.lessThan(smallValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.toISOExtString ~ " should be less than " ~ smallValue.toISOExtString ~ ". " ~ smallValue.toISOExtString ~ " is greater than or equal to " ~ smallValue.toISOExtString ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:less than " ~ smallValue.toISOExtString);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.toISOExtString);
}

@("SysTime throws error when negated comparison fails")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = smallValue + 4.seconds;
    auto msg = ({
        expect(smallValue).not.to.be.lessThan(largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.toISOExtString ~ " should not be less than " ~ largeValue.toISOExtString ~ ". " ~ smallValue.toISOExtString ~ " is less than " ~ largeValue.toISOExtString ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:greater than or equal to " ~ largeValue.toISOExtString);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.toISOExtString);
}
