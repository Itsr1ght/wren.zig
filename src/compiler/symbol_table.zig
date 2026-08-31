const std = @import("std");

pub const Symbol = i32;

pub const SymbolTable = struct {
    symbols: std.ArrayList([]u8) = .empty,
    table: std.AutoHashMap(Symbol, []const u8),

    pub fn init(allocator: std.mem.Allocator) SymbolTable {
        return .{ .table = .init(allocator) };
    }

    pub fn find(self: SymbolTable, name: []const u8) ?Symbol {
        return self.table.get(name);
    }

    pub fn add(self: *SymbolTable, allocator: std.mem.Allocator, name: []const u8) Symbol {
        const symbol: Symbol = @intCast(self.symbols.items.len);
        const owned_name = allocator.dupe(u8, name);
        errdefer allocator.free(owned_name);

        try self.symbols.append(allocator, owned_name);
        try self.table.put(symbol, owned_name);

        return symbol;
    }

    pub fn get(self: *SymbolTable, symbol: Symbol) []const u8 {
        return self.symbols.items[@intCast(symbol)];
    }

    pub fn ensure(self: *SymbolTable, allocator: std.mem.Allocator, name: []const u8) Symbol {
        if (self.find(name)) |symbol| {
            return symbol;
        }
        return self.add(allocator, name);
    }

    pub fn deinit(self: *SymbolTable, allocator: std.mem.Allocator) !void {
        for (self.symbols.items) |item| {
            allocator.free(item);
        }
        self.symbols.deinit(allocator);
        self.table.deinit();
    }
};
