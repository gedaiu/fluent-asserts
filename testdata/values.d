unittest {
  [1, 2, 3]
    .should
    .contain(4);
}

unittest {
  auto a = 1;

  [1, 2, 3]
    .should
    .contain(4);
}

unittest {
  /**/

  [1, 2, 3]
    .should
    .contain(4);
}

unittest {
  /++/

  [1, 2, 3]
    .should
    .contain(4);
}

unittest {
  //some comment

  [1, 2, 3]
    .should
    .contain(4);
}


unittest {
  /*
  Multi line comment
  */

  `multi
  line
  string`
    .should
    .contain(`multi
  line
  string`);
}

unittest {
  Assert.equal(5, 6);
  Assert.notEqual((5+1), 5);
  Assert.equal((5, (11)));
}

unittest {
  5.should.equal(6);
  (5+1).should.equal(5);
  (5, (11)).should.equal(3);
}

unittest {
  foreach(value; array) {

  }

  found.should.equal(1);
}

unittest {
  found(4).should.equal(1);
}

unittest {
  ({
    ({ }).should.beNull;
  }).should.throwException!TestException.msg;
}

unittest {
  [1, 2, 3].map!"a".should.throwException!TestException.msg;
}

unittest {
  Assert.equal([ new Value(1), new Value(2) ], [1, 3]);
  [ new Value(1), new Value(2) ].should.equal([1, 2]);
}

unittest {
  describe("when there are 2 android devices and one is not healthy", {
    MockDevice device1;
    MockDevice device2;

    it("should throw an exception if we request 2 android devices", {
      ({
        auto result = [ device1.idup, device2.idup ].filterBy(RunOptions("", "android", 2)).array;
      }).should.throwException!DeviceException.withMessage.equal("You requested 2 `androdid` devices, but there is only 1 healthy.");
    });
  });
}
