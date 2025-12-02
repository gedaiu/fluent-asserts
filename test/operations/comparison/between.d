module test.operations.comparison.between;

import fluentasserts.core.expect;
import fluent.asserts;

import std.string;
import std.conv;
import std.meta;
import std.datetime;

alias NumericTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real);

static foreach (Type; NumericTypes) {
    @(Type.stringof ~ " value is inside an interval")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        Type middleValue = cast(Type) 45;
        expect(middleValue).to.be.between(smallValue, largeValue);
        expect(middleValue).to.be.between(largeValue, smallValue);
        expect(middleValue).to.be.within(smallValue, largeValue);
    }

    @(Type.stringof ~ " value is outside an interval")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        expect(largeValue).to.not.be.between(smallValue, largeValue);
        expect(largeValue).to.not.be.between(largeValue, smallValue);
        expect(largeValue).to.not.be.within(smallValue, largeValue);
    }

    @(Type.stringof ~ " throws error when value equals max of interval")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        auto msg = ({
            expect(largeValue).to.be.between(smallValue, largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
        msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
    }

    @(Type.stringof ~ " throws error when value equals min of interval")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        auto msg = ({
            expect(smallValue).to.be.between(smallValue, largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
        msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
    }

    @(Type.stringof ~ " throws error when negated assert fails")
    unittest {
        Type smallValue = cast(Type) 40;
        Type largeValue = cast(Type) 50;
        Type middleValue = cast(Type) 45;
        auto msg = ({
            expect(middleValue).to.not.be.between(smallValue, largeValue);
        }).should.throwException!TestException.msg;

        msg.split("\n")[0].should.startWith(middleValue.to!string ~ " should not be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ".");
        msg.split("\n")[1].strip.should.equal("Expected:a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
        msg.split("\n")[2].strip.should.equal("Actual:" ~ middleValue.to!string);
    }
}

@("Duration value is inside an interval")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 50.seconds;
    Duration middleValue = 45.seconds;
    expect(middleValue).to.be.between(smallValue, largeValue);
    expect(middleValue).to.be.between(largeValue, smallValue);
    expect(middleValue).to.be.within(smallValue, largeValue);
}

@("Duration value is outside an interval")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 50.seconds;
    expect(largeValue).to.not.be.between(smallValue, largeValue);
    expect(largeValue).to.not.be.between(largeValue, smallValue);
    expect(largeValue).to.not.be.within(smallValue, largeValue);
}

@("Duration throws error when value equals max of interval")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 50.seconds;
    auto msg = ({
        expect(largeValue).to.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(largeValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ largeValue.to!string ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    msg.split("\n")[2].strip.should.equal("Actual:" ~ largeValue.to!string);
}

@("Duration throws error when value equals min of interval")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 50.seconds;
    auto msg = ({
        expect(smallValue).to.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.to!string ~ " should be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ". " ~ smallValue.to!string ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:a value inside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    msg.split("\n")[2].strip.should.equal("Actual:" ~ smallValue.to!string);
}

@("Duration throws error when negated assert fails")
unittest {
    Duration smallValue = 40.seconds;
    Duration largeValue = 50.seconds;
    Duration middleValue = 45.seconds;
    auto msg = ({
        expect(middleValue).to.not.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.startWith(middleValue.to!string ~ " should not be between " ~ smallValue.to!string ~ " and " ~ largeValue.to!string ~ ".");
    msg.split("\n")[1].strip.should.equal("Expected:a value outside (" ~ smallValue.to!string ~ ", " ~ largeValue.to!string ~ ") interval");
    msg.split("\n")[2].strip.should.equal("Actual:" ~ middleValue.to!string);
}

@("SysTime value is inside an interval")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = Clock.currTime + 40.seconds;
    SysTime middleValue = Clock.currTime + 35.seconds;
    expect(middleValue).to.be.between(smallValue, largeValue);
    expect(middleValue).to.be.between(largeValue, smallValue);
    expect(middleValue).to.be.within(smallValue, largeValue);
}

@("SysTime value is outside an interval")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = Clock.currTime + 40.seconds;
    expect(largeValue).to.not.be.between(smallValue, largeValue);
    expect(largeValue).to.not.be.between(largeValue, smallValue);
    expect(largeValue).to.not.be.within(smallValue, largeValue);
}

@("SysTime throws error when value equals max of interval")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = Clock.currTime + 40.seconds;
    auto msg = ({
        expect(largeValue).to.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(largeValue.toISOExtString ~ " should be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ". " ~ largeValue.toISOExtString ~ " is greater than or equal to " ~ largeValue.to!string ~ ".");
}

@("SysTime throws error when value equals min of interval")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = Clock.currTime + 40.seconds;
    auto msg = ({
        expect(smallValue).to.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.equal(smallValue.toISOExtString ~ " should be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ". " ~ smallValue.toISOExtString ~ " is less than or equal to " ~ smallValue.to!string ~ ".");
}

@("SysTime throws error when negated assert fails")
unittest {
    SysTime smallValue = Clock.currTime;
    SysTime largeValue = Clock.currTime + 40.seconds;
    SysTime middleValue = Clock.currTime + 35.seconds;
    auto msg = ({
        expect(middleValue).to.not.be.between(smallValue, largeValue);
    }).should.throwException!TestException.msg;

    msg.split("\n")[0].should.startWith(middleValue.toISOExtString ~ " should not be between " ~ smallValue.toISOExtString ~ " and " ~ largeValue.toISOExtString ~ ".");
}
