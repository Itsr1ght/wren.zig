const std = @import("std");
const wren = @import("wren");

const File = std.Io.File;

fn printHelp(io: std.Io) void {
    File.stdout().writeStreamingAll(io,
        \\Wren lang
        \\info: wren-cli run <file-name>.wren
        \\
        \\Commands:
        \\
        \\run: run the script
        \\repl: interpret the script
        \\
        \\General Options:
        \\
        \\--help: Print command-specific usage
    ) catch {};
}

fn runProgram(allocator: std.mem.Allocator, io: std.Io, writer: *std.Io.Writer, file_name: []const u8) void {
    const source = std.Io.Dir.cwd().readFileAlloc(io, file_name, allocator, .limited(1024 * 12)) catch |err| {
        if (err == error.FileNotFound) {
            writer.print("error: Cannot find the file: {s}\n\n", .{file_name}) catch {};
            writer.flush() catch {};
            printHelp(io);
            return;
        } else {
            writer.print("error: found error while running: {any}", .{err}) catch {};
            writer.flush() catch {};
            return;
        }
    };
    defer allocator.free(source);

    var vm = wren.WrenVM.init(.{ .allocator = allocator });
    defer vm.deinit();

    _ = vm.interpret(source) catch |err| {
        writer.print("error: error while compiling: {}\n\n", .{err}) catch return;
        writer.flush() catch return;
        return;
    };
}

fn interpretCode(allocator: std.mem.Allocator, io: std.Io, stdout: *std.Io.Writer) !void {
    var stdin_buffer: [1024 * 4]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);

    const stdin = &stdin_reader.interface;

    var vm = wren.WrenVM.init(.{
        .allocator = allocator,
    });
    defer vm.deinit();

    while (true) {
        try stdout.print(">", .{});
        try stdout.flush();

        const line = stdin.takeDelimiterExclusive('\n') catch return;
        _ = stdin.takeByte() catch {};

        if (line.len == 0) continue;
        if (std.mem.eql(u8, line, "exit")) {
            return;
        }

        const result = vm.interpret(line) catch |err| {
            try stdout.print("error : {}\n", .{err});
            try stdout.flush();
            continue;
        };

        switch (result) {
            .num => try stdout.print("{}\n", .{result.num}),
            .bool => try stdout.print("{}\n", .{result.bool}),
            .str => try stdout.print("{s}\n", .{result.str}),
        }
        try stdout.flush();
    }
}

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.gpa);
    defer init.gpa.free(args);

    var stdout_buffer: [1024 * 6]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--help")) {
            printHelp(init.io);
            return;
        }
        if (std.mem.eql(u8, arg, "run")) {
            if (i + 1 < args.len) {
                const file_name = args[i + 1];
                return runProgram(init.gpa, init.io, stdout, file_name);
            } else {
                try stdout.print("error: provide file\n\n", .{});
                try stdout.flush();
            }
        }

        if (std.mem.eql(u8, arg, "repl")) {
            return try interpretCode(init.gpa, init.io, stdout);
        }
    } else {
        printHelp(init.io);
    }
}
