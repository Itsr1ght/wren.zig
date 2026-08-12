const std = @import("std");
const wren = @import("wren");

pub fn main(init: std.process.Init) !void {
    wren.initConfiguration(.{});

    const args = try init.minimal.args.toSlice(init.gpa);
    defer init.gpa.free(args);

    for (args[1..]) |arg| {
        std.debug.print("{s}\n", .{arg});
    }

    std.debug.print("{d}\n", .{wren.getVersionNumber()});
}
