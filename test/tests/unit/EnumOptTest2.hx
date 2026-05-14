package unit;

package;

import nx.script.Interpreter;

class EnumOptTest2 {
	static function main() {
		var interp = new Interpreter();
		interp.optimize = true;
		
		// Test 1: Direct access
		try {
			var result = interp.runDynamic('enum Color{Red,Green,Blue}\nvar c=Color.Green\nc.variant');
			trace("Test 1 (direct): " + result);
		} catch (e:Dynamic) {
			trace("Test 1 ERROR: " + e);
		}
		
		// Test 2: String access
		try {
			var result = interp.runDynamic('enum Color{Red,Green,Blue}\nvar c=Color["Green"]\nc.variant');
			trace("Test 2 (string): " + result);
		} catch (e:Dynamic) {
			trace("Test 2 ERROR: " + e);
		}
		
		// Test 3: Without optimizations
		interp.optimize = false;
		try {
			var result = interp.runDynamic('enum Color{Red,Green,Blue}\nvar c=Color["Green"]\nc.variant');
			trace("Test 3 (no opt): " + result);
		} catch (e:Dynamic) {
			trace("Test 3 ERROR: " + e);
		}
	}
}
