const std = @import("std");

const Symbol = u32;

pub const SymbolTable = struct {
    names: std.ArrayList([]const u8) = .empty,
    symbols: std.StringHashMap(Symbol),

    pub fn ensure(self: *SymbolTable, allocator: *std.mem.Allocator, name: []const u8) !Symbol {
        if (self.symbols.get(name)) |symbol| {
            return symbol;
        }
        const symbol: Symbol = @intCast(self.names.items.len);
        const owned_name = try allocator.dupe(u8, name);
        try self.names.append(allocator, owned_name);
        try self.symbols.put(owned_name, symbol);
    }

    pub fn get(self: *const SymbolTable, symbol: Symbol) []const u8 {
        return self.names.items[symbol];
    }

    pub fn deinit(self: SymbolTable, allocator: std.mem.Allocator) !void {
        for (self.names.items) |*item| {
            allocator.free(item);
        }
        self.symbols.deinit();
        self.names.deinit(allocator);
    }
};

pub const FunctionCall = struct {
    arity: u8,
    symbol: Symbol,
};
