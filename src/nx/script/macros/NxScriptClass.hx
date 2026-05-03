package nx.script.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

using StringTools;

/**
 * Macro that wraps script methods with fallback to native implementations.
 * 
 * Usage on a concrete class:
 * ```haxe
 * @:build(nx.script.macros.NxScriptClass.build())
 * class MyState extends FlxState {
 *   function update(elapsed:Float) {
 *     // Native update logic
 *   }
 *   
 *   function create() {
 *     // Native create logic
 *   }
 * }
 * ```
 * 
 * Usage on a base class (recommended):
 * ```haxe
 * @:autoBuild(nx.script.macros.NxScriptClass.build())
 * class FlxScriptState extends FlxState {}
 * ```
 *
 * The macro:
 * 1. Create `__script_methodName` fields for each method
 * 2. Wrap each method to call the script version if available
 * 3. Fall back to native implementation if script method doesn't exist
 */
class NxScriptClass {
	#if macro
	static function isVoidReturn(ret:Null<ComplexType>):Bool {
		if (ret == null)
			return true;
		return switch (ret) {
			case TPath(tp): tp.name == "Void";
			case TParent(t): isVoidReturn(t);
			case TOptional(t): isVoidReturn(t);
			default: false;
		};
	}

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var newFields:Array<Field> = [];
		var hasScriptMethodMap = false;
		var hasSetScriptMethod = false;
		var hasGetScriptMethod = false;

		for (f in fields) {
			switch (f.name) {
				case "__nx_script_methods": hasScriptMethodMap = true;
				case "__nx_setScriptMethod": hasSetScriptMethod = true;
				case "__nx_getScriptMethod": hasGetScriptMethod = true;
				case _:
			}
		}

		if (!hasScriptMethodMap) {
			newFields.push({
				name: "__nx_script_methods",
				doc: "Instance-level script method registry",
				meta: [
					{
						name: ":noCompletion",
						params: [],
						pos: Context.currentPos()
					}
				],
				access: [APrivate],
				kind: FVar(macro :Map<String, Dynamic>, macro new Map<String, Dynamic>()),
				pos: Context.currentPos()
			});
		}

		if (!hasSetScriptMethod) {
			newFields.push({
				name: "__nx_setScriptMethod",
				doc: "Registers a script callback for a wrapped method",
				meta: [
					{
						name: ":noCompletion",
						params: [],
						pos: Context.currentPos()
					}
				],
				access: [APublic],
				kind: FFun({
					args: [
						{name: "name", type: macro :String},
						{name: "fn", type: macro :Dynamic}
					],
					ret: macro :Void,
					expr: macro {
						__nx_script_methods.set(name, fn);
					},
					params: []
				}),
				pos: Context.currentPos()
			});
		}

		if (!hasGetScriptMethod) {
			newFields.push({
				name: "__nx_getScriptMethod",
				doc: "Looks up a script callback for a wrapped method",
				meta: [
					{
						name: ":noCompletion",
						params: [],
						pos: Context.currentPos()
					}
				],
				access: [APublic],
				kind: FFun({
					args: [
						{name: "name", type: macro :String}
					],
					ret: macro :Dynamic,
					expr: macro {
						return __nx_script_methods.exists(name) ? __nx_script_methods.get(name) : null;
					},
					params: []
				}),
				pos: Context.currentPos()
			});
		}

		for (field in fields) {
			switch (field.kind) {
				case FFun(fn) if (fn.expr != null):
					// Get the method name
					var methodName = field.name;

					// Skip special methods
					if (methodName == "new" || methodName.startsWith("__") || methodName.startsWith("get_") || methodName.startsWith("set_")) {
						newFields.push(field);
						continue;
					}

					// Create the script field name
					var scriptFieldName = '__script_${methodName}';
					var guardFieldName = '__nx_script_guard_${methodName}';

					// Add a field to hold the script callable
					var scriptField:Field = {
						name: scriptFieldName,
						doc: 'Script-side implementation of ${methodName}',
						meta: [
							{
								name: ":noCompletion",
								params: [],
								pos: Context.currentPos()
							}
						],
						access: [APrivate],
						kind: FVar(macro :Dynamic, macro null),
						pos: Context.currentPos()
					};

					newFields.push(scriptField);

					var guardField:Field = {
						name: guardFieldName,
						doc: 'Reentrancy guard for ${methodName} script callback',
						meta: [
							{
								name: ":noCompletion",
								params: [],
								pos: Context.currentPos()
							}
						],
						access: [APrivate],
						kind: FVar(macro :Bool, macro false),
						pos: Context.currentPos()
					};

					newFields.push(guardField);

					// Now wrap the original method
					var args = fn.args;
					var returnsVoid = isVoidReturn(fn.ret);
					var paramList = [
						for (arg in args) {
							var ident = macro $i{arg.name};
							ident;
						}
					];

					// Build the call expression for the script method
					var scriptCall:Expr;
					if (returnsVoid) {
						scriptCall = macro {
							#if NXDEBUG
							var __nxClassName = Type.getClassName(Type.getClass(this));
							trace('[NxScriptWrapper - ' + __nxClassName + '] wrapper enter: ' + $v{methodName});
							#end
							if ($i{guardFieldName}) {
								#if NXDEBUG
								trace('[NxScriptWrapper - ' + __nxClassName + '] reentrant call for ' + $v{methodName} + ', running native method');
								#end
							} else {
							var __nxScriptFn:Dynamic = $i{scriptFieldName};
							if ((__nxScriptFn == null || !nx.bridge.Reflection.isFunction(__nxScriptFn))
								&& Reflect.hasField(this, "__nx_getScriptMethod")) {
								var __nxGetter = Reflect.field(this, "__nx_getScriptMethod");
								if (__nxGetter != null) {
									__nxScriptFn = nx.bridge.Reflection.callMethod(this, __nxGetter, [$v{methodName}]);
									#if NXDEBUG
									trace('[NxScriptWrapper - ' + __nxClassName + '] registry lookup for ' + $v{methodName} + ': ' + (__nxScriptFn != null));
									#end
								}
							}
							if (__nxScriptFn != null && nx.bridge.Reflection.isFunction(__nxScriptFn)) {
								try {
									$i{guardFieldName} = true;
									#if NXDEBUG
									trace('[NxScriptWrapper - ' + __nxClassName + '] calling script callback: ' + $v{methodName});
									#end
									nx.bridge.Reflection.callMethod(this, __nxScriptFn, $a{paramList});
									$i{guardFieldName} = false;
									return;
								} catch (e:Dynamic) {
									$i{guardFieldName} = false;

									var __nxClassName = Type.getClassName(Type.getClass(this));

									trace('[NxScriptWrapper - ' + __nxClassName + '] Error calling script method ' + $v{methodName} + ': ' + e);
									// Fall through to native implementation
								}
							}
							#if NXDEBUG
							trace('[NxScriptWrapper - ' + __nxClassName + '] no script callback for ' + $v{methodName} + ', running native method');
							#end
							}
						};
					} else {
						scriptCall = macro {
							#if NXDEBUG
							var __nxClassName = Type.getClassName(Type.getClass(this));
							trace('[NxScriptWrapper - ' + __nxClassName + '] wrapper enter: ' + $v{methodName});
							#end
							if ($i{guardFieldName}) {
								#if NXDEBUG
								trace('[NxScriptWrapper - ' + __nxClassName + '] reentrant call for ' + $v{methodName} + ', running native method');
								#end
							} else {
							var __nxScriptFn:Dynamic = $i{scriptFieldName};
							if ((__nxScriptFn == null || !nx.bridge.Reflection.isFunction(__nxScriptFn))
								&& Reflect.hasField(this, "__nx_getScriptMethod")) {
								var __nxGetter = Reflect.field(this, "__nx_getScriptMethod");
								if (__nxGetter != null) {
									__nxScriptFn = nx.bridge.Reflection.callMethod(this, __nxGetter, [$v{methodName}]);
									#if NXDEBUG
									trace('[NxScriptWrapper - ' + __nxClassName + '] registry lookup for ' + $v{methodName} + ': ' + (__nxScriptFn != null));
									#end
								}
							}
							if (__nxScriptFn != null && nx.bridge.Reflection.isFunction(__nxScriptFn)) {
								try {
									$i{guardFieldName} = true;
									#if NXDEBUG
									trace('[NxScriptWrapper - ' + __nxClassName + '] calling script callback: ' + $v{methodName});
									#end
									var __nxResult = cast nx.bridge.Reflection.callMethod(this, __nxScriptFn, $a{paramList});
									$i{guardFieldName} = false;
									return __nxResult;
								} catch (e:Dynamic) {
									$i{guardFieldName} = false;
									trace('[NxScriptWrapper - ' + __nxClassName + '] Error calling script method ' + $v{methodName} + ': ' + e);
									// Fall through to native implementation
								}
							}
							#if NXDEBUG
							trace('[NxScriptWrapper - ' + __nxClassName + '] no script callback for ' + $v{methodName} + ', running native method');
							#end
							}
						};
					}

					// Wrap the original expression
					var wrappedExpr = switch (fn.expr.expr) {
						case EBlock(exprs):
							var wrappedBlockExprs:Array<Expr> = [scriptCall];
							for (expr in exprs)
								wrappedBlockExprs.push(expr);
							{
								expr: EBlock(wrappedBlockExprs),
								pos: fn.expr.pos
							};
						default:
							{
								expr: EBlock([scriptCall, fn.expr]),
								pos: fn.expr.pos
							};
					};

					// Create wrapped function
					var wrappedFn = {
						args: args,
						ret: fn.ret,
						expr: wrappedExpr,
						params: fn.params
					};

					// Create wrapped field
					var wrappedField = {
						name: field.name,
						doc: field.doc,
						access: field.access,
						kind: FFun(wrappedFn),
						pos: field.pos,
						meta: field.meta
					};

					newFields.push(wrappedField);

				case _:
					newFields.push(field);
			}
		}

		return newFields;
	}
	#end
}
