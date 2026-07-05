package nx.lexer;

enum TokenType<KeywordType> {
    // Specials
    EOF;
    Invalid;

    // Literals
    Identifier;
    Number;
    String;

    // Symbols
    LeftParen;
    RightParen;
    LeftBrace;
    RightBrace;
    LeftBracket;
    RightBracket;

    Comma;
    Dot;
    Colon;
    Semicolon;

    // Operators
    Plus;
    Minus;
    Star;
    Slash;
    Percent;

    Equal;
    EqualEqual;

    Bang;
    BangEqual;

    Greater;
    GreaterEqual;

    Less;
    LessEqual;

    AndAnd;
    OrOr;

    PlusEqual;
    MinusEqual;
    StarEqual;
    SlashEqual;

    Arrow;

    // Keywords
    Keyword(key:KeywordType);

    IsThatAFuckingEmoji;
}