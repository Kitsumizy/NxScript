package nx.script;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import nx.bridge.Reflection;
import nx.script.Bytecode.ClassData;
import nx.script.Bytecode.FunctionChunk;
import nx.script.Bytecode.Value;

#if cpp
import cpp.ObjectType;
#end

/**
 * Minimal member resolver - direct access with simple cache.
 * No complex hierarchies, just cache what we access.
 */
class MemberResolver {
	static inline var NATIVE_SUPER_INSTANCE_FIELD = "__native_super_instance";

	// Cache for native class fields - avoids Type.getInstanceFields() in hot path
	static var nativeFieldsCache:Map<String, Array<String>> = new Map();
	
	// Simple per-object cache: obj -> (memberId -> Value)
	// This is the hotpath - caches field values AND method wrappers
	var nativeCache:ObjectMap<Dynamic, IntMap<Value>>;

	var vm:VM;
	var classStaticMethodCache:ObjectMap<ClassData, IntMap<Value>>;
	var instanceClassMethodCache:ObjectMap<ClassData, IntMap<Null<FunctionChunk>>>;
	var instanceMethodCache:ObjectMap<Dynamic, IntMap<Value>>;

	public function new(vm:VM) {
		this.vm = vm;
		classStaticMethodCache = new ObjectMap();
		instanceClassMethodCache = new ObjectMap();
		instanceMethodCache = new ObjectMap();
		nativeCache = new ObjectMap();
	}

	public function flush():Void {
		classStaticMethodCache = new ObjectMap();
		instanceClassMethodCache = new ObjectMap();
		instanceMethodCache = new ObjectMap();
		nativeCache = new ObjectMap();
	}

	inline function getNativeInstanceFields(nativeClass:Class<Dynamic>):Null<Array<String>> {
		if (nativeClass == null)
			return null;
		var className = Type.getClassName(nativeClass);
		if (nativeFieldsCache.exists(className))
			return nativeFieldsCache.get(className);
		var fields = Type.getInstanceFields(nativeClass);
		nativeFieldsCache.set(className, fields);
		return fields;
	}

	public function getMember(object:Value, field:String):Value {
		var memberId = vm.getMemberId(field);
		return getMemberById(object, memberId);
	}

	public function getMemberById(object:Value, memberId:Int):Value {
		return switch (object) {
			case VInstance(_, fields, classData):
				var fieldName = vm.resolveMemberName(memberId);
				if (fieldName != null && fields.exists(fieldName))
					return fields.get(fieldName);

				var cachedInstanceMethods = instanceMethodCache.get(fields);
				if (cachedInstanceMethods != null && cachedInstanceMethods.exists(memberId))
					return cachedInstanceMethods.get(memberId);

				var classMethodCache = instanceClassMethodCache.get(classData);
				if (classMethodCache == null) {
					classMethodCache = new IntMap<Null<FunctionChunk>>();
					instanceClassMethodCache.set(classData, classMethodCache);
				}

				var resolvedMethod:Null<FunctionChunk> = null;
				if (classMethodCache.exists(memberId)) {
					resolvedMethod = classMethodCache.get(memberId);
				} else {
					resolvedMethod = resolveMethodById(classData, memberId);
					classMethodCache.set(memberId, resolvedMethod);
				}

				if (resolvedMethod != null) {
					var superVal2:Value = VNull;
					if (classData.superClass != null && vm.classes.exists(classData.superClass))
						superVal2 = VClass(vm.classes.get(classData.superClass));
					else {
						switch (fields.get(NATIVE_SUPER_INSTANCE_FIELD)) {
							case VNativeObject(_):
								superVal2 = fields.get(NATIVE_SUPER_INSTANCE_FIELD);
							default:
						}
					}
					var bound = VFunction(resolvedMethod, ["this" => object, "super" => superVal2]);
					if (cachedInstanceMethods == null) {
						cachedInstanceMethods = new IntMap<Value>();
						instanceMethodCache.set(fields, cachedInstanceMethods);
					}
					cachedInstanceMethods.set(memberId, bound);
					return bound;
				}

				var nativeBase = fields.get(NATIVE_SUPER_INSTANCE_FIELD);
				switch (nativeBase) {
					case VNativeObject(_): return getMemberById(nativeBase, memberId);
					default: return VNull;
				}

			case VClass(classData):
				var classCache = classStaticMethodCache.get(classData);
				if (classCache != null && classCache.exists(memberId))
					return classCache.get(memberId);

				var staticMethod = resolveStaticMethodById(classData, memberId);
				if (staticMethod != null) {
					var bound = VFunction(staticMethod, ["__class__" => VClass(classData)]);
					if (classCache == null) {
						classCache = new IntMap<Value>();
						classStaticMethodCache.set(classData, classCache);
					}
					classCache.set(memberId, bound);
					return bound;
				}

				var memberName = vm.resolveMemberName(memberId);
				if (memberName != null && classData.staticFields.exists(memberName))
					return classData.staticFields.get(memberName);

				if (memberName == "new" && classData.constructor != null) {
					var thisVal = vm.getVariable("this") ?? VNull;
					return VFunction(classData.constructor, ["this" => thisVal, "__super_ctor__" => VBool(true)]);
				}

				var method = resolveMethodById(classData, memberId);
				if (method != null) {
					var thisVal = vm.getVariable("this") ?? VNull;
					return VFunction(method, ["this" => thisVal]);
				}
				return VNull;

			case VNativeObject(obj):
				// HOTPATH: Check cache FIRST - this is the big win
				var objCache = nativeCache.get(obj);
				if (objCache != null && objCache.exists(memberId))
					return objCache.get(memberId);
				
				var field = vm.resolveMemberName(memberId);
				if (field == null)
					throw 'Unknown member id: $memberId';

				// Sandbox check for blocked members (e.g. destroy(), etc.)
				if (vm.sandboxed && vm.sandboxBlocklist.exists(field))
					throw 'Sandbox: access to member "$field" is not allowed';

				// Array hotpath - check if native object is actually an Array
				// vtArray = 4 in hxcpp's ObjectType enum
				#if cpp
				var isArray = untyped __cpp__("({0}).mPtr && ({0}).mPtr->__GetType() == 4", obj);
				#else
				var isArray = Std.isOfType(obj, Array);
				#end
				
				if (isArray) {
					var arr:Array<Dynamic> = cast obj;
					var result = switch (field) {
						case "length": VNumber(arr.length);
						case "push": VNativeFunction("push", 1, (args) -> { arr.push(vm.valueToHaxe(args[0])); return VNumber(arr.length); });
						case "pop": VNativeFunction("pop", 0, (_) -> arr.length == 0 ? VNull : vm.haxeToValue(arr.pop()));
						case "shift": VNativeFunction("shift", 0, (_) -> arr.length == 0 ? VNull : vm.haxeToValue(arr.shift()));
						case "unshift": VNativeFunction("unshift", 1, (args) -> { arr.unshift(vm.valueToHaxe(args[0])); return VNull; });
						case "first": arr.length > 0 ? vm.haxeToValue(arr[0]) : VNull;
						case "last": arr.length > 0 ? vm.haxeToValue(arr[arr.length - 1]) : VNull;
						case "join": VNativeFunction("join", 1, (args) -> {
							var sep = switch (args[0]) { case VString(s): s; default: ""; };
							return VString(arr.map(v -> Std.string(v)).join(sep));
						});
						case "reverse": VNativeFunction("reverse", 0, (_) -> { arr.reverse(); return VNativeObject(arr); });
						case "indexOf": VNativeFunction("indexOf", 1, (args) -> VNumber(arr.indexOf(vm.valueToHaxe(args[0]))));
						case "contains" | "includes": VNativeFunction(field, 1, (args) -> VBool(arr.indexOf(vm.valueToHaxe(args[0])) >= 0));
						case "copy": VNativeObject(arr.copy());
						default: null;
					}
					if (result != null) {
						if (objCache == null) {
							objCache = new IntMap<Value>();
							nativeCache.set(obj, objCache);
						}
						objCache.set(memberId, result);
						return result;
					}
				}

				// Direct field access - no overhead
				var raw:Dynamic = Reflection.getField(obj, field);
				if (raw == null)
					raw = Reflect.field(obj, field);
				if (raw == null)
					return VNull;
				
				var result:Value;
				if (Reflection.isFunction(raw)) {
					var capturedObj = obj;
					var capturedFn = raw;
					result = VNativeFunction(field, -1, (args:Array<Value>) -> {
						var haxeArgs = [for (a in args) vm.valueToHaxe(a)];
						return vm.haxeToValue(Reflection.callMethod(capturedObj, capturedFn, haxeArgs));
					});
				} else {
					result = vm.haxeToValue(raw);
				}
				
				// Cache for next time
				if (objCache == null) {
					objCache = new IntMap<Value>();
					nativeCache.set(obj, objCache);
				}
				objCache.set(memberId, result);
				return result;

			default:
				throw 'Unsupported member target';
		}
	}

	public function setMember(object:Value, field:String, value:Value):Void {
		var memberId = vm.getMemberId(field);
		setMemberById(object, memberId, value);
	}

	public function setMemberById(object:Value, memberId:Int, value:Value):Void {
		switch (object) {
			case VInstance(_, fields, _):
				var fieldName = vm.resolveMemberName(memberId);
				if (fieldName == null)
					throw 'Unknown member id: $memberId';
				if (fields.exists(fieldName)) {
					fields.set(fieldName, value);
				} else {
					var nativeBase = fields.get(NATIVE_SUPER_INSTANCE_FIELD);
					switch (nativeBase) {
						case VNativeObject(_):
							setMemberById(nativeBase, memberId, value);
						default:
							fields.set(fieldName, value);
					}
				}
			case VClass(classData):
				var fieldName = vm.resolveMemberName(memberId);
				if (fieldName == null)
					throw 'Unknown member id: $memberId';
				classData.staticFields.set(fieldName, value);
			case VNativeObject(obj):
				var fieldName = vm.resolveMemberName(memberId);
				if (fieldName == null)
					throw 'Unknown member id: $memberId';
				Reflection.setField(obj, fieldName, vm.valueToHaxe(value));
				// Invalidate cache for this member
				var objCache = nativeCache.get(obj);
				if (objCache != null)
					objCache.remove(memberId);
			default:
				throw 'Cannot set member id $memberId';
		}
	}

	function resolveMethodById(classData:ClassData, memberId:Int):Null<FunctionChunk> {
		var currentClass = classData;
		while (currentClass != null) {
			for (name in currentClass.methods.keys()) {
				if (vm.getMemberId(name) == memberId)
					return currentClass.methods.get(name);
			}
			if (currentClass.superClass != null && vm.classes.exists(currentClass.superClass))
				currentClass = vm.classes.get(currentClass.superClass);
			else
				currentClass = null;
		}
		return null;
	}

	function resolveStaticMethodById(classData:ClassData, memberId:Int):Null<FunctionChunk> {
		for (name in classData.staticMethods.keys()) {
			if (vm.getMemberId(name) == memberId)
				return classData.staticMethods.get(name);
		}
		return null;
	}
}
