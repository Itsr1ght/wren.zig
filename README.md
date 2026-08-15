# wren.zig

> Work In Progress

[Wrenlang](https://wren.io/) rewritten in Zig.

## Instruction for package

```bash
zig fetch --save https://github.com/Itsr1ght/wren.zig
```

```zig
var wren_package = b.dependency("wren", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("wren", wren_package.module("wren"));
```

## Instruction for running cli

Run the command with below for running the example script

```bash
zig build run -- examples/wren/hello.wren
```
