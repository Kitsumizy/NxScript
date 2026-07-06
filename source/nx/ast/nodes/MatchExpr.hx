package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class MatchExpr implements Expr {
	public final nodeId:NodeId;
	public final target:Expr;
	public final cases:Array<MatchCase>;
	public final defaultBranch:Null<Expr>;

	public function new(target:Expr, cases:Array<MatchCase>, defaultBranch:Null<Expr>) {
		this.nodeId = NodeIdGenerator.next();
		this.target = target;
		this.cases = cases;
		this.defaultBranch = defaultBranch;
	}
}

class MatchCase {
	public final pattern:Expr;
	public final body:Expr;

	public function new(pattern:Expr, body:Expr) {
		this.pattern = pattern;
		this.body = body;
	}
}
