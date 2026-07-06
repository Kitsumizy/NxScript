package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class IndexExpr implements Expr {
	public final nodeId:NodeId;
	public final target:Expr;
	public final index:Expr;

	public function new(target:Expr, index:Expr) {
		this.nodeId = NodeIdGenerator.next();
		this.target = target;
		this.index = index;
	}

	public function toString():String {
		return 'IndexExpr(${target}, ${index})';
	}
}
