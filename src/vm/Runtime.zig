const std = @import("std");
const Value = @import("value.zig").Value;

const Self = @This();

allocator: std.mem.Allocator,
globals: std.StringHashMap(Value),
scopes: std.ArrayList(std.StringHashMap(Value)) = .empty,
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
    defer self.globals.deinit();
    defer self.scopes.deinit(self.allocator);
}

pub fn track(self: *Self, text: []const u8) ![]const u8 {
    self.strings.append(self.allocator, text) catch |err| {
        self.allocator.free(text);
        return err;
    };
    return text;
}

pub fn dupe(self: *Self, text: []const u8) ![]const u8 {
    const string = try self.allocator.dupe(u8, text);
    self.strings.append(self.allocator, string) catch |err| {
        self.allocator.free(string);
        return err;
    };
    return string;
}

pub fn beginScope(self: *Self) !void {
    try self.scopes.append(self.allocator, std.StringHashMap(Value).init(self.allocator));
}

pub fn endScope(self: *Self) void {
    var scope = self.scopes.pop();
    if (scope) |*s| s.deinit();
}
