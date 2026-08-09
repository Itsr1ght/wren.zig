const std = @import("std");

pub const print = std.debug.print;

pub fn wrenPrint(comptime format: []const u8, args: anytype) void {
    print(format, args);
}
