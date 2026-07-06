package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class UnsupportedExpr implements Expr {
	public final nodeId:NodeId;
	public final message:String;
	public final position:NxPosition;

	public function new(message:String, position:NxPosition) {
		this.nodeId = NodeIdGenerator.next();
		this.message = message;
		this.position = position;
	}

	public function toString():String {
		return 'UnsupportedExpr(${message})';
	}
}
