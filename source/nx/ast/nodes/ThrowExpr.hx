package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class ThrowExpr implements Expr {
	public final nodeId:NodeId;
	public final value:Expr;
	public final position:NxPosition;

	public function new(value:Expr, position:NxPosition) {
		this.nodeId = NodeIdGenerator.next();
		this.value = value;
		this.position = position;
	}
}
