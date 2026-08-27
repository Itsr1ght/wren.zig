const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;

const Parser = struct {
    lexer: Lexer,
    current: Token,
    previous: Token,

    had_error: bool,
    panic_mode: bool,
};
