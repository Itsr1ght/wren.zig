const std = @import("std");

const Value = @import("../vm/value.zig").Value;
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

        const value: Value = switch (self.current.token_type) {
            .number => try self.parseExpression(),
            .string => .{ .str = try self.allocator.dupe(u8, self.current.start[0..self.current.length]) },
            else => return ParseError.UnHandledCharacter,
        };

        const owned_name = try self.allocator.dupe(u8, name);
        try self.globals.put(owned_name, value);

        return value;
    }

    if (self.current.token_type == .identifier) {
        const name = self.current.start[0..self.current.length];

        const saved_pos = self.lexer.pos;
        const saved_line = self.lexer.line;

        const possibly_equal = try self.lexer.nextToken();
        if (possibly_equal.token_type == .equal) {
            self.current = try self.lexer.nextToken();
            const value: Value = switch (self.current.token_type) {
                .number => try self.parseExpression(),
                .string => blk: {
                    const text = self.current.start[0..self.current.length];
                    self.current = try self.lexer.nextToken();
                    break :blk .{ .str = try self.allocator.dupe(u8, text) };
                },
                else => return ParseError.UnHandledCharacter,
            };
            if (!self.globals.contains(name)) {
                return error.UndefinedVariable;
            }

            if (self.globals.get(name)) |old_value| {
                switch (old_value) {
                    .num => {},
                    .str => |s| self.allocator.free(s),
                }
            }

            self.globals.put(name, value) catch return ParseError.OutOfMemory;
            return value;
        }
        self.lexer.pos = saved_pos;
        self.lexer.line = saved_line;
    }

    return self.parseExpression();
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
                const right = try self.parseUnary();
                if (left != .num or right != .num) return error.TypeMismatch;
                left = .{ .num = left.num + right.num };
            },
            .minus => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseUnary();
                if (left != .num or right != .num) return error.TypeMismatch;
                left = .{ .num = left.num - right.num };
            },
            else => return left,
        }
    }
}

test "Parse a number" {
    var lexer = Lexer.init("45");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 45), result);
}

test "Parse addition" {
    var lexer = Lexer.init("10 + 5");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 15), result);
}

test "Parse substraction" {
    var lexer = Lexer.init("45 - 10");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 35), result);
}

test "Parse multiplication" {
    var lexer = Lexer.init("4 * 4");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 16), result);
}

test "Parse division" {
    var lexer = Lexer.init("10/2");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 5), result);
}

test "chained expression" {
    var lexer = Lexer.init("1 + 2 + 3");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 6), result);
}

test "chained expression with multiply" {
    var lexer = Lexer.init("1 * 2 + 3");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 5), result);
}

test "chained expression with divide" {
    var lexer = Lexer.init("5 * 2 / 5");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 2), result);
}

test "chained expression - special case" {
    var lexer = Lexer.init("2 + 3 * 4");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 14), result);
}

test "chained expression - first multi" {
    var lexer = Lexer.init("2 * 3 + 4");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 10), result);
}

test "expression with braces - 1" {
    var lexer = Lexer.init("(2 * 3) + 4");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 10), result);
}

test "expression with braces - 2" {
    var lexer = Lexer.init("2 * (3 + 4)");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 14), result);
}

test "Parse unary" {
    var lexer = Lexer.init("-1 + 2");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 1), result);
}

test "Advance minus calculation" {
    var lexer = Lexer.init("(-1 * 2) + (2 * 2)");
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 2), result);
}

test "String test" {
    var lexer = Lexer.init(
        \\var name = "John"
        \\name
    );
    var map = std.StringHashMap(f64).init(std.testing.allocator);
    var parser = try Self.init(std.testing.allocator, &lexer, &map);

    const result = try parser.parseExpression();
    try std.testing.expectEqualStrings("John", result);
}
