module test.operations.comparison.approximately;

import fluentasserts.core.expect;
import fluent.asserts;

import std.string;
import std.conv;
import std.meta;
import std.algorithm;
import std.range;

alias IntTypes = AliasSeq!(byte, ubyte, short, ushort, int, uint, long, ulong);
alias FPTypes = AliasSeq!(float, double, real);

static foreach (Type; FPTypes) {
    @("floats casted to " ~ Type.stringof ~ " checks valid values")
    unittest {
        Type testValue = cast(Type) 10f / 3f;
        testValue.should.be.approximately(3, 0.34);
        [testValue].should.be.approximately([3], 0.34);
    }

    @("floats casted to " ~ Type.stringof ~ " checks invalid values")
    unittest {
        Type testValue = cast(Type) 10f / 3f;
        testValue.should.not.be.approximately(3, 0.24);
        [testValue].should.not.be.approximately([3], 0.24);
    }

    @("floats casted to " ~ Type.stringof ~ " does not compare a string with a number")
    unittest {
        auto msg = ({
            "".should.be.approximately(3, 0.34);
        }).should.throwSomething.msg;

        msg.split("\n")[0].should.equal("There are ... no matching assert operations. Register any of `string.int.approximately`, `*.*.approximately` to perform this assert.");
    }

    @(Type.stringof ~ " values approximately compares two numbers")
    unittest {
        Type testValue = cast(Type) 0.351;
        expect(testValue).to.be.approximately(0.35, 0.01);
    }

    @(Type.stringof ~ " values checks approximately with delta 0.00001")
    unittest {
        Type testValue = cast(Type) 0.351;
        expect(testValue).to.not.be.approximately(0.35, 0.00001);
    }

    @(Type.stringof ~ " values checks approximately with delta 0.001")
    unittest {
        Type testValue = cast(Type) 0.351;
        expect(testValue).to.not.be.approximately(0.35, 0.001);
    }

    @(Type.stringof ~ " values shows detailed error when values are not approximately equal")
    unittest {
        Type testValue = cast(Type) 0.351;
        auto msg = ({
            expect(testValue).to.be.approximately(0.35, 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:0.35±0.0001");
        msg.should.contain("Actual:0.351");
        msg.should.not.contain("Missing:");
    }

    @(Type.stringof ~ " values shows detailed error when values are approximately equal but should not be")
    unittest {
        Type testValue = cast(Type) 0.351;
        auto msg = ({
            expect(testValue).to.not.be.approximately(testValue, 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:not " ~ testValue.to!string ~ "±0.0001");
    }

    @(Type.stringof ~ " lists approximately compares two lists")
    unittest {
        Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
        expect(testValues).to.be.approximately([0.35, 0.50, 0.34], 0.01);
    }

    @(Type.stringof ~ " lists with range 0.00001 compares two lists that are not equal")
    unittest {
        Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
        expect(testValues).to.not.be.approximately([0.35, 0.50, 0.34], 0.00001);
    }

    @(Type.stringof ~ " lists with range 0.0001 compares two lists that are not equal")
    unittest {
        Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
        expect(testValues).to.not.be.approximately([0.35, 0.50, 0.34], 0.0001);
    }

    @(Type.stringof ~ " lists with range 0.001 compares two lists with different lengths")
    unittest {
        Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
        expect(testValues).to.not.be.approximately([0.35, 0.50], 0.001);
    }

    @(Type.stringof ~ " lists shows detailed error when lists are not approximately equal")
    unittest {
        Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
        auto msg = ({
            expect(testValues).to.be.approximately([0.35, 0.50, 0.34], 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:[0.35±0.0001, 0.5±0.0001, 0.34±0.0001]");
        msg.should.contain("Missing:[0.501±0.0001, 0.341±0.0001]");
    }

    @(Type.stringof ~ " lists shows detailed error when lists are approximately equal but should not be")
    unittest {
        Type[] testValues = [cast(Type) 0.350, cast(Type) 0.501, cast(Type) 0.341];
        auto msg = ({
            expect(testValues).to.not.be.approximately(testValues, 0.0001);
        }).should.throwException!TestException.msg;

        msg.should.contain("Expected:not [0.35±0.0001, 0.501±0.0001, 0.341±0.0001]");
    }
}
