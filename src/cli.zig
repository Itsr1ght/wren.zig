const std = @import("std");
const wren = @import("wren");

pub fn main(init: std.process.Init) !void {
    _ = init;
    wren.wrenPrint("Hello {s}", .{"World"});
}
