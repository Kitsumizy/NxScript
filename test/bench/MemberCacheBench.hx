package;

import nx.script.Interpreter;
import Sys;

class MemberCacheBench {
	static function timeit(label:String, interp:Interpreter, code:String, iterations:Int = 50000) {
		var t0 = Sys.time();
		for (i in 0...iterations) {
			interp.runDynamic(code);
		}
		var t1 = Sys.time();
		var ms = (t1 - t0) * 1000;
		var perOp = (ms / iterations) * 1000;
		var ops = Math.round(iterations / (ms / 1000));
		
		trace(label + ": " + Std.string(ms).substr(0, 6) + "ms total | " + Std.string(perOp).substr(0, 5) + "μs/op | " + ops + " ops/sec");
		return perOp;
	}

	static function main() {
		trace("========================================");
		trace("  Member Access Cache - CPP Benchmark");
		trace("========================================\n");
		
		// Native object field access
		trace("1. Native object field access:");
		var interp1 = new Interpreter();
		interp1.runDynamic('var obj = { x: 10, y: 20 };');
		timeit("   obj.x (first)", interp1, "obj.x", 10000);
		timeit("   obj.x (cached)", interp1, "obj.x", 50000);
		
		// Array access
		trace("\n2. Array access:");
		var interp2 = new Interpreter();
		interp2.runDynamic('var arr = [1, 2, 3, 4, 5];');
		timeit("   arr.length", interp2, "arr.length", 30000);
		timeit("   arr.push()", interp2, "arr.push(1)", 20000);
		
		// Chained access
		trace("\n3. Chained member access:");
		var interp3 = new Interpreter();
		interp3.runDynamic('var deep = { a: { b: { c: 42 } } };');
		timeit("   deep.a.b.c", interp3, "deep.a.b.c", 30000);
		
		// Script vs Native
		trace("\n4. Script object vs Native object:");
		var interp4a = new Interpreter();
		interp4a.runDynamic('class P { var x = 10; } var p = new P();');
		var interp4b = new Interpreter();
		interp4b.runDynamic('var p = { x: 10 };');
		timeit("   Script object p.x", interp4a, "p.x", 30000);
		timeit("   Native object p.x", interp4b, "p.x", 30000);
		
		// Profiling
		#if nx_profile
		trace("\n5. Profile report:");
		interp4b.vm.printProfileReport();
		#end
		
		trace("\n========================================");
		trace("  Done");
		trace("========================================");
	}
}
