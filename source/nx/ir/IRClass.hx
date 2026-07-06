package nx.ir;

class IRClass {
	public final id:Int;
	public final name:String;
	public final fields:Array<IRField>;
	public final methods:Array<IRMethod>;

	public function new(id:Int, name:String, fields:Array<IRField>, methods:Array<IRMethod>) {
		this.id = id;
		this.name = name;
		this.fields = fields;
		this.methods = methods;
	}
}

class IRField {
	public final name:String;
	public final initializer:Array<IRInstruction>;

	public function new(name:String, initializer:Array<IRInstruction>) {
		this.name = name;
		this.initializer = initializer;
	}
}

class IRMethod {
	public final name:String;
	public final target:IRCallTarget;

	public function new(name:String, target:IRCallTarget) {
		this.name = name;
		this.target = target;
	}
}
