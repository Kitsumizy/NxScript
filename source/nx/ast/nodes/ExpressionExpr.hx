package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class ExpressionExpr implements Expr {
	public final nodeId:NodeId;
	public final expression:Expr;

	public function new(expression:Expr) {
		this.nodeId = NodeIdGenerator.next();
		this.expression = expression;
	}

	public function toString():String {
		return 'ExpressionExpr(${expression})';
	}
}