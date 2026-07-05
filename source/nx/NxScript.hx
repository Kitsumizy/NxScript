package nx;

import nx.common.NxBasicScript;
import nx.ir.IRBuilder;
import nx.lexer.Lexer;
import nx.lexer.TokenStream;
import nx.lexer.nxscript.NxKeyword;
import nx.lexer.nxscript.NxLexer;
import nx.parser.Parser;
import nx.parser.nxscript.NxParser;
import nx.semantic.SemanticAnalyzer;

class NxScript extends NxBasicScript<NxKeyword> {

    public function new(source:SourceContentOrPath) {
        super(source);
    }

    override function createLexer(source:NxSource):Lexer<NxKeyword> {
        return new NxLexer(source);
    }

    override function createParser(tokens:TokenStream<NxKeyword>):Parser<NxKeyword> {
        return new NxParser(tokens);
    }

    override function createSemanticAnalyzer():SemanticAnalyzer {
        var analyzer = new SemanticAnalyzer();
        // TODO: Register built-in functions, types, and other language features here.
        analyzer.registerBuiltins([
            "print",
            "println",
            "len",
            "type",
            "typeof",
            "is"
        ]);

        return analyzer;
    }

    override function createIRBuilder():IRBuilder {
        return new IRBuilder();
    }
}