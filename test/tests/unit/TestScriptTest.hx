package unit;


import nx.script.parsers.HaxeScriptParser;
import nx.script.Interpreter;

class TestScriptTest {
	public static function main() {
		var er = new Interpreter(false, false);
		er.parser = new HaxeScriptParser();
		er.runFile('test/tests/script.hx');
	}
}
