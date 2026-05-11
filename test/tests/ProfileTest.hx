package;

import nx.script.Interpreter;

class ProfileTest {
	static function main() {
		var interp = new Interpreter();
		
		// Run some code to generate profile data
		interp.runDynamic("
			var sum = 0;
			for (i in 0...100) {
				sum = sum + i;
			}
			
			function add(a, b) { return a + b; }
			var result = add(5, 3);
			
			class Test {
				var x = 10;
				func getX() { return this.x; }
			}
			var t = new Test();
			t.getX();
		");
		
		// Print profiling report
		interp.vm.printProfileReport();
	}
}
