package;

import nx.script.Interpreter;

class Issue22Test {
	static function main() {
		trace("Testing Issue #22: Anonymous Functions Fail to Parse");
		trace("=====================================================");
		
		var interp = new Interpreter();
		
		try {
			interp.runDynamic("
				var result = function(x) { return x + 1; };
				trace('result : ' + result(5));
				// should print 'result : 6';
			");
			trace("SUCCESS: Anonymous function parsed and executed correctly!");
		} catch (e:Dynamic) {
			trace("FAILED: " + e);
		}
	}
}
