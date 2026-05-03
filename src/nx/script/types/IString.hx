package nx.script.types;

interface IString {
	public var text(default, null):String;
	public function upper():NxString;
	public function lower():NxString;
	public function trim():NxString;
	public function contains(part:String):Bool;
	public function startsWith(prefix:String):Bool;
	public function endsWith(suffix:String):Bool;
	public function indexOf(part:String):Int;
	public function replace(from:String, to:String):NxString;
	public function split(delim:String):Array<String>;
}
