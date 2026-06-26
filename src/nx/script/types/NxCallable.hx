package nx.script.types;

import nx.script.Bytecode.Value;
import nx.script.Interpreter;

/**
 * Host wrapper around a callable script value.
 */
class NxCallable extends NxObject {
	public function new(interp:Interpreter, value:Value) {
		super(interp, value);
	}

	public function call(?args:Array<Dynamic>):Dynamic {
		if (args == null)
			args = [];
		var scriptArgs = [for (a in args) interp.vm.haxeToValue(a)];
		return interp.vm.valueToHaxe(interp.vm.callResolved(scriptValue, scriptArgs));
	}

	public function callValue(?args:Array<Value>):Value {
		return interp.vm.callResolved(scriptValue, args != null ? args : []);
	}
}
