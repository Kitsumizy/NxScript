package nx.lexer;

import nx.script.NxManager;

class TokenStream<KeywordType> {
    public var tokens:Array<Token<KeywordType>>;
    public var position:Int;
    
    public function new(tokens:Array<Token<KeywordType>>) {
        this.tokens = tokens;
        this.position = 0;
    }
    
    public function next():Token<KeywordType> {
        if (position < tokens.length) {
            return tokens[position++];
        } else {
            return null;
        }
    }
    
    public function peek(offset:Int = 0):Token<KeywordType> {
        var index = position + offset;
        if (index < tokens.length) {
            return tokens[index];
        } else {
            return null;
        }
    }
    public function eof():Bool {
        return position >= tokens.length;
    }
    public function hasNext():Bool {
        return eof() ;
    }
    public function match(type:TokenType<KeywordType>):Bool {
        var token = peek();
        if (token != null && token.type == type) {
            next();
            return true;
        }
        return false;
    }
    public function expect(type:TokenType<KeywordType>):Token<KeywordType> {
        var token = next();
        if (token == null || token.type != type) {
            // throw "Expected token of type ${type}, but got ${token}";
            NxManager.onException.emit(new NxException('Expected token of type ${type}, but got ${token}', token.position));
        }
        return token;
    }
    public function toString():String {
        var lines:Array<String> = ["TokenStream"];

        for (i in 0...tokens.length) {
            var prefix = i == 0 ? " ├─ " : " ├─ ";
            var marker = i == position ? ">" : " ";
            lines.push('${prefix}${marker} [${i}] ${tokens[i]}');
        }

        lines.push(' └─ cursor: ${position} ${eof() ? "(EOF)" : "(" + peek().toString() + ")"}');
        return lines.join("\n");
    }
}