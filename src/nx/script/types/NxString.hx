package nx.script.types;

import nx.script.Bytecode.Value;
import nx.script.Interpreter;
import StringTools;

class NxString extends NxObject implements IString {
	public var text(default, null):String;

	public function new(value:String, ?interp:Interpreter, ?rawValue:Value) {
		super(interp, rawValue != null ? rawValue : VString(value));
		this.text = value;
	}

	public inline function upper():NxString
		return new NxString(text.toUpperCase(), interp);

	public inline function lower():NxString
		return new NxString(text.toLowerCase(), interp);

	public inline function trim():NxString
		return new NxString(StringTools.trim(text), interp);

	public inline function contains(part:String):Bool
		return text.indexOf(part) >= 0;

	public inline function startsWith(prefix:String):Bool
		return StringTools.startsWith(text, prefix);

	public inline function endsWith(suffix:String):Bool
		return StringTools.endsWith(text, suffix);

	public inline function indexOf(part:String):Int
		return text.indexOf(part);

	public inline function replace(from:String, to:String):NxString
		return new NxString(StringTools.replace(text, from, to), interp);

	public function split(delim:String):Array<String>
		return text.split(delim);
}
