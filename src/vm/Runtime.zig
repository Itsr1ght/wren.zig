const std = @import("std");
const Value = @import("value.zig").Value;

const Self = @This();

allocator: std.mem.Allocator,
globals: std.StringHashMap(Value),
strings: std.ArrayList([]const u8) = .empty,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .globals = .init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    for (self.strings.items) |s| self.allocator.free(s);
    self.strings.deinit(self.allocator);

    var it = self.globals.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        switch (entry.value_ptr.*) {
            .str => |s| self.allocator.free(s),
            .num, .bool => {},
        }
    }
}

pub fn track(self: *Self, text: []const u8) ![]const u8 {
    self.strings.append(self.allocator, text) catch |err| {
        self.allocator.free(text);
        return err;
    };
    return text;
}
