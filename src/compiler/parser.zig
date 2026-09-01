const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;

const ParseError = error{
    ExpectedExpression,
    UnexpectedToken,
    ExpectedRightParen,
};

const Precedence = enum(u8) {
    none,
    assignment,
    conditional,
    logical_or,
    logical_and,
    equality,
    comparison,
    term,
    factor,
    unary,
    call,
    primary,

    fn precedence(token: TokenType) Precedence {
        return switch (token) {
            .pipepipe => .logical_or,
            .ampamp => .logical_and,

            .eqeq, .bangeq => .equality,

            .lt, .gt, .lteq, .gteq => .comparison,

            .plus, .minus => .term,

            .star, .slash, .percent => .factor,

            .left_param, .dot => .call,

            else => .none,
        };
    }

    fn value(self: Precedence) u8 {
        return @intFromEnum(self);
    }

    fn next(self: Precedence) Precedence {
        return switch (self) {
            .none => .none,
            .assignment => .conditional,
            .conditional => .logical_or,
            .logical_or => .logical_and,
            .logical_and => .equality,
            .equality => .comparison,
            .comparison => .term,
            .term => .factor,
            .factor => .unary,
            .unary => .call,
            .call => .primary,
            .primary => .primary,
        };
    }
};

pub const Parser = struct {
    lexer: *Lexer,

    current: Token,
    previous: Token,

    had_error: bool = false,
    panic_mode: bool = false,

    pub fn init(lexer: *Lexer) Parser {
        var parser: Parser = .{
            .lexer = lexer,
            .current = undefined,
            .previous = undefined,
        };

        parser.advance();

        return parser;
    }

    fn advance(self: *Parser) void {
        self.previous = self.current;
        self.current = self.lexer.nextToken();
    }

    fn check(self: *const Parser, token_type: TokenType) bool {
        return self.current.type == token_type;
    }

    fn consume(
        self: *Parser,
        token_type: TokenType,
    ) ParseError!void {
        if (!self.check(token_type)) {
            return error.UnexpectedToken;
        }

        self.advance();
    }

    fn expression(self: *Parser) ParseError!void {
        try self.parsePrecedence(.assignment);
    }

    fn parsePrecedence(
        self: *Parser,
        min_precedence: Precedence,
    ) ParseError!void {
        self.advance();

        try self.parsePrefix();

        while (min_precedence.value() <= Precedence.precedence(self.current.type).value()) {
            self.advance();
            try self.parseInfix();
        }
    }

    fn parsePrefix(self: *Parser) ParseError!void {
        switch (self.previous.type) {
            .number => self.number(),
            .string => self.string(),
            .identifier => self.identifier(),
            .left_param => try self.grouping(),

            .minus, .bang, .tilde => try self.unary(),

            else => return error.ExpectedExpression,
        }
    }

    fn parseInfix(self: *Parser) ParseError!void {
        switch (self.previous.type) {
            .plus,
            .minus,
            .star,
            .slash,
            .percent,
            => try self.binary(),

            .left_param => try self.call(),
            .dot => try self.property(),

            else => return error.UnexpectedToken,
        }
    }

    fn property(self: *Parser) ParseError!void {
        try self.consume(.identifier);
        std.debug.print("property: {s}\n", .{
            self.previous.start[0..@intCast(self.previous.length)],
        });
    }

    fn call(self: *Parser) ParseError!void {
        if (!self.check(.right_param)) {
            try self.expression();
            while (self.check(.comma)) {
                self.advance();
                try self.expression();
            }
        }
        try self.consume(.right_param);
        std.debug.print("call\n", .{});
    }

    fn unary(self: *Parser) ParseError!void {
        const operator = self.previous.type;
        try self.parsePrecedence(.unary);
        std.debug.print("unary: {any}\n", .{operator});
    }

    fn binary(self: *Parser) ParseError!void {
        const operator = self.previous.type;

        const precedence = Precedence.precedence(operator);
        const next_precedence = precedence.next();

        try self.parsePrecedence(next_precedence);
        std.debug.print("binary: {any}\n", .{operator});
    }

    fn number(self: *Parser) void {
        std.debug.print("number: {s}\n", .{
            self.previous.start[0..@intCast(self.previous.length)],
        });
    }

    fn string(self: *Parser) void {
        std.debug.print("string: {s}\n", .{
            self.previous.start[0..@intCast(self.previous.length)],
        });
    }

    fn identifier(self: *Parser) void {
        std.debug.print("identifier: {s}\n", .{
            self.previous.start[0..@intCast(self.previous.length)],
        });
    }

    fn grouping(self: *Parser) ParseError!void {
        try self.expression();
        try self.consume(.right_param);
    }

    pub fn parse(self: *Parser) ParseError!void {
        try self.expression();
        try self.consume(.eof);
    }
};

test "Parser basic binary" {
    var lexer = Lexer.init("(1 * 4) - (1 + 2)");
    var parser = Parser.init(&lexer);

    try parser.parse();
}

test "Parser basic unary" {
    var lexer = Lexer.init("-10");
    var parser = Parser.init(&lexer);

    try parser.parse();
}

test "Parse simple function" {
    var lexer = Lexer.init("foo()");
    var parser = Parser.init(&lexer);

    try parser.parse();
}

test "Parse function with param" {
    var lexer = Lexer.init("foo(1, 2)");
    var parser = Parser.init(&lexer);

    try parser.parse();
}

test "Parse function with param that containing expression" {
    var lexer = Lexer.init("foo(1, 2 * 3, 5, 6)");
    var parser = Parser.init(&lexer);

    try parser.parse();
}

test "call function using dot" {
    var lexer = Lexer.init("System.print(\"Hello World\")");
    var parser = Parser.init(&lexer);

    try parser.parse();
}
