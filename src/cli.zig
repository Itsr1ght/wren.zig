const std = @import("std");
const wren = @import("wren");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.gpa);
    defer init.gpa.free(args);

    for (args[1..]) |arg| {
        wren.wrenPrint("Args: {s}\n", .{arg});
    }
}
