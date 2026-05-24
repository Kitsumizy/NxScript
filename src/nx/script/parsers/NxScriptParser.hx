package nx.script.parsers;

import nx.script.AST.StmtWithPos;
import nx.script.Parser;
import nx.script.Tokenizer;

/**
 * Default NxScript parser frontend.
 */
class NxScriptParser implements IScriptParser {
	public function new() {}

	public function parse(source:String, strictMode:Bool):Array<StmtWithPos> {
		var tokenizer = new Tokenizer();
		tokenizer.init(source);
		var tokens = tokenizer.tokenize();
		var parser = new Parser(tokens, strictMode);
		return parser.parse();
	}
}
