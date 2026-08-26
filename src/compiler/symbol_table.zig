const std = @import("std");

pub const Symbol = i32;

pub const SymbolTable = struct {
    symbols: std.ArrayList([]const u8) = .empty,
    table: std.AutoHashMap(Symbol, []const u8),

    pub fn init(allocator: std.mem.Allocator) SymbolTable {
        return .{ .table = .init(allocator) };
    }

    pub fn find(self: SymbolTable, name: []const u8) ?Symbol {
        self.table.get(name);
    }

    pub fn add(self: *SymbolTable, name: []const u8) Symbol {
        self.table[self.symbols.items.len] = name;
        return self.symbols.items.len;
    }

    pub fn ensure(self: *SymbolTable, name: []const u8) Symbol {
        if (self.find(name)) |symbol| {
            return symbol;
        }
        return self.add(name);
    }

    pub fn deinit(self: *SymbolTable, allocator: std.mem.Allocator) !void {
        for (self.symbols.items) |item| {
            allocator.free(item);
        }
        self.symbols.deinit(allocator);
        self.table.deinit();
    }
};
