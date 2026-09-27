const std = @import("std");
const utils = @import("../utils/default.zig");

const Lexer = @import("../compiler/Lexer.zig");
const Parser = @import("../compiler/Parser.zig");

pub const Configuration = struct {
    allocator: std.mem.Allocator,
    stdout: *const fn (Self, []const u8) void = utils.defaultPrint,
};

const Self = @This();

config: Configuration,
globals: std.StringHashMap(f64),

pub fn init(config: Configuration) Self {
    return .{ .config = config, .globals = .init(config.allocator) };
}

pub fn deinit(self: *Self) void {
    var it = self.globals.keyIterator();
    while (it.next()) |key| {
        self.config.allocator.free(key.*);
    }
    self.globals.deinit();
}

pub fn interpret(self: *Self, source: []const u8) !f64 {
    var lexer = Lexer.init(source);
    var parser = try Parser.init(self.config.allocator, &lexer, &self.globals);

    return parser.parseStatement();
}

test "interpret a number" {
    var vm = Self.init(.{
        .allocator = std.testing.allocator,
    });
    const result = try vm.interpret("42");

    try std.testing.expectEqual(@as(f64, 42), result);
}

test "interpret addition" {
    var vm = Self.init(.{
        .allocator = std.testing.allocator,
    });
    const result = try vm.interpret("5 + 5");

    try std.testing.expectEqual(@as(f64, 10), result);
}
