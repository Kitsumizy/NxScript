package nx.script.types;

interface INumber {
	public var number(default, null):Float;
	public function add(v:Float):NxNumber;
	public function sub(v:Float):NxNumber;
	public function mul(v:Float):NxNumber;
	public function div(v:Float):NxNumber;
	public function mod(v:Float):NxNumber;
	public function pow(exp:Float):NxNumber;
	public function sqrt():NxNumber;
	public function abs():NxNumber;
	public function floor():NxInt;
	public function ceil():NxInt;
	public function round():NxInt;
	public function min(v:Float):NxNumber;
	public function max(v:Float):NxNumber;
	public function sin():NxNumber;
	public function cos():NxNumber;
	public function tan():NxNumber;
}
