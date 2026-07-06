package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class ArrayExpr implements Expr {
	public final nodeId:NodeId;
	public final elements:Array<Expr>;

	public function new(elements:Array<Expr>) {
		this.nodeId = NodeIdGenerator.next();
		this.elements = elements;
	}

	public function toString():String {
		return 'ArrayExpr([${elements.join(", ")}])';
	}
}
