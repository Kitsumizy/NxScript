package nx.lexer;

import nx.common.NxError;
import nx.common.NxPosition;

class Token<K> {
    public final type:TokenType<K>;
    public final lexeme:String;
    public final position:NxPosition;

    public function new(
        type:TokenType<K>,
        lexeme:String,
        position:NxPosition
    ) {
        this.type = type;
        this.lexeme = lexeme;
        this.position = position;
    }
    public function toString():String {
        if (type == TokenType.String)
            return 'Token(type=${type}, lexeme=${lexeme}, position=${position})';
        return 'Token(type=${type}, lexeme="${lexeme}", position=${position})';
    }
    public function error(message:String):NxError {
        return new NxError(message, position);
    }
}