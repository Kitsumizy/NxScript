package;

import nx.script.Interpreter;
import nx.script.parsers.HaxeScriptParser;
import nx.script.parsers.NxScriptParser;

class HaxeParser {
	static function main() {
		trace("========================================");
		trace("HAXE PARSER TESTS");
		trace("========================================\n");

		var interp = new Interpreter();
		interp.parser = new HaxeScriptParser();

		assert(interp.runDynamic('function add(a, b) { return a + b }\nadd(10, 20)') == 30, "function keyword");
		assert(interp.runDynamic('func add(a, b) { return a + b }\nadd(3, 4)') == 7, "func keyword compatibility");
		assert(interp.runDynamic('function choose(n) {\n\tif (n > 0) return "pos"\n\telseif (n < 0) return "neg"\n\telse return "zero"\n}\nchoose(-1)') == "neg",
			"elseif alias");
		assert(interp.runDynamic('var x = true\nif (x) "yes" else "no"') == "yes", "truthy control flow");
		assert(interp.runDynamic('switch (2) { case 1, 3: "one"\ncase 2 | 4: "two"\ndefault: "other" }') == "two", "switch haxe-style cases");
		assert(interp.runDynamic('match 2 { case 2 => "two" }') == "two", "match compatibility");
		assertThrows(function() interp.runDynamic('switch (2) { case 2 => "two" }'), "switch arrow forbidden");

		var nx = new Interpreter();
		nx.parser = new NxScriptParser();
		assert(nx.runDynamic('class Abc\n{\n}\n"ok"') == "ok", "nx class newline brace");
		assert(nx.runDynamic('func add(a,b)\n{\n\treturn a+b\n}\nadd(2,3)') == 5, "nx function newline brace");
		assert(nx.runDynamic('var sum=0\nfor (i in 0...3) sum=sum+i\nsum') == 3, "nx for in range");
		assert(nx.runDynamic('var arr=[2,3,4]\nvar sum=0\nfor (i in arr) sum=sum+i\nsum') == 9, "nx for in array");
		assert(nx.runDynamic('var arr=[2,3,4]\nvar v=0\nfor (i in [arr]) v=i[1]\nv') == 3, "nx for in [arr]");

		assert(interp.runDynamic('class Abc\n{\n}\n"ok"') == "ok", "haxe class newline brace");
		assert(interp.runDynamic('function add(a,b)\n{\n\treturn a+b\n}\nadd(2,3)') == 5, "haxe function newline brace");
		assert(interp.runDynamic('var sum=0\nfor (i in 0...3) sum=sum+i\nsum') == 3, "haxe for in range");
		assert(interp.runDynamic('var sum=0\nfor (i in [2,3,4]) sum=sum+i\nsum') == 9, "haxe for in array literal");
		assert(interp.runDynamic('var arr=[2,3,4]\nvar v=0\nfor (i in [arr]) v=i[1]\nv') == 3, "haxe for in [arr]");

		trace("\n========================================");
		trace("ALL HAXE PARSER TESTS PASSED!");
		trace("========================================");

		Sys.exit(0);
	}

	static function assert(condition:Bool, message:String) {
		if (!condition) {
			throw 'Assertion failed: $message';
		}
		trace('✓ $message');
	}

	static function assertThrows(fn:Void->Void, message:String) {
		var thrown = false;
		try {
			fn();
		} catch (_:Dynamic) {
			thrown = true;
		}
		assert(thrown, message);
	}
}
