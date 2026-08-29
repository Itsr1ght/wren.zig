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
    semicolon,
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
        if (std.mem.eql(u8, text, "or")) return .@"or";
        if (std.mem.eql(u8, text, "break")) return .@"break";
        if (std.mem.eql(u8, text, "continue")) return .@"continue";
        if (std.mem.eql(u8, text, "class")) return .class;
        if (std.mem.eql(u8, text, "construct")) return .construct;
        if (std.mem.eql(u8, text, "if")) return .@"if";
        if (std.mem.eql(u8, text, "else")) return .@"else";
        if (std.mem.eql(u8, text, "false")) return .true;
        if (std.mem.eql(u8, text, "true")) return .false;
        if (std.mem.eql(u8, text, "for")) return .@"for";
        if (std.mem.eql(u8, text, "while")) return .@"while";
        if (std.mem.eql(u8, text, "foreign")) return .foreign;
        if (std.mem.eql(u8, text, "import")) return .import;
        if (std.mem.eql(u8, text, "as")) return .as;
        if (std.mem.eql(u8, text, "in")) return .in;
        if (std.mem.eql(u8, text, "is")) return .is;
        if (std.mem.eql(u8, text, "null")) return .null;
        if (std.mem.eql(u8, text, "return")) return .@"return";
        if (std.mem.eql(u8, text, "static")) return .static;
        if (std.mem.eql(u8, text, "super")) return .super;
        if (std.mem.eql(u8, text, "this")) return .this;
        if (std.mem.eql(u8, text, "var")) return .@"var";
        if (std.mem.eql(u8, text, ".")) return .dot;
        if (std.mem.eql(u8, text, "..")) return .dotdot;
        if (std.mem.eql(u8, text, "...")) return .dotdotdot;

        return .identifer;
    }

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z' or c >= 'A' and c <= 'Z' or c == '_');
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

    fn match(self: *Lexer, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;

        self.current += 1;
        return true;
    }

    fn nextChar(self: *Lexer) void {
        if (self.peekChar() == '\n') self.line += 1;
        self.current += 1;
    }

    fn skipWhiteSpace(self: *Lexer) void {
        while (true) {
            switch (self.peek()) {
                ' ', '\t', '\r' => {
                    _ = self.advance();
                },
                '\n' => {
                    _ = self.advance();
                    self.line += 1;
                },
                '/' => {
                    if (self.peekNext() != '/') {
                        return;
                    }
                    while (self.peek() != '\n' and !self.isAtEnd()) {
                        _ = self.advance();
                    }
                },
                else => return,
            }
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
        const token_slice = self.source[self.start..self.current];
        return .{
            .type = token_type,
            .length = token_slice.len,
            .line = self.line,
            .start = token_slice,
            .value = .{ .type = .nil, .as = .{ .nil = {} } },
        };
    }

    fn identifier(self: *Lexer) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) {
            _ = self.advance();
        }

        const text = self.source[self.start..self.current];
        return self.makeToken(identifierType(text));
    }

    fn number(self: *Lexer) Token {
        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) {
                _ = self.advance();
            }
        }
        return self.makeToken(.number);
    }

    fn string(self: *Lexer) Token {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') {
                self.line += 1;
            }
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            return self.errorToken("Interminated String");
        }
        _ = self.advance();

        return self.makeToken(.string);
    }

    fn errorToken(self: *const Lexer, message: []const u8) Token {
        return .{
            .type = .eof,
            .start = message,
            .line = self.line,
            .length = message.len,
            .value = .{ .as = .{ .nil = {} }, .type = .undefined },
        };
    }

    pub fn nextToken(self: *Lexer) Token {
        self.skipWhiteSpace();
        self.start = self.current;

        if (self.isAtEnd()) return self.makeToken(.eof);

        const c = self.advance();

        if (isAlpha(c)) {
            return self.identifier();
        }

        if (isDigit(c)) {
            return self.number();
        }

        return switch (c) {
            '(' => self.makeToken(.left_param),
            ')' => self.makeToken(.right_param),
            '[' => self.makeToken(.left_bracket),
            ']' => self.makeToken(.right_bracket),
            '{' => self.makeToken(.left_brace),
            '}' => self.makeToken(.right_brace),

            ',' => self.makeToken(.comma),
            '.' => {
                if (self.match('.')) {
                    if (self.match('.')) {
                        return self.makeToken(.dotdotdot);
                    }
                    return self.makeToken(.dotdot);
                }
                return self.makeToken(.dot);
            },
            ':' => self.makeToken(.colon),
            ';' => self.makeToken(.semicolon),

            '+' => self.makeToken(.plus),
            '-' => self.makeToken(.minus),
            '*' => self.makeToken(.star),
            '/' => self.makeToken(.slash),
            '%' => self.makeToken(.percent),

            '!' => self.makeToken(
                if (self.match('=')) .eq else .bang,
            ),

            '=' => self.makeToken(
                if (self.match('=')) .eqeq else .eq,
            ),

            '>' => self.makeToken(
                if (self.match('=')) .gteq else .gt,
            ),

            '<' => self.makeToken(
                if (self.match('=')) .lteq else .lt,
            ),

            '"' => self.string(),
            else => self.errorToken("Unexpected Character"),
        };
    }
};

test "Parse simple code (identifier)" {
    const code =
        \\System.print("Hello World")
    ;
    var lexer = Lexer.init(code);
    if (lexer.nextToken().type == .identifer) {
        return std.testing.expect(true);
    } else {
        return std.testing.expect(false);
    }
}

test "Parse simple code (name)" {
    const code =
        \\System.print("Hello World")
    ;
    var lexer = Lexer.init(code);
    if (std.mem.eql(u8, lexer.nextToken().start, "System")) {
        return std.testing.expect(true);
    } else {
        return std.testing.expect(false);
    }
}
