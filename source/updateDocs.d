module updateDocs;

import fluentasserts.core.operations.registry;
import std.stdio;
import std.file;
import std.path;
import std.array;
import std.algorithm;
import std.string;

/// updating the built in operations in readme.md file
unittest {
  auto content = readText("README.md").split("#");

  foreach(ref section; content) {
    if(!section.startsWith(" Built in operations\n")) {
      continue;
    }

    section = " Built in operations\n\n";

    section ~= Registry.instance.docs ~ "\n\n";
  }

  std.file.write("README.md", content.join("#"));
}

/// updating the operations md files
unittest {
  foreach(operation; Registry.instance.registeredOperations) {
    string content = "# The `" ~ operation ~ "` operation\n\n";
    content ~= "[up](../README.md)\n\n";

    content ~= "Works with:\n" ;
    content ~= Registry.instance.bindingsForName(operation)
      .map!(a => "  - expect(`" ~ a.valueType ~ "`).[to].[be]." ~ operation ~ "(`" ~ a.expectedValueType ~ "`)")
      .join("\n");

    content ~= "\n";

    std.file.write(buildPath("api", operation ~ ".md"), content);
  }
}
