pub const TokenType = enum {
    // Reserved words
    as,
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
    number,
    character,
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

    return .{
        .token_type = .number,
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

    return error.UnHandledCharacter;
}

const std = @import("std");

test "Parse a Number" {
    var lexer = Self.init("222");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(token.token_type, TokenType.number);
    try std.testing.expectEqualStrings("222", token.start[0..token.length]);
}
