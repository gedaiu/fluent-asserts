import std.stdio;
import std.traits;

import fluent.asserts;
import unit_threaded.should : UnitTestException;

int main()
{
	pragma(msg, "base classes:", BaseTypeTuple!TestException);

	try {
		0.should.equal(1);
	} catch (UnitTestException e) {
		writeln("Got the right exception");
		return 0;
	} catch(Throwable t) {
		t.writeln;
	}

	return 1;
}
