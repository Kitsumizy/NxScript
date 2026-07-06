package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class TemplateExpr implements Expr {
	public final nodeId:NodeId;
	public final parts:Array<Expr>;

	public function new(parts:Array<Expr>) {
		this.nodeId = NodeIdGenerator.next();
		this.parts = parts;
	}
}
