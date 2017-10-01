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
