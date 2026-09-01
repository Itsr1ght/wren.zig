const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const wren_lib = b.addModule("wren", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const wren_cli = b.createModule(.{
        .root_source_file = b.path("src/cli.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "wren", .module = wren_lib },
        },
    });

    const executable = b.addExecutable(.{
        .name = "wren-cli",
        .root_module = wren_cli,
        .use_llvm = true,
    });

    b.installArtifact(executable);

    const run_exec = b.addRunArtifact(executable);

    const test_executable = b.addTest(.{
        .root_module = wren_lib,
        .use_llvm = true,
        .name = "wren-test",
    });

    const run_test = b.addRunArtifact(test_executable);

    if (b.args) |args| {
        run_exec.addArgs(args);
        run_test.addArgs(args);
    }

    const run_step = b.step("run", "Run the Wren cli");
    run_step.dependOn(&run_exec.step);

    const test_step = b.step("test", "Test the wren module");
    test_step.dependOn(&run_test.step);
}
