const std = @import("std");
const wren = @import("wren");

pub fn main(init: std.process.Init) !void {
    _ = init;
    var configuration: wren.Configuration = .{};
    wren.initConfiguration(&configuration);

    var wm = wren.newVm(&configuration);
    wm.deinit();

    std.debug.print("{s}\n", .{wren.VERSION_STRING});
}
