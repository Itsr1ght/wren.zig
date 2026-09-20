const std = @import("std");
const utils = @import("../utils/default.zig");

pub const Configuration = struct {
    allocator: std.mem.Allocator,
    stdout: *const fn (Self, []const u8) void = utils.defaultPrint,
};

const Self = @This();

config: Configuration,

pub fn init(config: Configuration) Self {
    return .{ .config = config };
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn compile(self: *Self, source: []const u8) !void {
    _ = self;
    _ = source;
}
