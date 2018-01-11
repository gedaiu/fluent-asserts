import std.stdio;
import std.traits;
import std.string;

import fluent.asserts;

int main()
{
	pragma(msg, "base classes:", BaseTypeTuple!TestException);

	try {
		0.should.equal(1);
	} catch (TestException e) {
		e.msg.writeln;
		return e.msg.indexOf("should equal `1`.") != -1;
	}

	return 1;
}
