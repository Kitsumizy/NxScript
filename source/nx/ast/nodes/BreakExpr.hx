package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class BreakExpr implements Expr {
	public final nodeId:NodeId;
	public final position:NxPosition;

	public function new(position:NxPosition) {
		this.nodeId = NodeIdGenerator.next();
		this.position = position;
	}

	public function toString():String {
		return "BreakExpr()";
	}
}
