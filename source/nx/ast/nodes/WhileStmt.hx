package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.Statement;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class WhileStmt implements Statement {
	public final nodeId:NodeId;
	public final condition:Expr;
	public final body:Statement;

	public function new(condition:Expr, body:Statement) {
		this.nodeId = NodeIdGenerator.next();
		this.condition = condition;
		this.body = body;
	}

	public function toString():String {
		return 'WhileStmt(${condition}, ${body})';
	}
}

