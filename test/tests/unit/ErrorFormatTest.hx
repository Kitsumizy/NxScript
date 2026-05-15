package unit;


import nx.script.Interpreter;

class ErrorFormatTest {
	static function main() {
		trace("========================================");
		trace("ERROR FORMAT TESTS");
		trace("========================================\n");

		var interp = new Interpreter();

		trace("Test 1: Parse error pretty format");
		var parseMsg = captureError(function() {
			interp.run('ifx (true) {\n\tvar x = 1\n}', "examples/invalid_keyword.nx");
		});
		// Error message contains key info (formatted output goes to console separately)
		assertContains(parseMsg, "ifx", "Shows undefined variable name");
		assertContains(parseMsg, "examples/invalid_keyword.nx", "Shows script path");
		assertContains(parseMsg, "Undefined", "Shows error type");

		trace("\nTest 2: Runtime crash includes stack");
		var runtimeMsg = captureError(function() {
			interp.run('func boom() {\n\tvar x = 1 / 0\n}\nboom()', "examples/runtime_crash.nx");
		});
		// Check error message contains key runtime info
		assertContains(runtimeMsg, "boom", "Includes function name");
		assertContains(runtimeMsg, "examples/runtime_crash.nx", "Includes script path");
		assertContains(runtimeMsg, "runtime", "Indicates runtime error");

		trace("\nTest 3: Haxe-like script syntax works");
		var result = interp.runDynamic('function add(a:Int, b:Int) { return a + b; } var out:Int = add(20, 22); out;', "examples/hx_style.nx");
		assert(result == 42, "Haxe-like function/type/semicolon syntax runs");

		trace("\n========================================");
		trace("ALL ERROR FORMAT TESTS PASSED!");
		trace("========================================");
		Sys.exit(0);
	}

	static function captureError(fn:Void->Void):String {
		try {
			fn();
			throw "Expected an error but script did not fail";
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function assert(condition:Bool, message:String):Void {
		if (!condition)
			throw 'Assertion failed: ' + message;
		trace('✓ ' + message);
	}

	static function assertContains(haystack:String, needle:String, message:String):Void {
		assert(haystack.indexOf(needle) >= 0, message + ' (missing: ' + needle + ')');
	}
}
