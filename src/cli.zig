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

fn runProgram(allocator: std.mem.Allocator, io: std.Io, file_name: []const u8) void {
    const source = std.Io.Dir.cwd().readFileAlloc(io, file_name, allocator, .limited(1024 * 12)) catch |err| {
        if (err == error.FileNotFound) {
            File.stdout().writeStreamingAll(io, "error: Cannot Find the file\n\n") catch {};
            printHelp(io);
            return;
        } else {
            const msg = std.fmt.allocPrint(allocator, "error: found error while running : {any}\n\n", .{err}) catch {
                File.stdout().writeStreamingAll(io, "error: cannot allocate memory") catch {};
                return;
            };
            defer allocator.free(msg);
            File.stdout().writeStreamingAll(io, msg) catch {};
            return;
        }
    };
    defer allocator.free(source);

    var vm = wren.WrenVM.init(.{ .allocator = allocator });
    defer vm.deinit();

    _ = vm.interpret(source) catch {
        File.stdout().writeStreamingAll(io, "error: error while compiling\n\n") catch return;
        return;
    };
}

fn interpretCode(allocator: std.mem.Allocator, io: std.Io) !void {
    var stdin_buffer: [1024 * 4]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(io, &stdin_buffer);

    var stdout_buffer: [1024 * 4]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    const stdin = &stdin_reader.interface;
    const stdout = &stdout_writer.interface;

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
                return runProgram(init.gpa, init.io, file_name);
            } else {
                File.stdout().writeStreamingAll(init.io, "error: provide file\n\n") catch {};
            }
        }

        if (std.mem.eql(u8, arg, "repl")) {
            return try interpretCode(init.gpa, init.io);
        }
    } else {
        printHelp(init.io);
    }
}
