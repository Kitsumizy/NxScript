package integration;

import nx.script.Interpreter;

/**
 * Integration test for parent scope feature.
 * Tests that scripts can read/write fields from a Haxe parent object.
 */
class ParentScopeTest {
	public var a:Int = 0;
	var callFnCalled:Bool = false;
	var scopeTestCalled:Bool = false;

	public function new() {
		var interp = new Interpreter();
		interp.parent = this;

		interp.runDynamic('
            a = 5;
            trace("a = " + a);
            call_fn_test();
            scope_test();
        ');

		trace('Test: a = ${a}');
		
		// Test 1: Variable assignment to parent field
		if (a != 5) {
			trace('FAIL: Variable assignment - expected 5, got ${a}');
		} else {
			trace('PASS: Variable assignment');
		}

		// Test 2: Function call to parent method (call_fn_test)
		if (!callFnCalled) {
			trace('FAIL: call_fn_test() was not called');
		} else {
			trace('PASS: call_fn_test()');
		}

		// Test 3: Function call to parent method (scope_test)
		if (!scopeTestCalled) {
			trace('FAIL: scope_test() was not called');
		} else {
			trace('PASS: scope_test()');
		}
	}

	function call_fn_test() {
		trace('Called call_fn_test() from parent');
		callFnCalled = true;
	}

	function scope_test() {
		trace('Called scope_test() from parent');
		scopeTestCalled = true;
	}

	public static function main() {
		new ParentScopeTest();
	}
}