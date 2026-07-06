package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class ForExpr implements Expr {
	public final nodeId:NodeId;
	public final initializer:Null<Expr>;
	public final condition:Null<Expr>;
	public final increment:Null<Expr>;
	public final body:Expr;

	public function new(initializer:Null<Expr>, condition:Null<Expr>, increment:Null<Expr>, body:Expr) {
		this.nodeId = NodeIdGenerator.next();
		this.initializer = initializer;
		this.condition = condition;
		this.increment = increment;
		this.body = body;
	}

	public function toString():String {
		return 'ForExpr(${initializer}, ${condition}, ${increment}, ${body})';
	}
}
