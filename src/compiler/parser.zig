const std = @import("std");

const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;

pub const Parser = struct {
    lexer: *Lexer,
    current: Token,
    previous: Token,

    had_error: bool,
    panic_mode: bool,

    pub fn init(lexer: *Lexer) Parser {
        var parser: Parser = .{
            .lexer = lexer,
            .current = undefined,
            .previous = undefined,
            .had_error = false,
            .panic_mode = false,
        };
        parser.advance();
        return parser;
    }

    fn check(self: *Parser, expected: TokenType) bool {
        return self.current.type == expected;
    }

    fn consume(self: *Parser, expected: TokenType) !void {
        if (self.current.type != expected) {
            return error.UnexpectedToken;
        }
        self.advance();
    }

    fn advance(self: *Parser) void {
        self.previous = self.current;
        self.current = self.lexer.nextToken();
    }

    fn number(self: *Parser) !void {
        self.advance();
    }

    fn string(self: *Parser) !void {
        self.advance();
    }

    fn identifier(self: *Parser) !void {
        self.advance();
    }

    fn grouping(self: *Parser) !void {
        self.advance();
    }

    fn expression(self: *Parser) !void {
        return switch (self.current.type) {
            .number => self.number(),
            .string => self.string(),
            .identifer => self.identifier(),
            .left_param => self.grouping(),
            else => self.advance(),
        };
    }

    pub fn parse(self: *Parser) !void {
        while (!self.check(.eof)) {
            try self.expression();
        }
    }
};

test "Parser basic" {
    var lexer = Lexer.init("1 66.66 69");
    var parser = Parser.init(&lexer);
    try parser.parse();
}
