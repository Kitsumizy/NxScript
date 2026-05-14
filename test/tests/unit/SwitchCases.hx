package unit;

package;

import nx.script.Interpreter;

class SwitchCases {
	static function main() {
		trace("========================================");
		trace("SWITCH CASE TESTS");
		trace("========================================\n");

		var interp = new Interpreter();

		assert(interp.runDynamic('var x=2\nswitch (x){case 1,3:"one"\ncase 2|4:"two"\ndefault:"other"}') == "two", "value case");
		assert(interp.runDynamic('switch (99){case 1,2:"one"\ndefault:"other"}') == "other", "default case");
		assert(interp.runDynamic('var s=85\nswitch (s){case 90...100:"A"\ncase 80...89:"B"\ndefault:"F"}') == "B", "range case");
		assert(interp.runDynamic('switch (7){case 1:"one"\ncase n:n*10}') == 70, "binding case");
		assert(interp.runDynamic('switch (-5){case -5:"neg"\ndefault:"no"}') == "neg", "negative literal");
		assert(interp.runDynamic('switch (null){case null:"nil"\ndefault:"no"}') == "nil", "null literal");
		assert(interp.runDynamic('switch (true){case true:"yes"\ndefault:"no"}') == "yes", "bool literal");
		assert(interp.runDynamic('var r=0\nswitch (3){case 1:{r=100}\ncase 3:{var t=300\nr=t+33}\ndefault:{r=-1}}\nr') == 333, "block body");
		assert(interp.runDynamic('var c="attack"\nswitch (c){case "attack":"go"\ndefault:"no"}') == "go", "string case");
		assert(interp.runDynamic('switch ([10,20,30]){case [a,b]:a+b\ncase [a,b,c]:a+b+c\ndefault:0}') == 60, "array destructure");
		assert(interp.runDynamic('enum Color{Red,Green,Blue}\nvar c=Color["Green"]\nswitch (c){case Red:"r"\ncase Green:"g"\ncase Blue:"b"}') == "g",
			"enum variant");
		assert(interp.runDynamic('enum Reply{Ok(msg),Err(code)}\nvar r=Reply["Ok"]("hi")\nswitch (r){case Ok(msg):msg\ndefault:"no"}') == "hi", "enum payload");
		assert(interp.runDynamic('switch (2){case 1:"one"\ncase 2:{var nested="a"\nvar result="no"\nswitch (nested){case "a":result="nested"\ndefault:result="no"}\nresult}\ndefault:"no"}') == "nested",
			"nested switch");
		assert(interp.runDynamic('switch (1){case 1:"one"}') == "one", "no default");
		assertThrows(function() interp.runDynamic('switch (2){case 2=>"two"}'), "arrow syntax forbidden");

		trace("\n========================================");
		trace("ALL SWITCH CASE TESTS PASSED!");
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
