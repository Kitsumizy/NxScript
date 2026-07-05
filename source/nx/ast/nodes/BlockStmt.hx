package nx.ast.nodes;

import nx.ast.Statement;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class BlockStmt implements Statement {
	public final nodeId:NodeId;
	public final statements:Array<Statement>;

	public function new(statements:Array<Statement>) {
		this.nodeId = NodeIdGenerator.next();
		this.statements = statements;
	}

	public function toString():String {
		return 'BlockStmt(${statements.join(", ")})';
	}
}

