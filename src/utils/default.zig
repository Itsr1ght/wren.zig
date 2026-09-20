const std = @import("std");
const WrenWM = @import("../vm/WrenVM.zig");

pub fn defaultPrint(vm: WrenWM, data: []const u8) void {
    _ = vm;
    std.debug.print("{s}", .{data});
}
