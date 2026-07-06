package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class NewExpr implements Expr {
	public final nodeId:NodeId;
	public final callee:Expr;
	public final args:Array<Expr>;
	public final position:NxPosition;

	public function new(callee:Expr, args:Array<Expr>, position:NxPosition) {
		this.nodeId = NodeIdGenerator.next();
		this.callee = callee;
		this.args = args;
		this.position = position;
	}
}
