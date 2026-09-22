const Lexer = @import("Lexer.zig");
const TokenType = Lexer.TokenType;
const Token = Lexer.Token;

const Self = @This();
lexer: *Lexer,
current: Token,

pub fn init(lexer: *Lexer) Self {
    return .{
        .lexer = lexer,
        .current = undefined,
    };
}
