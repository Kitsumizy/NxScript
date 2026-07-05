package nx.lexer;

class Lexer<KeywordType> {
    /**
    * The time taken to lex the input, in seconds.
    **/
    public var lexTime(default, null):Float = 0;
    /**
    * The source code being lexed.
    **/
    public var source(default,null):NxSource;

    var index:Int;
    var line:Int;
    var column:Int;

    public function new(source:NxSource) {
        this.source = source;

        index = 0;
        line = 1;
        column = 1;
    }
    /**
    * Lexes the input source code and returns an array of tokens.
    * This method should be overridden by subclasses to provide specific lexing logic.
    **/
    public function lex():TokenStream<KeywordType> {
        throw "Not implemented";
    }

    inline function eof():Bool
        return index >= source.length;

    inline function peek(offset = 0):String {
        if (index + offset >= source.length)
            return "EOF";

        return source.charAt(index + offset);
    }
    final function advance():String {
        var c = peek();

        index++;

        if (c == "\n") {
            line++;
            column = 1;
        } else {
            column++;
        }

        return c;
    }
    inline function isDigit(c:String):Bool {
        return c.length == 1 && c.charCodeAt(0) >= 48 && c.charCodeAt(0) <= 57;
    }

    inline function isAlpha(c:String):Bool {
        return c.length == 1 && (
            (c.charCodeAt(0) >= 65 && c.charCodeAt(0) <= 90) ||
            (c.charCodeAt(0) >= 97 && c.charCodeAt(0) <= 122) ||
            c == "_"
        );
    }

    inline function isAlphaNumeric(c:String):Bool {
        return isAlpha(c) || isDigit(c);
    }
}