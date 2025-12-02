module test.operations.comparison.greaterOrEqualTo;

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
        expect(largeValue).to.be.greaterOrEqualTo(smallValue);
        expect(largeValue).to.be.greaterOrEqualTo(largeValue);
    }

    @(Type.stringof ~ " compares two values using negation")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        expect(smallValue).not.to.be.greaterOrEqualTo(largeValue);
    }

    @(Type.stringof ~ " throws error when comparison fails")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        auto msg = ({
            expect(smallValue).to.be.greaterOrEqualTo(largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be greater or equal to " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than " ~ largeValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:greater or equal than " ~ largeValue.to!string);
        msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
    }

    @(Type.stringof ~ " throws error when negated comparison fails")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        auto msg = ({
            expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(largeValue.to!string ~ " should not be greater or equal to " ~ smallValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater or equal than " ~ smallValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:less than " ~ smallValue.to!string);
        msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
    }
}

@("Duration compares two values")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 41.seconds;
    expect(largeValue).to.be.greaterOrEqualTo(smallValue);
}

@("Duration compares two values using negation")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 41.seconds;
    expect(smallValue).not.to.be.greaterOrEqualTo(largeValue);
}

@("Duration does not throw when compared with itself")
unittest {
    Duration smallValue = 40.seconds;
    expect(smallValue).to.be.greaterOrEqualTo(smallValue);
}

@("Duration throws error when negated comparison fails")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 41.seconds;
    auto msg = ({
        expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(largeValue.to!string ~ " should not be greater or equal to " ~ smallValue.to!string ~ ". " ~
        largeValue.to!string ~ " is greater or equal than " ~ smallValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:less than " ~ smallValue.to!string);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
}

@("SysTime compares two values")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = smallValue + 4.seconds;
    expect(largeValue).to.be.greaterOrEqualTo(smallValue);
    expect(largeValue).to.be.above(smallValue);
}

@("SysTime compares two values using negation")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = smallValue + 4.seconds;
    expect(smallValue).not.to.be.greaterOrEqualTo(largeValue);
    expect(smallValue).not.to.be.above(largeValue);
}

@("SysTime does not throw when compared with itself")
unittest {
    SysTime smallValue = Clock.currTime;
    expect(smallValue).to.be.greaterOrEqualTo(smallValue);
}

@("SysTime throws error when negated comparison fails")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = smallValue + 4.seconds;
    auto msg = ({
        expect(largeValue).not.to.be.greaterOrEqualTo(smallValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(largeValue.toISOExtString ~ " should not be greater or equal to " ~ smallValue.toISOExtString ~ ". " ~
        largeValue.toISOExtString ~ " is greater or equal than " ~ smallValue.toISOExtString ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:less than " ~ smallValue.toISOExtString);
    msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.toISOExtString);
}
