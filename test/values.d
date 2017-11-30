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
