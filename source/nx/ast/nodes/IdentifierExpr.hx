package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class IdentifierExpr implements Expr {
	public final nodeId:NodeId;
	public final name:String;
	public final position:NxPosition;

	public function new(name:String, position:NxPosition) {
		this.nodeId = NodeIdGenerator.next();
		this.name = name;
		this.position = position;
	}

	public function toString():String {
		return 'IdentifierExpr(${name})';
	}
}

