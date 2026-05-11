package;

import nx.script.Interpreter;

class Issue21Test {
	static function main() {
		trace("Testing Issue #21: Default Function Arguments");
		trace("==============================================");
		
		var interp = new Interpreter();
		
		// Test 1: Function with default argument - call without argument
		try {
			var result = interp.runDynamic("
				function test(a = 1) {
					return a;
				}
				test();
			");
			if (result == 1) {
				trace("✓ Test 1 PASSED: test() with default a=1 returns 1");
			} else {
				trace("✗ Test 1 FAILED: Expected 1, got " + result);
			}
		} catch (e:Dynamic) {
			trace("✗ Test 1 FAILED: " + e);
		}
		
		// Test 2: Function with default argument - call with argument
		try {
			var result = interp.runDynamic("
				function test2(a = 1) {
					return a;
				}
				test2(5);
			");
			if (result == 5) {
				trace("✓ Test 2 PASSED: test2(5) returns 5");
			} else {
				trace("✗ Test 2 FAILED: Expected 5, got " + result);
			}
		} catch (e:Dynamic) {
			trace("✗ Test 2 FAILED: " + e);
		}
		
		// Test 3: Multiple parameters with mixed defaults
		try {
			var result = interp.runDynamic("
				function test3(a, b = 10, c = 20) {
					return a + b + c;
				}
				test3(1);
			");
			if (result == 31) {
				trace("✓ Test 3 PASSED: test3(1) with defaults b=10, c=20 returns 31");
			} else {
				trace("✗ Test 3 FAILED: Expected 31, got " + result);
			}
		} catch (e:Dynamic) {
			trace("✗ Test 3 FAILED: " + e);
		}
		
		// Test 4: Call with partial arguments
		try {
			var result = interp.runDynamic("
				function test4(a, b = 10, c = 20) {
					return a + b + c;
				}
				test4(1, 2);
			");
			if (result == 23) {
				trace("✓ Test 4 PASSED: test4(1, 2) returns 23");
			} else {
				trace("✗ Test 4 FAILED: Expected 23, got " + result);
			}
		} catch (e:Dynamic) {
			trace("✗ Test 4 FAILED: " + e);
		}
		
		// Test 5: Example from issue #21
		try {
			interp.runDynamic("
				function testInvalid(a = 1) {
					trace('a : ' + a);
				}
				testInvalid();
			");
			trace("✓ Test 5 PASSED: Issue #21 example works");
		} catch (e:Dynamic) {
			trace("✗ Test 5 FAILED: " + e);
		}
		
		trace("\n==============================================");
		trace("Issue #21 tests completed");
	}
}
