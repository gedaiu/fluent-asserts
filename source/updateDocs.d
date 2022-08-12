module updateDocs;

import fluentasserts.core.operations.registry;
import std.stdio;
import std.file;
import std.array;
import std.string;

/// updating the built in operations in readme.md file
unittest {
  writeln("Updating the readme.md file.");

  auto content = readText("README.md").split("#");

  foreach(ref section; content) {
    if(!section.startsWith(" Built in operations\n")) {
      continue;
    }

    section = " Built in operations\n\n";

    section ~= Registry.instance.docs ~ "\n\n";
  }

  writeln(content.join("#"));

  std.file.write("README.md", content.join("#"));
}

