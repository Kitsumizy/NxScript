package nx.script.types;

import nx.script.Bytecode.Value;
import nx.script.Interpreter;

class NxNumber extends NxObject implements INumber {
	public var number(default, null):Float;

	public function new(value:Float, ?interp:Interpreter, ?rawValue:Value) {
		super(interp, rawValue != null ? rawValue : VNumber(value));
		this.number = value;
	}

	public inline function add(v:Float):NxNumber
		return new NxNumber(number + v, interp);

	public inline function sub(v:Float):NxNumber
		return new NxNumber(number - v, interp);

	public inline function mul(v:Float):NxNumber
		return new NxNumber(number * v, interp);

	public inline function div(v:Float):NxNumber
		return new NxNumber(number / v, interp);

	public inline function mod(v:Float):NxNumber
		return new NxNumber(number % v, interp);

	public inline function pow(exp:Float):NxNumber
		return new NxNumber(Math.pow(number, exp), interp);

	public inline function sqrt():NxNumber
		return new NxNumber(Math.sqrt(number), interp);

	public inline function abs():NxNumber
		return new NxNumber(Math.abs(number), interp);

	public inline function floor():NxInt
		return new NxInt(Std.int(Math.floor(number)), interp);

	public inline function ceil():NxInt
		return new NxInt(Std.int(Math.ceil(number)), interp);

	public inline function round():NxInt
		return new NxInt(Std.int(Math.round(number)), interp);

	public inline function min(v:Float):NxNumber
		return new NxNumber(Math.min(number, v), interp);

	public inline function max(v:Float):NxNumber
		return new NxNumber(Math.max(number, v), interp);

	public inline function sin():NxNumber
		return new NxNumber(Math.sin(number), interp);

	public inline function cos():NxNumber
		return new NxNumber(Math.cos(number), interp);

	public inline function tan():NxNumber
		return new NxNumber(Math.tan(number), interp);
}
