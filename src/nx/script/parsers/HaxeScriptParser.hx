package nx.script.parsers;

import nx.script.AST.StmtWithPos;
import nx.script.Parser;

/**
 * Haxe-flavoured parser frontend.
 *
 * This reuses the same core parser pipeline as NxScript, but keeps its own
 * tokenizer class so the frontend stays isolated.
 */
class HaxeScriptParser implements IScriptParser {
	public function new() {}

	public function parse(source:String, strictMode:Bool):Array<StmtWithPos> {
		var tokenizer = new HaxeScriptTokenizer(source);
		var tokens = tokenizer.tokenize();
		var parser = new Parser(tokens, strictMode);
		return parser.parse();
	}
}
