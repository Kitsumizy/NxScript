package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class MemberExpr implements Expr {
	public final nodeId:NodeId;
	public final target:Expr;
	public final name:String;
	public final namePosition:NxPosition;
	public final optional:Bool;

	public function new(target:Expr, name:String, namePosition:NxPosition, optional:Bool = false) {
		this.nodeId = NodeIdGenerator.next();
		this.target = target;
		this.name = name;
		this.namePosition = namePosition;
		this.optional = optional;
	}
}
