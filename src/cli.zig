const std = @import("std");
const wren = @import("wren");

pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args.toSlice(init.gpa);
    defer init.gpa.free(args);

    var file_name: []const u8 = "";

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, file_name, "")) {
            file_name = arg;
        }
    }

    var buffer: [1024 * 4]u8 = undefined;
    const source_data = try std.Io.Dir.cwd().readFile(init.io, file_name, &buffer);

    const vm = try wren.WrenVM.init(.{
        .allocator = init.gpa,
    });
    defer vm.deinit();

    try vm.compile(source_data);
}
