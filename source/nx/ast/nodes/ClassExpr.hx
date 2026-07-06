package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class ClassExpr implements Expr {
	public final nodeId:NodeId;
	public final name:String;
	public final namePosition:NxPosition;
	public final members:Array<Expr>;

	public function new(name:String, namePosition:NxPosition, members:Array<Expr>) {
		this.nodeId = NodeIdGenerator.next();
		this.name = name;
		this.namePosition = namePosition;
		this.members = members;
	}
}
