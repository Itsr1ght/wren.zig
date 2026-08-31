const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const ObjString = @import("string.zig").ObjString;
const Symbol = @import("../compiler/symbol_table.zig").Symbol;
const SymbolTable = @import("../compiler/symbol_table.zig").SymbolTable;

pub const LoadModuleResult = struct {
    source: ?[]const u8 = null,
};

pub const ObjModule = struct {
    obj: Obj,
    variables: std.ArrayList(Value) = .empty,
    variable_names: SymbolTable,
    name: *ObjString,

    pub fn init(allocator: std.mem.Allocator, name: *ObjString) !ObjModule {
        return .{
            .obj = .{
                .type = .module,
                .is_dark = false,
                .next = null,
            },
            .variable_names = SymbolTable.init(allocator),
            .name = name,
        };
    }

    pub fn defineVariable(self: *ObjModule, allocator: std.mem.Allocator, name: []const u8, value: Value) !Symbol {
        const symbol = try self.variable_names.ensure(name);
        if (symbol == self.variables.items.len) {
            try self.variables.append(allocator, value);
        } else {
            self.variables.items[symbol] = value;
        }

        return symbol;
    }

    pub fn setVariable(self: *ObjModule, symbol: Symbol, value: Value) void {
        self.variables.items[symbol] = value;
    }

    pub fn getVariable(self: *ObjModule, symbol: *Symbol) Value {
        return self.variables.items[symbol];
    }

    pub fn deinit(self: *ObjModule, allocator: std.mem.Allocator) void {
        self.variables.deinit(allocator);
        self.variable_names.deinit(allocator) catch {};
    }
};
