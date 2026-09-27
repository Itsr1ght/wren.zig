const std = @import("std");
const utils = @import("../utils/default.zig");

const Value = @import("value.zig").Value;
const Lexer = @import("../compiler/Lexer.zig");
const Parser = @import("../compiler/Parser.zig");

pub const Configuration = struct {
    allocator: std.mem.Allocator,
    stdout: *const fn (Self, []const u8) void = utils.defaultPrint,
};

const Self = @This();

config: Configuration,
globals: std.StringHashMap(Value),

pub fn init(config: Configuration) Self {
    return .{ .config = config, .globals = .init(config.allocator) };
}

pub fn deinit(self: *Self) void {
    var it = self.globals.iterator();
    while (it.next()) |entry| {
        self.config.allocator.free(entry.key_ptr.*);
        switch (entry.value_ptr.*) {
            .str => |s| self.config.allocator.free(s),
            .num => {},
        }
    }
    self.globals.deinit();
}

pub fn interpret(self: *Self, source: []const u8) !Value {
    var lexer = Lexer.init(source);
    var parser = try Parser.init(self.config.allocator, &lexer, &self.globals);

    return parser.parseStatement();
}

test "interpret a number" {
    var vm = Self.init(.{
        .allocator = std.testing.allocator,
    });
    defer vm.deinit();

    const result = try vm.interpret("42");

    try std.testing.expectEqual(@as(f64, 42), result);
}

test "interpret addition" {
    var vm = Self.init(.{
        .allocator = std.testing.allocator,
    });
    defer vm.deinit();

    const result = try vm.interpret("5 + 5");

    try std.testing.expectEqual(@as(f64, 10), result);
}
