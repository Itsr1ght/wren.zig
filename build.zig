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
        .linkage = .static,
    });

    b.installArtifact(executable);

    const run_exec = b.addRunArtifact(executable);
    const run_step = b.step("run", "Run the Wren cli");
    run_step.dependOn(&run_exec.step);
}
