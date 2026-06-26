package nx.script;

import nx.script.Bytecode.Value;
import nx.script.Bytecode.ClassData;
import nx.script.Bytecode.FunctionChunk;

/**
 * Registers the built-in class hierarchy (Object, String, Number, Bool, Array, Function)
 * into the VM's class/globals registry.
 *
 * These aren't full implementations — they're class shells so that method dispatch on
 * primitive values (`"hi".upper()`, `(3.5).floor()`, etc.) resolves correctly.
 * The actual method bodies live in VM's GET_MEMBER/CALL dispatch.
 *
 * Extending these from script code is technically allowed. Results may vary.
 */
class NativeClasses {
	private static function numberResolver():Value->String->Null<Value> {
		return function(self:Value, field:String):Null<Value> {
			return switch (self) {
				case VNumber(n):
					switch (field) {
						// Rounding
						case "floor": VNativeFunction("floor", 0, (_) -> VNumber(Math.floor(n)));
						case "ceil": VNativeFunction("ceil", 0, (_) -> VNumber(Math.ceil(n)));
						case "round": VNativeFunction("round", 0, (_) -> VNumber(Math.round(n)));
						case "abs": VNativeFunction("abs", 0, (_) -> VNumber(Math.abs(n)));

						// Roots & Powers
						case "sqrt": VNativeFunction("sqrt", 0, (_) -> VNumber(Math.sqrt(n)));
						case "pow": VNativeFunction("pow", 1, (args) -> switch (args[0]) {
								case VNumber(exp): VNumber(Math.pow(n, exp));
								default: throw 'Expected number';
							});

						// Trigonometry
						case "sin": VNativeFunction("sin", 0, (_) -> VNumber(Math.sin(n)));
						case "cos": VNativeFunction("cos", 0, (_) -> VNumber(Math.cos(n)));
						case "tan": VNativeFunction("tan", 0, (_) -> VNumber(Math.tan(n)));
						case "asin": VNativeFunction("asin", 0, (_) -> VNumber(Math.asin(n)));
						case "acos": VNativeFunction("acos", 0, (_) -> VNumber(Math.acos(n)));
						case "atan": VNativeFunction("atan", 0, (_) -> VNumber(Math.atan(n)));

						// Type conversions
						case "int": VNativeFunction("int", 0, (_) -> VNumber(Math.floor(n)));
						case "float": VNativeFunction("float", 0, (_) -> VNumber(n));
						case "str": VNativeFunction("str", 0, (_) -> VString(Std.string(n)));
						case "bool": VNativeFunction("bool", 0, (_) -> VBool(n != 0));

						// Basic arithmetic
						case "add": VNativeFunction("add", 1, (args) -> switch (args[0]) {
								case VNumber(x): VNumber(n + x);
								default: throw 'Expected number';
							});
						case "sub": VNativeFunction("sub", 1, (args) -> switch (args[0]) {
								case VNumber(x): VNumber(n - x);
								default: throw 'Expected number';
							});
						case "mul": VNativeFunction("mul", 1, (args) -> switch (args[0]) {
								case VNumber(x): VNumber(n * x);
								default: throw 'Expected number';
							});
						case "div": VNativeFunction("div", 1, (args) -> switch (args[0]) {
								case VNumber(x): VNumber(n / x);
								default: throw 'Expected number';
							});
						case "mod": VNativeFunction("mod", 1, (args) -> switch (args[0]) {
								case VNumber(x): VNumber(n % x);
								default: throw 'Expected number';
							});

						// Comparison
						case "min": VNativeFunction("min", 1, (args) -> switch (args[0]) {
								case VNumber(x): VNumber(Math.min(n, x));
								default: throw 'Expected number';
							});
						case "max": VNativeFunction("max", 1, (args) -> switch (args[0]) {
								case VNumber(x): VNumber(Math.max(n, x));
								default: throw 'Expected number';
							});

						default: null;
					}
				default: null;
			}
		};
	}

	private static function stringResolver():Value->String->Null<Value> {
		return function(self:Value, field:String):Null<Value> {
			return switch (self) {
				case VString(s):
					switch (field) {
						// Properties
						case "length": VNumber(s.length);

						// Case conversion
						case "upper": VNativeFunction("upper", 0, (_) -> VString(s.toUpperCase()));
						case "lower": VNativeFunction("lower", 0, (_) -> VString(s.toLowerCase()));

						// Trimming
						case "trim": VNativeFunction("trim", 0, (_) -> VString(StringTools.trim(s)));

						// Type conversion
						case "int": VNativeFunction("int", 0, (_) -> VNumber(Std.parseInt(s) != null ? Std.parseInt(s) : 0));
						case "float": VNativeFunction("float", 0, (_) -> VNumber(Std.parseFloat(s)));
						case "bool": VNativeFunction("bool", 0, (_) -> VBool(s.length > 0));

						// Search
						case "contains": VNativeFunction("contains", 1, (args) -> switch (args[0]) {
								case VString(search): VBool(s.indexOf(search) >= 0);
								default: throw 'Expected string';
							});
						case "indexOf": VNativeFunction("indexOf", 1, (args) -> switch (args[0]) {
								case VString(search): VNumber(s.indexOf(search));
								default: throw 'Expected string';
							});

						// Substrings
						case "charAt": VNativeFunction("charAt", 1, (args) -> switch (args[0]) {
								case VNumber(i): VString(s.charAt(Std.int(i)));
								default: throw 'Expected number';
							});
						case "substr": VNativeFunction("substr", 2, (args) -> {
								var start = switch (args[0]) {
									case VNumber(n): Std.int(n);
									default: 0;
								};
								var len = switch (args[1]) {
									case VNumber(n): Std.int(n);
									default: s.length;
								};
								VString(s.substr(start, len));
							});

						// Split/Join
						case "split": VNativeFunction("split", 1, (args) -> switch (args[0]) {
								case VString(delim): VArray([for (part in s.split(delim)) VString(part)]);
								default: throw 'Expected string';
							});

						// Search extras
						case "startsWith": VNativeFunction("startsWith", 1, (args) -> switch (args[0]) {
								case VString(prefix): VBool(s.length >= prefix.length && s.substr(0, prefix.length) == prefix);
								default: throw 'Expected string';
							});
						case "endsWith": VNativeFunction("endsWith", 1, (args) -> switch (args[0]) {
								case VString(suffix): VBool(s.length >= suffix.length && s.substr(s.length - suffix.length) == suffix);
								default: throw 'Expected string';
							});

						// Modification
						case "replace": VNativeFunction("replace", 2, (args) -> {
								var from = switch (args[0]) {
									case VString(x): x;
									default: throw 'Expected string';
								};
								var to = switch (args[1]) {
									case VString(x): x;
									default: throw 'Expected string';
								};
								VString(StringTools.replace(s, from, to));
							});
						case "repeat": VNativeFunction("repeat", 1, (args) -> switch (args[0]) {
								case VNumber(n):
									var count = Std.int(n);
									if (count < 0)
										throw 'repeat count must be >= 0';
									var sb = new StringBuf();
									for (_ in 0...count)
										sb.add(s);
									VString(sb.toString());
								default: throw 'Expected number';
							});
						case "padStart": VNativeFunction("padStart", 2, (args) -> {
								var len = switch (args[0]) {
									case VNumber(n): Std.int(n);
									default: throw 'Expected number';
								};
								var pad = switch (args[1]) {
									case VString(x): x;
									default: " ";
								};
								if (pad.length == 0)
									pad = " ";
								var result = s;
								while (result.length < len)
									result = pad + result;
								VString(result.substr(result.length - Std.int(Math.max(len, s.length))));
							});
						case "padEnd": VNativeFunction("padEnd", 2, (args) -> {
								var len = switch (args[0]) {
									case VNumber(n): Std.int(n);
									default: throw 'Expected number';
								};
								var pad = switch (args[1]) {
									case VString(x): x;
									default: " ";
								};
								if (pad.length == 0)
									pad = " ";
								var result = s;
								while (result.length < len)
									result = result + pad;
								VString(result.substr(0, Std.int(Math.max(len, s.length))));
							});

						default: null;
					}
				default: null;
			}
		};
	}

	/**
	 * Registers all native classes. Call once per VM. Calling it twice will overwrite the first
	 * registration and waste a few microseconds. Don't do that.
	 */
	public static function registerAll(vm:VM):Void {
		registerObject(vm);
		registerString(vm);
		registerNumber(vm);
		registerInt(vm);
		registerFloat(vm);
		registerBool(vm);
		registerArray(vm);
		registerFunction(vm);
		registerConversions(vm);
		#if sys
		registerSys(vm);
		#end
	}

	#if sys
	/**
	 * Exposes Haxe's Sys class as a native object in NxScript.
	 * Allows scripts to call: Sys.command("echo hi"), Sys.println("x"), etc.
	 * Only available on sys targets (HL, CPP, Neko, Node).
	 *
	 * Usage in script:
	 *   import Sys;
	 *   Sys.command('echo Hello');
	 *
	 * Or without import (it's a global):
	 *   Sys.println("hi")
	 */
	private static function registerSys(vm:VM):Void {
		vm.globals.set("Sys", VNativeObject(Sys));
	}
	#end

	// ========================================
	// Object - Base class for all classes
	// ========================================

	private static function registerObject(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		// Object will be the base class, no methods for now
		// Could add: toString, equals, hashCode, etc.

		var classData:ClassData = {
			name: "Object",
			superClass: null,
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: null
		};

		vm.classes.set("Object", classData);
		vm.globals.set("Object", VClass(classData));
	}

	// ========================================
	// String - String manipulation methods
	// ========================================

	private static function registerString(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		// String extends Object
		var classData:ClassData = {
			name: "String",
			superClass: "Object",
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: stringResolver()
		};

		vm.classes.set("String", classData);
		vm.globals.set("String", VClass(classData));
	}

	// ========================================
	// Number - Numeric operations
	// ========================================

	private static function registerNumber(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		var classData:ClassData = {
			name: "Number",
			superClass: "Object",
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: numberResolver()
		};

		vm.classes.set("Number", classData);
		vm.globals.set("Number", VClass(classData));
	}

	// ========================================
	// Int — integer subtype of Number
	// Accepts only whole numbers. Throws on fractional values.
	// ========================================

	private static function registerInt(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		var classData:ClassData = {
			name: "Int",
			superClass: "Number",
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: null
		};

		vm.classes.set("Int", classData);
		vm.globals.set("Int", VClass(classData));

		// Int.from(value) — converts Number/Float to Int, throws on non-integer
		vm.natives.set("Int_from", VNativeFunction("Int_from", 1, (args) -> {
			switch (args[0]) {
				case VNumber(n):
					if (n != Math.floor(n))
						throw 'Int.from: ${n} is not a whole number';
					return VNumber(Math.floor(n));
				default:
					throw 'Int.from expects a Number';
			}
		}));
	}

	// ========================================
	// Float — float subtype of Number
	// Accepts both integers and decimals. Coerces Int to Float.
	// ========================================

	private static function registerFloat(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		var classData:ClassData = {
			name: "Float",
			superClass: "Number",
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: null
		};

		vm.classes.set("Float", classData);
		vm.globals.set("Float", VClass(classData));

		// Float.from(value) — converts Number/Int to Float
		vm.natives.set("Float_from", VNativeFunction("Float_from", 1, (args) -> {
			switch (args[0]) {
				case VNumber(n): return VNumber(n); // already a float internally
				default: throw 'Float.from expects a Number';
			}
		}));
	}

	// ========================================
	// Conversion natives: fromNumber, fromInt, fromFloat
	// ========================================

	private static function registerConversions(vm:VM):Void {
		// fromNumber(x) — identity, accepts VNumber, VBool, VString(numeric)
		vm.natives.set("fromNumber", VNativeFunction("fromNumber", 1, (args) -> {
			return switch (args[0]) {
				case VNumber(n): VNumber(n);
				case VBool(b): VNumber(b ? 1.0 : 0.0);
				case VString(s):
					var n = Std.parseFloat(s);
					Math.isNaN(n) ?throw 'fromNumber: cannot parse "${s}"':VNumber(n);
				default: throw "fromNumber expects a Number, Bool, or numeric String";
			};
		}));

		// fromInt(x) — like fromNumber but enforces whole number
		vm.natives.set("fromInt", VNativeFunction("fromInt", 1, (args) -> {
			return switch (args[0]) {
				case VNumber(n):
					if (n != Math.floor(n))
						throw 'fromInt: ${n} is not a whole number';
					VNumber(Math.floor(n));
				case VString(s):
					var n = Std.parseInt(s);
					n == null ?throw 'fromInt: cannot parse "${s}"':VNumber(n);
				default: throw "fromInt expects a Number or numeric String";
			};
		}));

		// fromFloat(x) — accepts any Number/Int, returns as float
		vm.natives.set("fromFloat", VNativeFunction("fromFloat", 1, (args) -> {
			return switch (args[0]) {
				case VNumber(n): VNumber(n);
				case VString(s):
					var n = Std.parseFloat(s);
					Math.isNaN(n) ?throw 'fromFloat: cannot parse "${s}"':VNumber(n);
				default: throw "fromFloat expects a Number or numeric String";
			};
		}));
	}

	// ========================================
	// Bool - Boolean operations
	// ========================================

	private static function registerBool(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		// Bool extends Object
		var classData:ClassData = {
			name: "Bool",
			superClass: "Object",
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: null
		};

		vm.classes.set("Bool", classData);
		vm.globals.set("Bool", VClass(classData));
	}

	// ========================================
	// Array - Array manipulation
	// ========================================

	private static function registerArray(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		// Array extends Object
		var classData:ClassData = {
			name: "Array",
			superClass: "Object",
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: null
		};

		vm.classes.set("Array", classData);
		vm.globals.set("Array", VClass(classData));
	}

	// ========================================
	// Function - Function wrapper
	// ========================================

	private static function registerFunction(vm:VM):Void {
		var methods = new Map<String, FunctionChunk>();
		var fields = new Map<String, Value>();

		// Function extends Object
		var classData:ClassData = {
			name: "Function",
			superClass: "Object",
			nativeSuper: null,
			methods: methods,
			fields: fields,
			constructor: null,
			staticFields: new Map(),
			staticMethods: new Map(),
			nativeMemberResolver: null
		};

		vm.classes.set("Function", classData);
		vm.globals.set("Function", VClass(classData));
	}
}
