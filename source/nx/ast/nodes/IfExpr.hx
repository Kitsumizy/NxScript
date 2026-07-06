package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class IfExpr implements Expr {
	public final nodeId:NodeId;
	public final condition:Expr;
	public final thenBranch:Expr;
	public final elseBranch:Null<Expr>;

	public function new(condition:Expr, thenBranch:Expr, elseBranch:Null<Expr> = null) {
		this.nodeId = NodeIdGenerator.next();
		this.condition = condition;
		this.thenBranch = thenBranch;
		this.elseBranch = elseBranch;
	}

	public function toString():String {
		return elseBranch == null
			? 'IfExpr(${condition}, ${thenBranch})'
			: 'IfExpr(${condition}, ${thenBranch}, ${elseBranch})';
	}
}

