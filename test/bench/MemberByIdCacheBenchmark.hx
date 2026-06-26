package;

import nx.script.Interpreter;
import nx.script.VM;
import Sys;

class MemberByIdCacheBenchmark {
	static var warmupDone = false;
	
	static function warmup() {
		if (warmupDone) return;
		// Warmup JIT
		var interp = new Interpreter();
		interp.runDynamic('var obj = { x: 1 }; for (i in 0...1000) obj.x;');
		warmupDone = true;
	}

	static function timeMemberAccess(label:String, interp:Interpreter, code:String, iterations:Int = 50000) {
		warmup();
		
		var t0 = Sys.time();
		for (i in 0...iterations) {
			interp.runDynamic(code);
		}
		var t1 = Sys.time();
		
		var ms = (t1 - t0) * 1000;
		var perOp = (ms / iterations) * 1000; // microseconds
		var opsPerSec = iterations / (ms / 1000);
		
		trace('$label:');
		trace('  Total: ${ms}ms');
		trace('  Per op: ${perOp}μs');
		trace('  Ops/sec: ${Math.round(opsPerSec)}');
		trace('');
		
		return perOp;
	}

	static function main() {
		trace("══════════════════════════════════════════════════");
		trace("MemberById Cache Performance Test");
		trace("══════════════════════════════════════════════════\n");
		
		// Test 1: Repeated access to same native object field
		trace("Test 1: Repeated native object field access");
		trace("─────────────────────────────────────────────");
		var interp1 = new Interpreter();
		interp1.runDynamic('var point = { x: 10, y: 20, z: 30 };');
		
		var time1 = timeMemberAccess("point.x (1st access - cache miss)", interp1, "point.x", 10000);
		var time2 = timeMemberAccess("point.x (subsequent - cache hit)", interp1, "point.x", 50000);
		
		trace('Speedup: ${Std.string(Std.int((time1 / time2) * 100) / 100)}x faster on cached access\n');
		
		// Test 2: Multiple different fields
		trace("Test 2: Multiple different fields (cache thrashing)");
		trace("────────────────────────────────────────────────────");
		var interp2 = new Interpreter();
		interp2.runDynamic('var obj = { a: 1, b: 2, c: 3, d: 4, e: 5 };');
		
		timeMemberAccess("obj.a", interp2, "obj.a", 20000);
		timeMemberAccess("obj.b", interp2, "obj.b", 20000);
		timeMemberAccess("obj.c", interp2, "obj.c", 20000);
		timeMemberAccess("obj.d", interp2, "obj.d", 20000);
		timeMemberAccess("obj.e", interp2, "obj.e", 20000);
		
		// Test 3: Method calls
		trace("Test 3: Native method calls");
		trace("─────────────────────────────────────────────────");
		var interp3 = new Interpreter();
		interp3.runDynamic('var arr = [1, 2, 3];');
		
		timeMemberAccess("arr.length", interp3, "arr.length", 30000);
		timeMemberAccess("arr.push()", interp3, "arr.push(1)", 20000);
		
		// Test 4: Chained access
		trace("Test 4: Chained member access");
		trace("─────────────────────────────────────────────────");
		var interp4 = new Interpreter();
		interp4.runDynamic('var deep = { a: { b: { c: { d: 42 } } } };');
		
		var timeChained = timeMemberAccess("deep.a.b.c.d", interp4, "deep.a.b.c.d", 20000);
		trace('Chained access is ${Std.string(Std.int((timeChained / time2) * 100) / 100)}x slower than single access\n');
		
		// Test 5: Script object vs Native object
		trace("Test 5: Script object vs Native object");
		trace("─────────────────────────────────────────────────");
		var interp5a = new Interpreter();
		interp5a.runDynamic('
			class ScriptPoint {
				var x = 10;
				var y = 20;
			}
			var p = new ScriptPoint();
		');
		
		var interp5b = new Interpreter();
		interp5b.runDynamic('var p = { x: 10, y: 20 };');
		
		var timeScript = timeMemberAccess("Script object p.x", interp5a, "p.x", 30000);
		var timeNative = timeMemberAccess("Native object p.x", interp5b, "p.x", 30000);
		
		trace('Native is ${Std.string(Std.int((timeScript / timeNative) * 100) / 100)}x faster than script object\n');
		
		// Test 6: Compare with optimizations on/off
		trace("Test 6: Optimizations comparison");
		trace("─────────────────────────────────────────────────");
		var interp6a = new Interpreter();
		interp6a.optimize = false;
		interp6a.runDynamic('var obj = { x: 10 };');
		
		var interp6b = new Interpreter();
		interp6b.optimize = true;
		interp6b.runDynamic('var obj = { x: 10 };');
		
		var timeOptOff = timeMemberAccess("optimize=false", interp6a, "obj.x", 30000);
		var timeOptOn = timeMemberAccess("optimize=true", interp6b, "obj.x", 30000);
		
		if (timeOptOn > 0)
			trace('Optimizations: ${Std.string(Std.int((timeOptOff / timeOptOn) * 100) / 100)}x speedup\n');
		
		// Test 7: Profiling
		#if nx_profile
		trace("Test 7: Profiling Data");
		trace("─────────────────────────────────────────────────");
		interp6b.vm.printProfileReport();
		#else
		trace("\nCompile with -D nx_profile for detailed profiling\n");
		#end
		
		trace("══════════════════════════════════════════════════");
		trace("Benchmark complete");
		trace("══════════════════════════════════════════════════");
	}
}
