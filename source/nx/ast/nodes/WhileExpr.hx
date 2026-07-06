package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class WhileExpr implements Expr {
	public final nodeId:NodeId;
	public final condition:Expr;
	public final body:Expr;

	public function new(condition:Expr, body:Expr) {
		this.nodeId = NodeIdGenerator.next();
		this.condition = condition;
		this.body = body;
	}

	public function toString():String {
		return 'WhileExpr(${condition}, ${body})';
	}
}

