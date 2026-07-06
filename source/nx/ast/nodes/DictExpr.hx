package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class DictExpr implements Expr {
	public final nodeId:NodeId;
	public final entries:Array<DictEntry>;

	public function new(entries:Array<DictEntry>) {
		this.nodeId = NodeIdGenerator.next();
		this.entries = entries;
	}

	public function toString():String {
		return 'DictExpr({${entries.join(", ")}})';
	}
}

class DictEntry {
	public final key:Expr;
	public final value:Expr;

	public function new(key:Expr, value:Expr) {
		this.key = key;
		this.value = value;
	}

	public function toString():String {
		return '${key}: ${value}';
	}
}
