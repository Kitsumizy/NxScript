package nx.script.types;

import nx.script.Bytecode.Value;
import nx.script.Interpreter;

/**
 * Host wrapper around a script object/instance/dict value.
 */
class NxObject {
	public var interp(default, null):Null<Interpreter>;
	public var scriptValue(default, null):Value;

	public function new(?interp:Interpreter, ?value:Value) {
		this.interp = interp;
		this.scriptValue = value != null ? value : VNull;
	}

	public inline function toValue():Value {
		return scriptValue;
	}

	public function toHaxe():Dynamic {
		if (interp == null)
			return null;
		return interp.vm.valueToHaxe(scriptValue);
	}

	inline function requireScriptBinding():Interpreter {
		if (interp == null)
			throw "NxObject is not bound to an Interpreter";
		return interp;
	}

	public function get(member:String):Dynamic {
		var i = requireScriptBinding();
		var memberId = i.memberId(member);
		return i.vm.valueToHaxe(i.vm.getMemberById(scriptValue, memberId));
	}

	public function getId(memberId:Int):Dynamic {
		var i = requireScriptBinding();
		return i.vm.valueToHaxe(i.vm.getMemberById(scriptValue, memberId));
	}

	public function set(member:String, v:Dynamic):NxObject {
		var i = requireScriptBinding();
		var memberId = i.memberId(member);
		i.vm.setMemberById(scriptValue, memberId, i.vm.haxeToValue(v));
		return this;
	}

	public function setId(memberId:Int, v:Dynamic):NxObject {
		var i = requireScriptBinding();
		i.vm.setMemberById(scriptValue, memberId, i.vm.haxeToValue(v));
		return this;
	}

	public function callMember(member:String, ?args:Array<Dynamic>):Dynamic {
		var i = requireScriptBinding();
		var memberId = i.memberId(member);
		return callMemberId(memberId, args);
	}

	public function callMemberId(memberId:Int, ?args:Array<Dynamic>):Dynamic {
		var i = requireScriptBinding();
		if (args == null)
			args = [];
		var scriptArgs = [for (a in args) i.vm.haxeToValue(a)];
		var result = i.vm.callMemberById(scriptValue, memberId, scriptArgs);
		return i.vm.valueToHaxe(result);
	}

	public function callable(member:String):NxCallable {
		var i = requireScriptBinding();
		var memberId = i.memberId(member);
		return new NxCallable(i, i.vm.getMemberById(scriptValue, memberId));
	}

	public function callableId(memberId:Int):NxCallable {
		var i = requireScriptBinding();
		return new NxCallable(i, i.vm.getMemberById(scriptValue, memberId));
	}
}
