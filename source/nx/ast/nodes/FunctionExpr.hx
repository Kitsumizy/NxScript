package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class FunctionExpr implements Expr {
	public final nodeId:NodeId;
	public final name:String;
	public final namePosition:NxPosition;
	public final params:Array<String>;
	public final body:BlockExpr;

	public function new(name:String, namePosition:NxPosition, params:Array<String>, body:BlockExpr) {
		this.nodeId = NodeIdGenerator.next();
		this.name = name;
		this.namePosition = namePosition;
		this.params = params;
		this.body = body;
	}

	public function toString():String {
		return 'FunctionExpr(${name}, [${params.join(", ")}], ${body})';
	}
}

