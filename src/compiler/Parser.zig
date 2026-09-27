const std = @import("std");

const Value = @import("../vm/value.zig").Value;
const ValueType = @import("../vm/value.zig").ValueType;
const Lexer = @import("Lexer.zig");
const TokenType = Lexer.TokenType;
const Token = Lexer.Token;

const Self = @This();
lexer: *Lexer,
current: Token,
globals: *std.StringHashMap(Value),
allocator: std.mem.Allocator,

const ParseError = error{
    ExpectedNumber,
    ExpectedIdentifer,
    ExpectedEquals,
    ExpectedRightParen,
    UnterminatedComments,
    UnHandledCharacter,
    InvalidCharacter,
    UndefinedVariable,
    StringEnd,
    AlreadyExist,
    TypeMismatch,
    UnExpectedComparison,
} || std.mem.Allocator.Error;

pub fn init(allocator: std.mem.Allocator, lexer: *Lexer, globals: *std.StringHashMap(Value)) !Self {
    var self: Self = .{
        .lexer = lexer,
        .current = undefined,
        .allocator = allocator,
        .globals = globals,
    };
    self.current = try self.lexer.nextToken();
    return self;
}

pub fn parseNumber(self: *Self) ParseError!Value {
    if (self.current.token_type != .number) {
        return ParseError.ExpectedNumber;
    }
    const text = self.current.start[0..self.current.length];

    self.current = try self.lexer.nextToken();

    return .{ .num = try std.fmt.parseFloat(f64, text) };
}

pub fn parseStatement(self: *Self) ParseError!Value {
    if (self.current.token_type == .@"var") {
        self.current = try self.lexer.nextToken();

        if (self.current.token_type != .identifier) return ParseError.ExpectedIdentifer;
        const name = self.current.start[0..self.current.length];

        if (self.globals.contains(name)) return ParseError.AlreadyExist;

        self.current = try self.lexer.nextToken();

        if (self.current.token_type != .equal) return ParseError.ExpectedEquals;
        self.current = try self.lexer.nextToken();

        const value: Value = try self.parseExpression();

        const owned_value: Value = switch (value) {
            .str => |s| .{ .str = try self.allocator.dupe(u8, s) },
            .num, .bool => value,
        };

        const owned_name = try self.allocator.dupe(u8, name);
        try self.globals.put(owned_name, owned_value);

        return value;
    }

    if (self.current.token_type == .identifier) {
        const name = self.current.start[0..self.current.length];

        const saved_pos = self.lexer.pos;
        const saved_line = self.lexer.line;

        const possibly_equal = try self.lexer.nextToken();
        if (possibly_equal.token_type == .equal) {
            self.current = try self.lexer.nextToken();

            const value: Value = try self.parseEquality();

            if (!self.globals.contains(name)) {
                return error.UndefinedVariable;
            }

            if (self.globals.get(name)) |old_value| {
                switch (old_value) {
                    .num, .bool => {},
                    .str => |s| self.allocator.free(s),
                }
            }

            const owned_value: Value = switch (value) {
                .str => |s| .{ .str = try self.allocator.dupe(u8, s) },
                .num, .bool => value,
            };

            self.globals.put(name, owned_value) catch return ParseError.OutOfMemory;
            return value;
        }
        self.lexer.pos = saved_pos;
        self.lexer.line = saved_line;
    }

    return self.parseEquality();
}

fn parseComparison(self: *Self) ParseError!Value {
    var left = try self.parseExpression();
    while (true) {
        switch (self.current.token_type) {
            .less_than => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseExpression();
                if (left != .num or right != .num) return ParseError.TypeMismatch;
                const cmp = left.num < right.num;
                left = .{ .bool = cmp };
            },
            .greater_than => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseExpression();
                if (left != .num or right != .num) return ParseError.TypeMismatch;
                const cmp = left.num > right.num;
                left = .{ .bool = cmp };
            },
            .less_than_equal => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseExpression();
                if (left != .num or right != .num) return ParseError.TypeMismatch;
                const cmp = left.num <= right.num;
                left = .{ .bool = cmp };
            },
            .greater_than_equal => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseExpression();
                if (left != .num or right != .num) return ParseError.TypeMismatch;
                const cmp = left.num >= right.num;
                left = .{ .bool = cmp };
            },
            else => return left,
        }
    }
}

fn parseEquality(self: *Self) ParseError!Value {
    var left = try self.parseComparison();

    while (true) {
        switch (self.current.token_type) {
            .equalequal => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseComparison();
                const cmp = Value.valuesEqual(left, right);
                left = .{ .bool = cmp };
            },
            .bangeql => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseComparison();
                const cmp = Value.valuesEqual(left, right);
                left = .{ .bool = !cmp };
            },
            else => return left,
        }
    }
}

fn parsePrimary(self: *Self) ParseError!Value {
    if (self.current.token_type == .left_bracket) {
        self.current = try self.lexer.nextToken();
        const value = try self.parseExpression();
        if (self.current.token_type != .right_bracket) {
            return ParseError.ExpectedRightParen;
        }
        self.current = try self.lexer.nextToken();
        return value;
    }

    if (self.current.token_type == .identifier) {
        const name = self.current.start[0..self.current.length];
        const value = self.globals.get(name) orelse return error.UndefinedVariable;
        self.current = try self.lexer.nextToken();
        return value;
    }

    if (self.current.token_type == .string) {
        const text = self.current.start[0..self.current.length];
        self.current = try self.lexer.nextToken();
        return .{ .str = text };
    }

    if (self.current.token_type == .true) {
        self.current = try self.lexer.nextToken();
        return .{ .bool = true };
    }

    if (self.current.token_type == .false) {
        self.current = try self.lexer.nextToken();
        return .{ .bool = false };
    }

    return self.parseNumber();
}

fn parseUnary(self: *Self) ParseError!Value {
    if (self.current.token_type == .minus) {
        self.current = try self.lexer.nextToken();
        if (self.current.token_type != .number) return ParseError.ExpectedNumber;
        const value = try self.parseUnary();
        return .{ .num = -value.num };
    }
    return self.parsePrimary();
}

fn parseTerm(self: *Self) ParseError!Value {
    var left = try self.parseUnary();
    while (true) {
        switch (self.current.token_type) {
            .star => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseUnary();
                if (left != .num or right != .num) return error.TypeMismatch;
                left.num = left.num * right.num;
            },
            .slash => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseUnary();
                if (left != .num or right != .num) return error.TypeMismatch;
                left.num = left.num / right.num;
            },
            else => return left,
        }
    }
}

pub fn parseExpression(self: *Self) ParseError!Value {
    var left = try self.parseTerm();
    while (true) {
        switch (self.current.token_type) {
            .plus => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseTerm();
                if (left != .num or right != .num) return error.TypeMismatch;
                left = .{ .num = left.num + right.num };
            },
            .minus => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseTerm();
                if (left != .num or right != .num) return error.TypeMismatch;
                left = .{ .num = left.num - right.num };
            },
            else => return left,
        }
    }
}

pub fn parseProgram(self: *Self) ParseError!Value {
    var last: Value = .{ .num = 0 };
    while (self.current.token_type != .eof) {
        last = try self.parseStatement();
    }
    return last;
}

test "Parse a number" {
    var lexer = Lexer.init("45");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 45), result.num);
}

test "Parse addition" {
    var lexer = Lexer.init("10 + 5");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 15), result.num);
}

test "Parse substraction" {
    var lexer = Lexer.init("45 - 10");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 35), result.num);
}

test "Parse multiplication" {
    var lexer = Lexer.init("4 * 4");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 16), result.num);
}

test "Parse division" {
    var lexer = Lexer.init("10/2");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 5), result.num);
}

test "chained expression" {
    var lexer = Lexer.init("1 + 2 + 3");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(@as(f64, 6), result.num);
}

test "chained expression with multiply" {
    var lexer = Lexer.init("1 * 2 + 3");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 5), result.num);
}

test "chained expression with divide" {
    var lexer = Lexer.init("5 * 2 / 5");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 2), result.num);
}

test "chained expression - special case" {
    var lexer = Lexer.init("2 + 3 * 4");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 14), result.num);
}

test "chained expression - first multi" {
    var lexer = Lexer.init("2 * 3 + 4");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 10), result.num);
}

test "expression with braces - 1" {
    var lexer = Lexer.init("(2 * 3) + 4");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(@as(f64, 10), result.num);
}

test "expression with braces - 2" {
    var lexer = Lexer.init("2 * (3 + 4)");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(@as(f64, 14), result.num);
}

test "Parse unary" {
    var lexer = Lexer.init("-1 + 2");
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 1), result.num);
}

test "Advance minus calculation" {
    var lexer = Lexer.init("(-1 * 2) + (2 * 2)");
    var map = std.StringHashMap(Value).init(std.testing.allocator);

    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(@as(f64, 2), result.num);
}

test "String test" {
    var lexer = Lexer.init(
        \\var name = "John"
        \\name
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqualStrings("John", result.str);
}

test "testing bool" {
    var lexer = Lexer.init(
        \\true
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(true, result.bool);
}

test "comparing bool" {
    var lexer = Lexer.init(
        \\true==true
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(true, result.bool);
}

test "comparing number" {
    var lexer = Lexer.init(
        \\20==20
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(true, result.bool);
}

test "comparing number - 2" {
    var lexer = Lexer.init(
        \\20==10
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(false, result.bool);
}

test "greater than test" {
    var lexer = Lexer.init(
        \\20>10
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(true, result.bool);
}

test "less than test" {
    var lexer = Lexer.init(
        \\10<20
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(true, result.bool);
}

test "string comparison" {
    var lexer = Lexer.init(
        \\"Hello"=="Hello"
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(true, result.bool);
}

test "not the string" {
    var lexer = Lexer.init(
        \\"Hello"!="Hello"
    );
    var map = std.StringHashMap(Value).init(std.testing.allocator);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            std.testing.allocator.free(entry.key_ptr.*);
            switch (entry.value_ptr.*) {
                .str => |s| std.testing.allocator.free(s),
                else => {},
            }
        }
        map.deinit();
    }

    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseStatement();
    try std.testing.expectEqual(false, result.bool);
}
