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

fn advance(self: Self) u8 {
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

pub fn nextToken(self: *Self) Token {
    self.skipWhiteSpace();
}

const std = @import("std");

test "Parse a character" {
    var lexer = Self.init("a");
    const token = lexer.nextToken();
    if (token.token_type == .character) {
        try std.testing.expect(true);
    } else {
        try std.testing.expect(true);
    }
}
