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
    left_brace, // {
    right_brace, // }
    left_square_bracket, // [
    right_square_bracket, // ]
    dot, // .
    bang, // !
    bangeql, // !=
    tilde, // ~
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
    caret, // ^
    equal, // =
    equalequal, // ==
    notequal, // !=
    amp, // &
    ampamp, // &&
    pipe, // |
    pipepipe, // ||
    questionmark, // ?
    colon, // :
    comma, // ,
    doublequote, // "
    // Types
    identifier,
    number,
    string,
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

fn makeToken(self: *Self, token_type: TokenType, start: usize) Token {
    return .{
        .token_type = token_type,
        .start = self.data.ptr + start,
        .length = self.pos - start,
        .line = self.line,
    };
}

pub fn nextToken(self: *Self) !Token {
    self.skipWhiteSpace();

    const start = self.pos;

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
        '+' => {
            _ = self.advance();
            return self.makeToken(.plus, start);
        },
        '-' => {
            _ = self.advance();
            return self.makeToken(.minus, start);
        },
        '*' => {
            _ = self.advance();
            return self.makeToken(.star, start);
        },
        '/' => {
            _ = self.advance();

            if (self.peek() == '/') {
                while (self.peek() != '\n' and !self.isAtEnd()) {
                    _ = self.advance();
                }
                return self.nextToken();
            }

            if (self.peek() == '*') {
                _ = self.advance();
                var depth: usize = 1;

                while (depth > 0 and !self.isAtEnd()) {
                    if (self.peek() == '/' and self.peekNext() == '*') {
                        _ = self.advance();
                        _ = self.advance();
                        depth += 1;
                    } else if (self.peek() == '*' and self.peekNext() == '/') {
                        _ = self.advance();
                        _ = self.advance();
                        depth -= 1;
                    } else {
                        if (self.peek() == '\n') self.line += 1;
                        _ = self.advance();
                    }
                }

                if (depth > 0) {
                    return error.UntermicatedComments;
                }

                return self.nextToken();
            }

            return self.makeToken(.slash, start);
        },

        '{' => {
            _ = self.advance();
            return self.makeToken(.left_brace, start);
        },

        '}' => {
            _ = self.advance();
            return self.makeToken(.right_brace, start);
        },

        '(' => {
            _ = self.advance();
            return self.makeToken(.left_bracket, start);
        },

        ')' => {
            _ = self.advance();
            return self.makeToken(.right_bracket, start);
        },

        '[' => {
            _ = self.advance();
            return self.makeToken(.left_square_bracket, start);
        },

        ']' => {
            _ = self.advance();
            return self.makeToken(.right_square_bracket, start);
        },
        ',' => {
            _ = self.advance();
            return self.makeToken(.comma, start);
        },
        '%' => {
            _ = self.advance();
            return self.makeToken(.percent, start);
        },
        '~' => {
            _ = self.advance();
            return self.makeToken(.tilde, start);
        },
        ':' => {
            _ = self.advance();
            return self.makeToken(.colon, start);
        },
        '!' => {
            _ = self.advance();
            if (self.peek() == '=') {
                _ = self.advance();
                return self.makeToken(.bangeql, start);
            }
            return self.makeToken(.bang, start);
        },
        '&' => {
            _ = self.advance();
            if (self.peek() == '&') {
                _ = self.advance();
                return self.makeToken(.ampamp, start);
            }
            return self.makeToken(.amp, start);
        },
        '|' => {
            _ = self.advance();
            if (self.peek() == '|') {
                _ = self.advance();
                return self.makeToken(.pipepipe, start);
            }
            return self.makeToken(.pipe, start);
        },

        '=' => {
            _ = self.advance();
            if (self.peek() == '=') {
                _ = self.advance();
                return self.makeToken(.equalequal, start);
            }
            return self.makeToken(.equal, start);
        },

        '.' => {
            _ = self.advance();
            if (self.peek() == '.') {
                _ = self.advance();
                if (self.peek() == '.') {
                    _ = self.advance();
                    return self.makeToken(.dotdotdot, start);
                }
                return self.makeToken(.dotdot, start);
            }
            return self.makeToken(.dot, start);
        },

        '>' => {
            _ = self.advance();
            if (self.peek() == '=') {
                _ = self.advance();
                return self.makeToken(.greater_than_equal, start);
            }
            return self.makeToken(.greater_than, start);
        },

        '<' => {
            _ = self.advance();
            if (self.peek() == '=') {
                _ = self.advance();
                return self.makeToken(.less_than_equal, start);
            }
            return self.makeToken(.less_than, start);
        },

        else => {
            if (isAlpha(c)) return self.identifier();
            if (isDigit(c)) return self.number();
            return error.UnHandledCharacter;
        },
    }
}

const std = @import("std");

test "Tokenizing a Int" {
    var lexer = Self.init("222");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(TokenType.number, token.token_type);
    try std.testing.expectEqualStrings("222", token.start[0..token.length]);
}

test "Tokenizing a Float" {
    var lexer = Self.init("3.14");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(TokenType.number, token.token_type);
    try std.testing.expectEqualStrings("3.14", token.start[0..token.length]);
}

test "Tokenizing a String" {
    var lexer = Self.init("\"hello\"");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(TokenType.string, token.token_type);
    try std.testing.expectEqualStrings("hello", token.start[0..token.length]);
}

test "Tokenizing a multi-line String" {
    var lexer = Self.init(
        \\"
        \\ Snap back to reality
        \\ ope, there goes gravity
        \\"
    );
    const token = try lexer.nextToken();

    try std.testing.expectEqual(TokenType.string, token.token_type);
    try std.testing.expectEqualStrings(
        \\
        \\ Snap back to reality
        \\ ope, there goes gravity
        \\
    , token.start[0..token.length]);
}

test "Tokenizing a while" {
    var lexer = Self.init("while");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(TokenType.@"while", token.token_type);
}

test "Tokenizing a identifier" {
    var lexer = Self.init("hello_world");
    const token = try lexer.nextToken();

    try std.testing.expectEqual(TokenType.identifier, token.token_type);
    try std.testing.expectEqualStrings("hello_world", token.start[0..token.length]);
}

test "Tokenzine the single-line comment" {
    var lexer = Self.init(
        \\//Hello World this is comment
        \\var
    );

    const token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.@"var", token.token_type);
}

test "Tokenzing the entire block" {
    var lexer = Self.init("var hello = \"Hello World\"");

    var token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.@"var", token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.identifier, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.equal, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.string, token.token_type);
}

test "Tokenzing the Number block" {
    var lexer = Self.init("(1 * 2) * (3 + 4) / (8 - 2)");

    var token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.left_bracket, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.number, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.star, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.number, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.right_bracket, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.star, token.token_type);
}

test "Tokenizing the Condition" {
    var lexer = Self.init("if((3 * 2) >= 2 )");

    var token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.@"if", token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.left_bracket, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.left_bracket, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.number, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.star, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.number, token.token_type);

    token = try lexer.nextToken();
    try std.testing.expectEqual(TokenType.right_bracket, token.token_type);
}
