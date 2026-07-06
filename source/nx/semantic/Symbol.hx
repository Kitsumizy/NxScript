package nx.semantic;

class Symbol {
	public final name:String;
	public final kind:SymbolKind;
	public final scopeDepth:Int;
	public final arity:Null<Int>;
	public final isConst:Bool;
	public var captured:Bool;

	public function new(name:String, kind:SymbolKind, scopeDepth:Int, arity:Null<Int> = null, captured:Bool = false, isConst:Bool = false) {
		this.name = name;
		this.kind = kind;
		this.scopeDepth = scopeDepth;
		this.arity = arity;
		this.isConst = isConst;
		this.captured = captured;
	}

	public function label():String {
		var kindLabel = switch (kind) {
			case Builtin: "builtin";
			case Class: "class";
			case Field: isConst ? "field const" : "field";
			case Function: "function";
			case Variable: isConst ? "const" : "var";
			case Parameter: "param";
			case Undefined: "undefined";
		};

		var label = arity == null
			? '${kindLabel}:${name}'
			: '${kindLabel}:${name}/${arity}';

		if (captured && kind != Undefined)
			label += '^';

		return label;
	}

	public function toString():String {
		return label();
	}
}
