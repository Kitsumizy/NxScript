package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.lexer.TokenType;

class UnaryExpr<K> implements Expr {
	public final nodeId:NodeId;
	public final op:TokenType<K>;
	public final right:Expr;

	public function new(op:TokenType<K>, right:Expr) {
		this.nodeId = NodeIdGenerator.next();
		this.op = op;
		this.right = right;
	}

	public function toString():String {
		return 'UnaryExpr(${Std.string(op)}, ${right})';
	}
}

