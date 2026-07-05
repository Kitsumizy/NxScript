package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.Statement;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class IfStmt implements Statement {
	public final nodeId:NodeId;
	public final condition:Expr;
	public final thenBranch:Statement;
	public final elseBranch:Null<Statement>;

	public function new(condition:Expr, thenBranch:Statement, elseBranch:Null<Statement> = null) {
		this.nodeId = NodeIdGenerator.next();
		this.condition = condition;
		this.thenBranch = thenBranch;
		this.elseBranch = elseBranch;
	}

	public function toString():String {
		return elseBranch == null
			? 'IfStmt(${condition}, ${thenBranch})'
			: 'IfStmt(${condition}, ${thenBranch}, ${elseBranch})';
	}
}

