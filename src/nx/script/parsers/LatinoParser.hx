package nx.script.parsers;

import nx.script.AST.StmtWithPos;
import nx.script.Interpreter;
import nx.script.Parser;

/**
 * Latino language parser - Spanish-based programming language.
 * 
 * Syntax features:
 * - variable x = 5
 * - funcion nombre() { }
 * - si (cond) { } sino { } fin
 * - mientras (cond) { } fin
 * - desde (i=0; i < 10; i++) { } fin
 * - escribir("hola")
 * - leer()
 * - .. for string concatenation
 * 
 * Usage:
 * var interp = new Interpreter();
 * LatinoParser.registerBuiltins(interp);  // Register Latino builtins
 * interp.parser = new LatinoParser();
 * interp.run("escribir('hola')");
 */
class LatinoParser implements IScriptParser {
	public function new() {}

	public function parse(source:String, strictMode:Bool):Array<StmtWithPos> {
		var tokenizer = new LatinoTokenizer(source);
		var tokens = tokenizer.tokenize();
		var parser = new Parser(tokens, strictMode);
		return parser.parse();
	}

	/**
	 * Register Latino built-in functions (escribir, leer, tipo, longitud, rango, etc.)
	 * Call this after creating Interpreter, before running Latino code.
	 */
	public static function registerBuiltins(interp:Interpreter):Void {
		LatinoBuiltins.registerAll(interp);
	}
}
