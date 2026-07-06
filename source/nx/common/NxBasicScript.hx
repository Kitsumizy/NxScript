package nx.common;

import nx.ir.IRBuilder;
import nx.ir.IRProgram;
import nx.lexer.Lexer;
import nx.lexer.TokenStream;
import nx.parser.Parser;
import nx.parser.Program;
import nx.semantic.SemanticAnalyzer;
import nx.semantic.SemanticProgram;

class NxBasicScript<TKeyword> {
	public var source(default, null):NxSource;

	public var tokens(default, null):TokenStream<TKeyword>;
	public var program(default, null):Program;
	public var semantic(default, null):SemanticProgram;
	public var ir(default, null):IRProgram;

	public function new(source:SourceContentOrPath) {
		this.source = new NxSource(source);
		compile();
	}

	public function compile():Void {
		var lexer = createLexer(source);

		tokens = lexer.lex();

		var parser = createParser(tokens);

		program = parser.parse();

		var analyzer = createSemanticAnalyzer();

		semantic = analyzer.analyze(program);

		if (semantic.diagnostics.length == 0)
			ir = createIRBuilder().build(semantic);
		else
			ir = null;
		#if NX_VERBOSE
		trace("Source:");
		trace(source.content);
		trace("Tokens:");
		for (token in tokens)
			trace(token.toString());
		trace("Diagnostics:");
		for (diagnostic in semantic.diagnostics)
			trace(diagnostic.message);
		if (semantic.diagnostics.length == 0)
			trace("No diagnostics.");
		trace("IR:");
		if (ir != null)
			trace(ir.toString());
		#end
	}

	// ---------- Factories ----------

	function createLexer(source:NxSource):Lexer<TKeyword> {
		throw "createLexer() not implemented.";
	}

	function createParser(tokens:TokenStream<TKeyword>):Parser<TKeyword> {
		throw "createParser() not implemented.";
	}

	function createSemanticAnalyzer():SemanticAnalyzer {
		return new SemanticAnalyzer();
	}

	function createIRBuilder():IRBuilder {
		return new IRBuilder();
	}
}
