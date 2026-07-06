package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class BlockExpr implements Expr {
	public final nodeId:NodeId;
	public final exprs:Array<Expr>;

	public function new(exprs:Array<Expr>) {
		this.nodeId = NodeIdGenerator.next();
		this.exprs = exprs;
	}

	public function toString():String {
		return 'BlockExpr(${exprs.join(", ")})';
	}
}

