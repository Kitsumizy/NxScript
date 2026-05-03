package nx.script;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import nx.bridge.Reflection;
import nx.script.Bytecode.ClassData;
import nx.script.Bytecode.FunctionChunk;
import nx.script.Bytecode.Value;

/**
 * Resolves members for heavier object kinds: instances, classes, and native Haxe objects.
 * Uses member IDs internally and only falls back to names when required by backing storage.
 */
class MemberResolver {
	static inline var NATIVE_SUPER_INSTANCE_FIELD = "__native_super_instance";

	var vm:VM;
	var classStaticMethodCache:ObjectMap<ClassData, IntMap<Value>>;
	var instanceClassMethodCache:ObjectMap<ClassData, IntMap<Null<FunctionChunk>>>;
	var instanceMethodCache:ObjectMap<Dynamic, IntMap<Value>>;
	var nativeObjectMethodCache:ObjectMap<Dynamic, IntMap<Value>>;
	var nativeFieldKindCache:Map<String, IntMap<Bool>>;

	public function new(vm:VM) {
		this.vm = vm;
		classStaticMethodCache = new ObjectMap();
		instanceClassMethodCache = new ObjectMap();
		instanceMethodCache = new ObjectMap();
		nativeObjectMethodCache = new ObjectMap();
		nativeFieldKindCache = new Map();
	}

	public function flush():Void {
		classStaticMethodCache = new ObjectMap();
		instanceClassMethodCache = new ObjectMap();
		instanceMethodCache = new ObjectMap();
		nativeObjectMethodCache = new ObjectMap();
		nativeFieldKindCache = new Map();
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
						// For classes that directly extend a native base (e.g. FlxState),
						// bind `super` to the attached native instance so calls like
						// `super.add(obj)` work inside script overrides.
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
				var nativeCache = nativeObjectMethodCache.get(obj);
				if (nativeCache != null && nativeCache.exists(memberId))
					return nativeCache.get(memberId);

				var field = vm.resolveMemberName(memberId);
				if (field == null)
					throw 'Unknown member id: $memberId';

				if (Std.isOfType(obj, Array)) {
					var arr:Array<Dynamic> = cast obj;
					switch (field) {
						case "length": return VNumber(arr.length);
						case "push": return cacheNativeMethodById(obj, memberId, VNativeFunction("push", 1, (args) -> {
								arr.push(vm.valueToHaxe(args[0]));
								return VNumber(arr.length);
							}));
						case "pop": return cacheNativeMethodById(obj, memberId,
								VNativeFunction("pop", 0, (_) -> arr.length == 0 ? VNull : vm.haxeToValue(arr.pop())));
						case "shift": return cacheNativeMethodById(obj, memberId,
								VNativeFunction("shift", 0, (_) -> arr.length == 0 ? VNull : vm.haxeToValue(arr.shift())));
						case "unshift": return cacheNativeMethodById(obj, memberId, VNativeFunction("unshift", 1, (args) -> {
								arr.unshift(vm.valueToHaxe(args[0]));
								return VNull;
							}));
						case "first": return arr.length > 0 ? vm.haxeToValue(arr[0]) : VNull;
						case "last": return arr.length > 0 ? vm.haxeToValue(arr[arr.length - 1]) : VNull;
						case "join": return cacheNativeMethodById(obj, memberId, VNativeFunction("join", 1, (args) -> {
								var sep = switch (args[0]) {
									case VString(s): s;
									default: "";
								};
								return VString(arr.map(v -> Std.string(v)).join(sep));
							}));
						case "reverse": return cacheNativeMethodById(obj, memberId, VNativeFunction("reverse", 0, (_) -> {
								arr.reverse();
								return VNativeObject(arr);
							}));
						case "indexOf": return cacheNativeMethodById(obj, memberId,
								VNativeFunction("indexOf", 1, (args) -> VNumber(arr.indexOf(vm.valueToHaxe(args[0])))));
						case "contains" | "includes":
							return cacheNativeMethodById(obj, memberId, VNativeFunction(field, 1, (args) -> VBool(arr.indexOf(vm.valueToHaxe(args[0])) >= 0)));
						case "copy": return VNativeObject(arr.copy());
						default:
					}
				}

				var nativeClass = Type.getClass(obj);
				var nativeClassName = nativeClass == null ? null : Type.getClassName(nativeClass);
				var instanceFields:Array<String> = nativeClass == null ? null : Type.getInstanceFields(nativeClass);
				if (instanceFields != null && instanceFields.indexOf(field) >= 0) {
					var reflectedField = Reflect.field(obj, field);
					if (reflectedField != null) {
						if (Reflection.isFunction(reflectedField)) {
							var capturedObj = obj;
							var capturedFn = reflectedField;
							return cacheNativeMethodById(obj, memberId, VNativeFunction(field, -1, (args:Array<Value>) -> {
								var haxeArgs = [for (a in args) vm.valueToHaxe(a)];
								return vm.haxeToValue(Reflection.callMethod(capturedObj, capturedFn, haxeArgs));
							}));
						}
						return vm.haxeToValue(reflectedField);
					}
				}
				var kindCache = nativeClassName == null ? null : nativeFieldKindCache.get(nativeClassName);
				if (kindCache != null && kindCache.exists(memberId) && kindCache.get(memberId)) {
					var cachedFn = Reflection.getField(obj, field);
					if (cachedFn != null && Reflection.isFunction(cachedFn)) {
						var capturedObj = obj;
						var capturedFn = cachedFn;
						return cacheNativeMethodById(obj, memberId, VNativeFunction(field, -1, (args:Array<Value>) -> {
							var haxeArgs = [for (a in args) vm.valueToHaxe(a)];
							return vm.haxeToValue(Reflection.callMethod(capturedObj, capturedFn, haxeArgs));
						}));
					}
				}

				var raw:Dynamic = Reflection.getField(obj, field);
				if (raw == null)
					raw = Reflect.field(obj, field);
				if (raw == null)
					return VNull;
				var isFn = Reflection.isFunction(raw);
				if (kindCache == null && nativeClassName != null) {
					kindCache = new IntMap<Bool>();
					nativeFieldKindCache.set(nativeClassName, kindCache);
				}
				if (kindCache != null)
					kindCache.set(memberId, isFn);
				if (!isFn)
					return vm.haxeToValue(raw);
				var capturedObj = obj;
				var capturedFn = raw;
				return cacheNativeMethodById(obj, memberId, VNativeFunction(field, -1, (args:Array<Value>) -> {
					var haxeArgs = [for (a in args) vm.valueToHaxe(a)];
					return vm.haxeToValue(Reflection.callMethod(capturedObj, capturedFn, haxeArgs));
				}));

			default:
				throw 'Unsupported member target';
		};
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
				var nativeClass = Type.getClass(obj);
				if (nativeClass != null) {
					var nativeClassName = Type.getClassName(nativeClass);
					var kindCache = nativeFieldKindCache.get(nativeClassName);
					if (kindCache != null)
						kindCache.remove(memberId);
				}
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

	inline function cacheNativeMethodById(obj:Dynamic, memberId:Int, value:Value):Value {
		var cachedMethods = nativeObjectMethodCache.get(obj);
		if (cachedMethods == null) {
			cachedMethods = new IntMap<Value>();
			nativeObjectMethodCache.set(obj, cachedMethods);
		}
		cachedMethods.set(memberId, value);
		return value;
	}
}
