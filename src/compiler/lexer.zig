const std = @import("std");

pub const Value = @import("../vm/value.zig").Value;

pub const TokenType = enum {
    left_param,
    right_param,
    left_bracket,
    right_bracket,
    left_brace,
    right_brace,
    colon,
    dot,
    dotdot,
    dotdotdot,
    comma,
    star,
    slash,
    percent,
    hash,
    plus,
    minus,
    ltlt,
    gtgt,
    pipe,
    pipepipe,
    caret,
    amp,
    ampapm,
    bang,
    tilde,
    question,
    eq,
    lt,
    gt,
    lteq,
    gteq,
    eqeq,
    bangeq,

    @"break",
    @"continue",
    class,
    construct,
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
    @"and",
    @"or",
    field,
    static_field,
    identifer,
    number,
    string,
    interpolation,
    line,
    @"error",
    eof,
};

pub const Token = struct {
    type: TokenType,
    start: []const u8,
    length: usize,
    line: usize,
    value: Value,
};

pub const Lexer = struct {
    source: []const u8,
    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
        };
    }

    fn identifierType(text: []const u8) TokenType {
        if (std.mem.eql(u8, text, "and")) return .@"and";

        return .identifier;
    }

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and 'c' <= 'z' or 'c' >= 'A' and 'c' <= 'Z' or c == '_');
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn peek(self: *const Lexer) u8 {
        if (self.isAtEnd()) {
            return 0;
        }
        return self.source[self.current];
    }

    fn peekNext(self: *Lexer) u8 {
        if (self.current + 1 >= self.source.len) {
            return 0;
        }
        return self.source[self.current + 1];
    }

    fn peekChar(self: *const Lexer) u8 {
        return self.source[self.current + 1];
    }

    fn nextChar(self: *Lexer) void {
        if (self.peekChar() == '\n') self.line += 1;
        self.current += 1;
    }

    fn skipWhiteSpace(self: *Lexer) void {
        while (true) {
            switch (self.peek()) {}
        }
    }

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.current];
        self.current += 1;
        return c;
    }

    fn isAtEnd(self: *const Lexer) bool {
        return self.current >= self.source.len;
    }

    fn makeToken(self: *const Lexer, token_type: TokenType) Token {
        const token_slice = self.source[self.token_start..self.current];
        return .{
            .type = token_type,
            .length = token_slice.len,
            .line = self.line,
            .start = token_slice,
            .value = .{ .type = .null },
        };
    }

    fn identifier(self: *Lexer) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) {
            _ = self.advance();
        }

        const text = self.source[self.start..self.current];
        return self.makeToken(identifierType(text));
    }

    pub fn nextToken(self: *Lexer) Token {
        self.skipWhiteSpace();
        self.start = self.current;

        if (self.isAtEnd()) self.makeToken(.eof);

        const c = self.advance();

        if (isAlpha(c)) {
            return self.identifier();
        }
    }
};
