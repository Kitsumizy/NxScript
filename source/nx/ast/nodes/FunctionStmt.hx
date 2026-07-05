package nx.ast.nodes;

import nx.ast.Statement;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class FunctionStmt implements Statement {
	public final nodeId:NodeId;
	public final name:String;
	public final namePosition:NxPosition;
	public final params:Array<String>;
	public final body:BlockStmt;

	public function new(name:String, namePosition:NxPosition, params:Array<String>, body:BlockStmt) {
		this.nodeId = NodeIdGenerator.next();
		this.name = name;
		this.namePosition = namePosition;
		this.params = params;
		this.body = body;
	}

	public function toString():String {
		return 'FunctionStmt(${name}, [${params.join(", ")}], ${body})';
	}
}

