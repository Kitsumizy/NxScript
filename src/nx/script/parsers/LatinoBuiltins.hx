package nx.script.parsers;

import nx.script.Interpreter;
import nx.script.types.*;

/**
 * Built-in functions for Latino language parser.
 * Call LatinoParser.registerBuiltins(interp) after creating Interpreter.
 */
class LatinoBuiltins {
	public static function registerAll(interp:Interpreter):Void {
		var vm = interp.vm;
		
		// Console output
		vm.natives.set("escribir", VNativeFunction("escribir", -1, function(args:Array<Value>):Value {
			var parts:Array<Dynamic> = [];
			for (arg in args) parts.push(vm.valueToString(arg));
			#if sys
			Sys.println(parts.join(" "));
			#else
			trace(parts.join(" "));
			#end
			return VNull;
		}));

		vm.natives.set("poner", VNativeFunction("poner", -1, function(args:Array<Value>):Value {
			var parts:Array<Dynamic> = [];
			for (arg in args) parts.push(vm.valueToString(arg));
			#if sys
			Sys.print(parts.join(" "));
			#else
			trace(parts.join(" "));
			#end
			return VNull;
		}));

		vm.natives.set("leer", VNativeFunction("leer", 0, function(args:Array<Value>):Value {
			#if sys
			return VString(Sys.stdin().readLine());
			#else
			return VString("");
			#end
		}));

		vm.natives.set("limpiar", VNativeFunction("limpiar", 0, function(args:Array<Value>):Value {
			return VNull;
		}));

		// Type functions (Latino names)
		vm.natives.set("tipo", VNativeFunction("tipo", 1, function(args:Array<Value>):Value {
			return VString(switch (args[0]) {
				case VNumber(_): "decimal"; case VString(_): "cadena"; case VBool(_): "logico";
				case VArray(_): "lista"; case VDict(_): "diccionario"; case VNull: "nulo";
				case VFunction(_, _), VNativeFunction(_, _, _): "funcion";
				case VNativeObject(obj):
					#if (js || html5)
					if (Type.getClassName(Type.getClass(obj)) == "Date") "fecha" else "objeto";
					#elseif cpp
					if (untyped __cpp__("({0}).mPtr && std::string({0}).mPtr->__GetClass()->mName == \"Date\"")) "fecha" else "objeto";
					#else
					if (Std.isOfType(obj, Date)) "fecha" else "objeto";
					#end
				case VClass(_): "clase"; case VInstance(_, _, _): "instancia";
				default: "desconocido";
			});
		}));

		// Math
		vm.natives.set("abs", VNativeFunction("abs", 1, function(args:Array<Value>):Value {
			return VNumber(switch (args[0]) { case VNumber(n): Math.abs(n); default: 0; });
		}));
		vm.natives.set("floor", VNativeFunction("floor", 1, function(args:Array<Value>):Value {
			return VNumber(switch (args[0]) { case VNumber(n): Math.floor(n); default: 0; });
		}));
		vm.natives.set("ceil", VNativeFunction("ceil", 1, function(args:Array<Value>):Value {
			return VNumber(switch (args[0]) { case VNumber(n): Math.ceil(n); default: 0; });
		}));
		vm.natives.set("round", VNativeFunction("round", 1, function(args:Array<Value>):Value {
			return VNumber(switch (args[0]) { case VNumber(n): Math.round(n); default: 0; });
		}));
		vm.natives.set("sqrt", VNativeFunction("sqrt", 1, function(args:Array<Value>):Value {
			return VNumber(switch (args[0]) { case VNumber(n): Math.sqrt(n); default: 0; });
		}));
		vm.natives.set("pow", VNativeFunction("pow", 2, function(args:Array<Value>):Value {
			var b = switch (args[0]) { case VNumber(n): n; default: 0.0; }
			var e = switch (args[1]) { case VNumber(n): n; default: 0.0; }
			return VNumber(Math.pow(b, e));
		}));

		vm.natives.set("PI", VNumber(Math.PI));
		vm.natives.set("E", VNumber(Math.exp(1)));

		// Array (Latino names)
		vm.natives.set("longitud", VNativeFunction("longitud", 1, function(args:Array<Value>):Value {
			return VNumber(switch (args[0]) {
				case VArray(arr): arr.length; case VString(s): s.length;
				case VDict(map): Lambda.count(map); default: 0;
			});
		}));

		vm.natives.set("rango", VNativeFunction("rango", -1, function(args:Array<Value>):Value {
			var from = 0, to = 0;
			if (args.length == 1) to = switch (args[0]) { case VNumber(n): Std.int(n); default: throw "rango espera un numero"; };
			else if (args.length == 2) {
				from = switch (args[0]) { case VNumber(n): Std.int(n); default: throw "rango espera numeros"; };
				to = switch (args[1]) { case VNumber(n): Std.int(n); default: throw "rango espera numeros"; };
			} else throw "rango espera 1 o 2 argumentos";
			return VArray([for (i in from...to) VNumber(i)]);
		}));

		vm.natives.set("empujar", VNativeFunction("empujar", 2, function(args:Array<Value>):Value {
			return switch (args[0]) { case VArray(arr): arr.push(args[1]); VNumber(arr.length); default: throw "empujar() requiere un array"; }
		}));
		vm.natives.set("sacar", VNativeFunction("sacar", 1, function(args:Array<Value>):Value {
			return switch (args[0]) { case VArray(arr): arr.length > 0 ? arr.pop() : VNull; default: throw "sacar() requiere un array"; }
		}));

		// String (Latino names)
		vm.natives.set("mayusculas", VNativeFunction("mayusculas", 1, function(args:Array<Value>):Value {
			return VString(switch (args[0]) { case VString(s): s.toUpperCase(); default: ""; });
		}));
		vm.natives.set("minusculas", VNativeFunction("minusculas", 1, function(args:Array<Value>):Value {
			return VString(switch (args[0]) { case VString(s): s.toLowerCase(); default: ""; });
		}));
		vm.natives.set("recortar", VNativeFunction("recortar", 1, function(args:Array<Value>):Value {
			return VString(switch (args[0]) { case VString(s): StringTools.trim(s); default: ""; });
		}));
		vm.natives.set("dividir", VNativeFunction("dividir", 2, function(args:Array<Value>):Value {
			return switch (args[0]) {
				case VString(s): switch (args[1]) { case VString(d): VArray([for (p in s.split(d)) VString(p)]); default: throw "delimitador debe ser string"; }
				default: throw "dividir() requiere un string";
			}
		}));
		vm.natives.set("unir", VNativeFunction("unir", 2, function(args:Array<Value>):Value {
			return switch (args[0]) {
				case VArray(arr): var strs = [for (v in arr) vm.valueToString(v)];
					switch (args[1]) { case VString(sep): VString(strs.join(sep)); default: VString(strs.join(vm.valueToString(args[1]))); }
				default: throw "unir() requiere un array";
			}
		}));
	}
}
