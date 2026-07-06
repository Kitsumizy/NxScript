package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class ReturnExpr implements Expr {
	public final nodeId:NodeId;
	public final value:Null<Expr>;

	public function new(value:Null<Expr> = null) {
		this.nodeId = NodeIdGenerator.next();
		this.value = value;
	}

	public function toString():String {
		return value == null ? 'ReturnExpr()' : 'ReturnExpr(${value})';
	}
}

