const Tokentype = enum {
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
};

const Token = struct {
    token_type: Tokentype,
    start: [*]const u8,
    length: usize,
    line: usize,
};
