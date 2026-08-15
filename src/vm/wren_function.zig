const std = @import("std");

const Symbol = u32;

pub const SymbolTable = struct {
    names: std.ArrayList([]const u8),
    pub fn get(self: *const SymbolTable, symbol: Symbol) []const u8 {
        return self.names.items[symbol];
    }
};

pub const FunctionCall = struct {
    arity: u8,
    symbol: Symbol,
};
