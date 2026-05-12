package;

import nx.script.Interpreter;

class EnumOptTest {
	static function main() {
		var interp = new Interpreter();
		interp.optimize = true;
		
		try {
			var result = interp.runDynamic("
				enum Color {
					Red,
					Green,
					Blue
				}
				var c = Color.Green;
				c;
			");
			trace("SUCCESS: " + result);
		} catch (e:Dynamic) {
			trace("ERROR: " + e);
		}
	}
}
