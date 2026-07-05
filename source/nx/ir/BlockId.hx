package nx.ir;

class BlockId {
	public final name:String;

	public function new(name:String) {
		this.name = name;
	}

	public function toString():String {
		return 'Block(${name})';
	}
}

