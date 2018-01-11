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
		auto pos = e.msg.indexOf("source/app.d");
		e.msg.writeln;
		return pos != -1;
	}

	return 1;
}
