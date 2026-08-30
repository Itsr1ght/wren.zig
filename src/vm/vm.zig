const std = @import("std");

pub const class = @import("class.zig");
pub const closure = @import("closure.zig");
pub const fiber = @import("fiber.zig");
pub const foreign = @import("foreign.zig");
pub const function = @import("function.zig");
pub const gc = @import("gc.zig");
pub const instance = @import("instance.zig");
pub const method = @import("method.zig");
pub const module = @import("module.zig");
pub const object = @import("object.zig");
pub const string = @import("string.zig");
pub const value = @import("value.zig");

pub const lexer = @import("../compiler/lexer.zig");
pub const parser = @import("../compiler/parser.zig");
pub const symbol_table = @import("../compiler/symbol_table.zig");

const utils = @import("utils.zig");

pub const Configuration = struct {
    allocator: std.mem.Allocator,
    write: *const fn (*WrenVM, []const u8) void = utils.defaultWriter,
    resolve_module: ?*const fn (*WrenVM, []const u8) []const u8 = null,
    load_module: ?*const fn (*WrenVM) module.LoadModuleResult = null,
};

pub const WrenVM = struct {
    config: Configuration,

    pub fn init(config: Configuration) !*WrenVM {
        const vm = try config.allocator.create(WrenVM);
        vm.* = .{
            .config = config,
        };
        return vm;
    }

    pub fn compile(self: *WrenVM, source: []const u8) !void {
        _ = self;
        var current_lexer = lexer.Lexer.init(source);
        const current_parser = parser.Parser.init(&current_lexer);
        _ = current_parser;
    }

    pub fn deinit(self: *WrenVM) void {
        const allocator = self.config.allocator;
        allocator.destroy(self);
    }
};

test "Init VM" {
    const vm = try WrenVM.init(.{
        .allocator = std.testing.allocator,
    });
    defer vm.deinit();

    try vm.compile("System.print(\"Hello World\")");
    return std.testing.expect(true);
}
