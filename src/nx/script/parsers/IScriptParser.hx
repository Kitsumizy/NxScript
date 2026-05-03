package nx.script.parsers;

import nx.script.AST.StmtWithPos;

/**
 * Parser frontend contract.
 *
 * Different language frontends (NxScript, Haxe-like, etc.) should implement this
 * and return the canonical Nx AST used by Compiler.
 */
interface IScriptParser {
	public function parse(source:String, strictMode:Bool):Array<StmtWithPos>;
}
