/+dub.sdl:
dependency "fluent-asserts" version= "~>0.13.3"
+/

import std.stdio;
import fluent.asserts;

void f2() {
  int k = 3;
  Assert.equal(k, 4);
}

void f1() {
  int j = 2;
  f2();
}

void f0() {
  int i = 1;
  f1();
}

void main() {
  f0();
}