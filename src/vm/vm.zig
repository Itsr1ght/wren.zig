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

    strings: std.ArrayList(*string.ObjString) = .empty,
    modules: std.ArrayList(*module.ObjModule) = .empty,

    pub fn init(config: Configuration) !*WrenVM {
        const vm = try config.allocator.create(WrenVM);
        vm.* = .{
            .config = config,
        };
        return vm;
    }

    pub fn copyString(self: *WrenVM, data: []const u8) !*string.ObjString {
        for (self.strings.items) |str| {
            if (std.mem.eql(u8, data, str.char)) {
                return str;
            }
        }

        const obj_string = try string.ObjString.init(self.config.allocator, data);
        try self.strings.append(self.config.allocator, obj_string);
        return obj_string;
    }

    pub fn createModule(self: *WrenVM, name: []const u8) !*module.ObjModule {
        const mod_name = try self.copyString(name);
        const mod = try self.config.allocator.create(module.ObjModule);
        mod.* = try .init(self.config.allocator, mod_name);
        try self.modules.append(self.config.allocator, mod);
        return mod;
    }

    pub fn compile(self: *WrenVM, source: []const u8) !void {
        _ = self;
        var current_lexer = lexer.Lexer.init(source);
        var current_parser = parser.Parser.init(&current_lexer);
        try current_parser.parse();
    }

    pub fn deinit(self: *WrenVM) void {
        const allocator = self.config.allocator;
        for (self.strings.items) |str| {
            str.deinit(allocator);
        }
        self.strings.deinit(allocator);

        for (self.modules.items) |mod| {
            mod.deinit(allocator);
            allocator.destroy(mod);
        }
        self.modules.deinit(allocator);

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

test "Create a Module" {
    const vm = try WrenVM.init(.{
        .allocator = std.testing.allocator,
    });
    defer vm.deinit();

    _ = try vm.createModule("math");
    return std.testing.expect(true);
}
