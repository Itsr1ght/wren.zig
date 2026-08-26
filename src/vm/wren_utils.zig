const std = @import("std");

const WrenVM = @import("../lib.zig").WrenVM;
const SymbolTable = @import("wren_function.zig").SymbolTable;
const Method = @import("wren_value.zig").Method;

pub fn symbolTableFind(allocator: *std.mem.Allocator, symbols: *SymbolTable, name: []const u8) ?i32 {
    return symbols.ensure(allocator, name) catch null;
}

pub fn symbolTableAdd(vm: *WrenVM, symbols: *SymbolTable, name: []const u8, length: usize) i32 {
    const actual_name = name[0..length];
    for (symbols.names.items, 0..) |symbol, i| {
        if (std.mem.eql(u8, symbol, actual_name)) {
            return @intCast(i);
        }
    }

    const owned_name = vm.allocator.dupe(u8, actual_name){return -1};

    symbols.names.append(vm.allocator, owned_name) catch {
        return -1;
    };

    symbols.symbols[symbols.names.items.len] = owned_name;

    return @intCast(symbols.names.items.len - 1);
}

pub fn symbolTableEnsure(vm: *WrenVM, symbols: *SymbolTable, name: []const u8) i32 {
    const existing = symbolTableFind(&vm.allocator, symbols, name);
    if (existing) |exist| {
        return exist;
    }
}

pub fn methodBufferFill(allocator: *std.mem.Allocator, methods: *std.ArrayList(Method), index: usize) !void {
    while (methods.items.len <= index) {
        try methods.append(allocator, .{
            .type = .none,
            .implementation = .none,
        });
    }
}
