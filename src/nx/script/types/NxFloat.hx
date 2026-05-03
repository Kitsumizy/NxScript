package nx.script.types;

import nx.script.Bytecode.Value;
import nx.script.Interpreter;

class NxFloat extends NxNumber {
	public function new(value:Float, ?interp:Interpreter, ?rawValue:Value) {
		super(value, interp, rawValue);
	}

	public inline function asFloat():Float
		return number;
}
