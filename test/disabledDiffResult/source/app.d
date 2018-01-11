import std.stdio;
import std.traits;
import std.string;

import fluent.asserts;

int main()
{
	pragma(msg, "base classes:", BaseTypeTuple!TestException);

	try {
		"a".should.equal("b");
	} catch (TestException e) {
		e.msg.writeln;
		return e.msg.indexOf("Diff:") == -1;
	}

	return 1;
}
