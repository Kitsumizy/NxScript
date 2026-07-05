package nx.parser;


import nx.parser.Program;
import nx.script.NxManager;
import nx.lexer.TokenStream;
import nx.lexer.Token;
import nx.lexer.TokenType;

class Parser<K> {
    public var parserTime(default, null):Float = 0;
    public final tokens:TokenStream<K>;

    private var current(get, never):Int;
    final private function get_current():Int {
        return tokens.position;
    }

    public function new(tokens:TokenStream<K>) {
        this.tokens = tokens;
    }

    /**
     * Implemented by every language-specific parser. Should return the root node of the AST.
     */
    public function parse():Program {
        throw "Parser.parse() not implemented.";
    }

    inline function isAtEnd():Bool {
        return peek().type == EOF;
    }

    inline function peek(offset:Int = 0):Token<K> {
       return tokens.peek(offset);
    }

    inline function previous():Token<K> {
        return tokens.peek(-1);
    }

    inline function advance():Token<K> {
        if (!isAtEnd())
            return tokens.next();

        return previous();
    }

    inline function check(type:TokenType<K>):Bool {
        return peek().type == type;
    }

    inline function match(type:TokenType<K>):Bool {
        if (!check(type))
            return false;

        advance();
        return true;
    }

    final function expect(type:TokenType<K>, message:String):Token<K> {
        if (check(type))
            return advance();

        NxManager.onException.emit(peek().error(message));
        return null;
    }
    inline function matchKeyword(keyword:K):Bool {
    switch (peek().type) {
        case Keyword(k) if (k == keyword):
            advance();
            return true;

        default:
            return false;
    }
}
}