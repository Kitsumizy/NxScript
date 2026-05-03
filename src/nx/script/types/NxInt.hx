package nx.script.types;

import nx.script.Bytecode.Value;
import nx.script.Interpreter;

class NxInt extends NxNumber {
	public function new(value:Int, ?interp:Interpreter, ?rawValue:Value) {
		super(value, interp, rawValue);
	}

	public inline function asInt():Int
		return Std.int(number);

	public inline function inc():NxInt
		return new NxInt(Std.int(number) + 1, interp);

	public inline function dec():NxInt
		return new NxInt(Std.int(number) - 1, interp);

	public inline function addInt(v:Int):NxInt
		return new NxInt(Std.int(number) + v, interp);

	public inline function subInt(v:Int):NxInt
		return new NxInt(Std.int(number) - v, interp);
}
