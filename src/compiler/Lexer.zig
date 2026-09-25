pub const TokenType = enum {
    // Reserved words
    @"break",
    class,
    construct,
    @"continue",
    @"else",
    false,
    @"for",
    foreign,
    @"if",
    import,
    as,
    in,
    is,
    null,
    @"return",
    static,
    super,
    this,
    true,
    @"var",
    @"while",
    // Precedence and Associativity
    left_bracket, // (
    right_bracket, // )
    left_square_bracket, // [
    right_square_bracket, // ]
    dot, // .
    exclamation, // !
    tilda, // ~
    star, // *
    slash, // /
    percent, // %
    plus, // +
    minus, // -
    dotdot, // ..
    dotdotdot, // ...
    less_than, // <
    less_than_equal, // <=
    greater_than, // >
    greater_than_equal, // >=
    @"and", // &
    caret, // ^
    @"or", // |
    equal, // =
    equalequal, // ==
    notequal, // !=
    andand, // &&
    oror, // ||
    questionmark, // ?
    colon, // :
    semicolon, // ;
    coma, // ,
    singlequote, // '
    doublequote, // "
    underscore, // _
    // Types
    identifier,
    number,
    string,
    boolean,
    eof,
};

pub const Token = struct {
    token_type: TokenType,
    start: [*]const u8,
    length: usize,
    line: usize,
};

const Self = @This();
data: []const u8,
pos: usize = 0,
line: usize = 0,

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}

fn identiferType(text: []const u8) TokenType {
    const keywords = std.StaticStringMap(TokenType).initComptime(.{
        .{ "if", .@"if" },
        .{ "else", .@"else" },
        .{ "var", .@"var" },
        .{ "while", .@"while" },
        .{ "break", .@"break" },
        .{ "continue", .@"continue" },
        .{ "for", .@"for" },
        .{ "return", .@"return" },
        .{ "class", .class },
        .{ "super", .super },
        .{ "this", .this },
        .{ "true", .true },
        .{ "false", .false },
        .{ "null", .null },
        .{ "foreign", .foreign },
        .{ "import", .import },
        .{ "static", .static },
        .{ "as", .as },
        .{ "in", .in },
        .{ "is", .is },
    });
    return keywords.get(text) orelse .identifier;
}

pub fn init(source: []const u8) Self {
    return .{ .data = source };
}

fn isAtEnd(self: *const Self) bool {
    return self.pos >= self.data.len;
}

fn peek(self: *Self) u8 {
    if (self.pos >= self.data.len) return 0;
    return self.data[self.pos];
}

fn peekNext(self: *Self) u8 {
    if (self.pos + 1 >= self.data.len) return 0;
    return self.data[self.pos + 1];
}

fn advance(self: *Self) u8 {
    const c = self.peek();
    self.pos += 1;
    return c;
}

fn skipWhiteSpace(self: *Self) void {
    while (true) {
        const c = self.peek();
        switch (c) {
            ' ', '\r', '\t' => _ = self.advance(),
            '\n' => {
                self.line += 1;
                _ = self.advance();
            },
            else => return,
        }
    }
}

fn number(self: *Self) Token {
    const start = self.pos;
    while (isDigit(self.peek())) {
        _ = self.advance();
    }

    if (self.peek() == '.' and isDigit(self.peekNext())) {
        _ = self.advance();
        while (isDigit(self.peek())) {
            _ = self.advance();
        }
    }

    return .{
        .token_type = .number,
        .start = self.data.ptr + start,
        .length = self.pos - start,
        .line = self.line,
    };
}

fn string(self: *Self) !Token {
    _ = self.advance();
    const start = self.pos;
    while (self.peek() != '"' and !self.isAtEnd()) {
        if (self.peek() == '\n') self.line += 1;
        _ = self.advance();
    }
    const length = self.pos - start;
    if (self.isAtEnd()) return error.StringEnd;

    _ = self.advance();

    return .{
        .token_type = .string,
        .start = self.data.ptr + start,
        .length = length,
        .line = self.line,
    };
}

fn identifier(self: *Self) Token {
    const start = self.pos;

    while (isAlpha(self.peek()) or isDigit(self.peek())) {
        _ = self.advance();
    }

    const text = self.data[start..self.pos];
    return .{
        .token_type = identiferType(text),
        .start = self.data.ptr + start,
        .length = self.pos - start,
        .line = self.line,
    };
}

pub fn nextToken(self: *Self) !Token {
    self.skipWhiteSpace();
    if (self.isAtEnd()) {
        return .{
            .token_type = .eof,
            .line = self.line,
            .length = 0,
            .start = self.data.ptr + self.pos,
        };
    }

    const c = self.peek();
    if (isDigit(c)) {
        return self.number();
    }
    switch (c) {
        '\"' => return try self.string(),
        else => return self.identifier(),
    }

    return error.UnHandledCharacter;
}

const std = @import("std");

test "Parse a Int" {
    var lexer = Self.init("222");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(token.token_type, TokenType.number);
    try std.testing.expectEqualStrings("222", token.start[0..token.length]);
}

test "Parse a Float" {
    var lexer = Self.init("3.14");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(token.token_type, TokenType.number);
    try std.testing.expectEqualStrings("3.14", token.start[0..token.length]);
}

test "Parse a String" {
    var lexer = Self.init("\"hello\"");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(token.token_type, TokenType.string);
    try std.testing.expectEqualStrings("hello", token.start[0..token.length]);
}

test "Parse a multi-line String" {
    var lexer = Self.init(
        \\"
        \\ Hello World
        \\ Snap back to reality
        \\"
    );
    const token = try lexer.nextToken();

    try std.testing.expectEqual(token.token_type, TokenType.string);
    try std.testing.expectEqualStrings(
        \\
        \\ Hello World
        \\ Snap back to reality
        \\
    , token.start[0..token.length]);
}

test "Parse a while" {
    var lexer = Self.init("while");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(token.token_type, TokenType.@"while");
}

test "Parse a identifier" {
    var lexer = Self.init("hello_world");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(token.token_type, TokenType.identifier);
    try std.testing.expectEqualStrings("hello_world", token.start[0..token.length]);
}
