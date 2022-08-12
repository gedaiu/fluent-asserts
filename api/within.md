# The `within` operation

[up](../README.md)

Asserts that the target is a number or a date greater than or equal to the given number or date start, and less than or equal to the given number or date finish respectively. However, it's often best to assert that the target is equal to its expected value.

Works with:
  - expect(`core.time.Duration`).[to].[be].within(`core.time.Duration`)
  - expect(`std.datetime.systime.SysTime`).[to].[be].within(`std.datetime.systime.SysTime`)
  - expect(`byte`).[to].[be].within(`byte`)
  - expect(`ubyte`).[to].[be].within(`ubyte`)
  - expect(`short`).[to].[be].within(`short`)
  - expect(`ushort`).[to].[be].within(`ushort`)
  - expect(`int`).[to].[be].within(`int`)
  - expect(`uint`).[to].[be].within(`uint`)
  - expect(`long`).[to].[be].within(`long`)
  - expect(`ulong`).[to].[be].within(`ulong`)
  - expect(`float`).[to].[be].within(`float`)
  - expect(`double`).[to].[be].within(`double`)
  - expect(`real`).[to].[be].within(`real`)
