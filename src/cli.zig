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
            const msg = std.fmt.allocPrint(
                allocator,
                "error: found error while running : {any}\n\n",
                .{err},
            ) catch {
                File.stdout().writeStreamingAll(io, "error: cannot allocate memory") catch {};
                return;
            };
            defer allocator.free(msg);
            File.stdout().writeStreamingAll(io, msg) catch {};
            return;
        }
    };
    defer allocator.free(source);

    const vm = wren.WrenVM.init(.{
        .allocator = allocator,
    }) catch {
        File.stdout().writeStreamingAll(io, "Error while creating the VM\n\n") catch {};
        return;
    };
    defer vm.deinit();

    vm.compile(source) catch {
        File.stdout().writeStreamingAll(io, "error: error while compiling\n\n");
        return;
    };
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
    } else {
        printHelp(init.io);
    }
}
