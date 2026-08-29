const std = @import("std");

const WrenVM = @import("vm.zig").WrenVM;

pub fn defaultWriter(_: *WrenVM, text: []const u8) void {
    std.debug.print("{s}", .{text});
}
