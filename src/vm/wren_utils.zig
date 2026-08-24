const std = @import("std");

const WrenVM = @import("../lib.zig").WrenVM;
const SymbolTable = @import("wren_function.zig").SymbolTable;
const Method = @import("wren_value.zig").Method;

pub fn symbolTableFind(allocator: *std.mem.Allocator, symbols: *SymbolTable, name: []const u8) ?i32 {
    return symbols.ensure(allocator, name) catch null;
}

pub fn symbolTableAdd(vm: *WrenVM, symbols: *SymbolTable, name: []const u8, length: usize) i32 {
    _ = vm;
    _ = symbols;
    _ = name;
    _ = length;
}

pub fn symbolTableEnsure(vm: *WrenVM, symbols: *SymbolTable, name: []const u8, length: usize) i32 {
    _ = length;
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
