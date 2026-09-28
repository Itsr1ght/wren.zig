const std = @import("std");
const utils = @import("../utils/default.zig");

const Value = @import("value.zig").Value;
const Runtime = @import("Runtime.zig");
const Lexer = @import("../compiler/Lexer.zig");
const Parser = @import("../compiler/Parser.zig");

pub const Configuration = struct {
    allocator: std.mem.Allocator,
    stdout: *const fn (Self, []const u8) void = utils.defaultPrint,
};

const Self = @This();

config: Configuration,
runtime: Runtime,

pub fn init(config: Configuration) Self {
    return .{
        .config = config,
        .runtime = .init(config.allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.runtime.deinit();
}

pub fn interpret(self: *Self, source: []const u8) !Value {
    var lexer = Lexer.init(source);
    var parser = try Parser.init(&self.runtime, &lexer);

    return parser.parseProgram();
}

test "interpret a number" {
    var vm = Self.init(.{
        .allocator = std.testing.allocator,
    });
    defer vm.deinit();

    const result = try vm.interpret("42");

    try std.testing.expectEqual(@as(f64, 42), result.num);
}

test "interpret addition" {
    var vm = Self.init(.{
        .allocator = std.testing.allocator,
    });
    defer vm.deinit();

    const result = try vm.interpret("5 + 5");

    try std.testing.expectEqual(@as(f64, 10), result.num);
}

test "program with multiple statements" {
    var vm = Self.init(.{ .allocator = std.testing.allocator });
    defer vm.deinit();

    const source =
        \\var a = 5
        \\var b = 5
        \\a + b
    ;

    const result = try vm.interpret(source);
    try std.testing.expectEqual(@as(f64, 10), result.num);
}
