package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.lexer.TokenType;

class BinaryExpr<K> implements Expr {
	public final nodeId:NodeId;
	public final left:Expr;
	public final op:TokenType<K>;
	public final right:Expr;

	public function new(left:Expr, op:TokenType<K>, right:Expr) {
		this.nodeId = NodeIdGenerator.next();
		this.left = left;
		this.op = op;
		this.right = right;
	}

	public function toString():String {
		return 'BinaryExpr(${left}, ${Std.string(op)}, ${right})';
	}
}

