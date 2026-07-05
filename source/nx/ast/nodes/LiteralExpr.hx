package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class LiteralExpr implements Expr {
	public final nodeId:NodeId;
	public final value:Dynamic;

	public function new(value:Dynamic) {
		this.nodeId = NodeIdGenerator.next();
		this.value = value;
	}

	public function toString():String {
		if (value == null)
			return 'LiteralExpr(null)';

		if (Std.isOfType(value, String))
			return 'LiteralExpr("' + Std.string(value) + '")';

		return 'LiteralExpr(${Std.string(value)})';
	}
}

