package;

import nx.script.Interpreter;
import Sys;

class MemberAccessBenchmark {
	static function timeit(label:String, fn:Void->Void, iterations:Int = 100000) {
		var t0 = Sys.time();
		for (i in 0...iterations) {
			fn();
		}
		var t1 = Sys.time();
		var ms = (t1 - t0) * 1000;
		var perOp = (ms / iterations) * 1000; // microseconds per operation
		trace('$label: ${ms}ms total, ${perOp}μs per op (${iterations} iterations)');
	}

	static function main() {
		trace("==============================================");
		trace("Member Access Benchmark");
		trace("==============================================");
		
		// Test 1: Native object field access
		trace("\n1. Native Object Field Access:");
		var interp1 = new Interpreter();
		interp1.runDynamic('
			var obj = { x: 10, y: 20, z: 30 };
		');
		
		timeit("obj.x access (cached)", () -> {
			var result = interp1.runDynamic("obj.x");
		}, 10000);
		
		// Test 2: Native object method call
		trace("\n2. Native Object Method Call:");
		var interp2 = new Interpreter();
		interp2.runDynamic('
			var arr = [1, 2, 3, 4, 5];
		');
		
		timeit("arr.length access", () -> {
			var result = interp2.runDynamic("arr.length");
		}, 10000);
		
		timeit("arr.push() call", () -> {
			var result = interp2.runDynamic("arr.push(1)");
		}, 10000);
		
		// Test 3: Script object field access
		trace("\n3. Script Object Field Access:");
		var interp3 = new Interpreter();
		interp3.runDynamic('
			class Point {
				var x = 0;
				var y = 0;
				func new(px, py) {
					this.x = px;
					this.y = py;
				}
			}
			var p = new Point(10, 20);
		');
		
		timeit("p.x access (script object)", () -> {
			var result = interp3.runDynamic("p.x");
		}, 10000);
		
		// Test 4: Array access
		trace("\n4. Array Access:");
		var interp4 = new Interpreter();
		interp4.runDynamic('
			var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
		');
		
		timeit("data[i] access", () -> {
			var result = interp4.runDynamic("data[0]");
		}, 10000);
		
		// Test 5: Chained member access
		trace("\n5. Chained Member Access:");
		var interp5 = new Interpreter();
		interp5.runDynamic('
			var nested = {
				a: {
					b: {
						c: 42
					}
				}
			};
		');
		
		timeit("nested.a.b.c access", () -> {
			var result = interp5.runDynamic("nested.a.b.c");
		}, 10000);
		
		// Test 6: With optimizations enabled
		trace("\n6. With Optimizations Enabled:");
		var interp6 = new Interpreter();
		interp6.optimize = true;
		interp6.runDynamic('
			var obj = { x: 10, y: 20 };
			function getX() { return obj.x; }
		');
		
		timeit("getX() with optimize=true", () -> {
			var result = interp6.runDynamic("getX()");
		}, 10000);
		
		// Test 7: Profiling data
		trace("\n7. Profiling Data:");
		#if nx_profile
		interp6.vm.printProfileReport();
		#else
		trace("Compile with -D nx_profile for detailed profiling");
		#end
		
		trace("\n==============================================");
		trace("Benchmark complete");
		trace("==============================================");
	}
}
