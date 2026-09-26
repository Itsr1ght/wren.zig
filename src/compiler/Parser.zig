const std = @import("std");

const Lexer = @import("Lexer.zig");
const TokenType = Lexer.TokenType;
const Token = Lexer.Token;

const Self = @This();
lexer: *Lexer,
current: Token,

const ParseError = error{
    ExpectedNumber,
    ExpectedRightParen,
    UnterminatedComments,
    UnHandledCharacter,
    InvalidCharacter,
    StringEnd,
};

pub fn init(lexer: *Lexer) !Self {
    var self: Self = .{
        .lexer = lexer,
        .current = undefined,
    };
    self.current = try self.lexer.nextToken();
    return self;
}

pub fn parseNumber(self: *Self) ParseError!f64 {
    if (self.current.token_type != .number) {
        return ParseError.ExpectedNumber;
    }
    const text = self.current.start[0..self.current.length];

    self.current = try self.lexer.nextToken();
    return std.fmt.parseFloat(f64, text);
}

fn parsePrimary(self: *Self) ParseError!f64 {
    if (self.current.token_type == .left_bracket) {
        self.current = try self.lexer.nextToken();
        const value = try self.parseExpression();
        if (self.current.token_type != .right_bracket) {
            return ParseError.ExpectedRightParen;
        }
        self.current = try self.lexer.nextToken();
        return value;
    }
    return self.parseNumber();
}

fn parseUnary(self: *Self) ParseError!f64 {
    if (self.current.token_type == .minus) {
        self.current = try self.lexer.nextToken();
        const value = try self.parseUnary();
        return -value;
    }
    return self.parsePrimary();
}

fn parseTerm(self: *Self) ParseError!f64 {
    var left = try self.parseUnary();
    while (true) {
        switch (self.current.token_type) {
            .star => {
                self.current = try self.lexer.nextToken();
                const right = try self.parsePrimary();
                left = left * right;
            },
            .slash => {
                self.current = try self.lexer.nextToken();
                const right = try self.parsePrimary();
                left = left / right;
            },
            else => return left,
        }
    }
}

pub fn parseExpression(self: *Self) ParseError!f64 {
    var left = try self.parseTerm();
    while (true) {
        switch (self.current.token_type) {
            .plus => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseTerm();
                left = left + right;
            },
            .minus => {
                self.current = try self.lexer.nextToken();
                const right = try self.parseTerm();
                left = left - right;
            },
            else => return left,
        }
    }
}

test "Parse a number" {
    var lexer = Lexer.init("45");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 45), result);
}

test "Parse addition" {
    var lexer = Lexer.init("10 + 5");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 15), result);
}

test "Parse substraction" {
    var lexer = Lexer.init("45 - 10");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 35), result);
}

test "Parse multiplication" {
    var lexer = Lexer.init("4 * 4");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 16), result);
}

test "Parse division" {
    var lexer = Lexer.init("10/2");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 5), result);
}

test "chained expression" {
    var lexer = Lexer.init("1 + 2 + 3");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 6), result);
}

test "chained expression with multiply" {
    var lexer = Lexer.init("1 * 2 + 3");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 5), result);
}

test "chained expression with divide" {
    var lexer = Lexer.init("5 * 2 / 5");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 2), result);
}

test "chained expression - special case" {
    var lexer = Lexer.init("2 + 3 * 4");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 14), result);
}

test "chained expression - first multi" {
    var lexer = Lexer.init("2 * 3 + 4");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 10), result);
}

test "expression with braces - 1" {
    var lexer = Lexer.init("(2 * 3) + 4");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 10), result);
}

test "expression with braces - 2" {
    var lexer = Lexer.init("2 * (3 + 4)");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 14), result);
}

test "Parse unary" {
    var lexer = Lexer.init("-1 + 2");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 1), result);
}

test "Advance minus calculation" {
    var lexer = Lexer.init("(-1 * 2) + (2 * 2)");
    var parser = try Self.init(&lexer);

    const result = try parser.parseExpression();
    try std.testing.expectEqual(@as(f64, 2), result);
}
