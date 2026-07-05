package nx.ir;

class IRBinding {
	public final name:String;
	public final address:IRAddress;
	public final arity:Null<Int>;

	public function new(name:String, address:IRAddress, ?arity:Int) {
		this.name = name;
		this.address = address;
		this.arity = arity;
	}

	public function toString():String {
		var arityLabel = arity == null ? "" : '/${arity}';
		return '${name}${arityLabel} ${Std.string(address)}';
	}
}
