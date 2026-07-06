package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class VariableExpr implements Expr {
	public final nodeId:NodeId;
	public final name:String;
	public final namePosition:NxPosition;
	public final initializer:Null<Expr>;
	public final isConst:Bool;

	public function new(name:String, namePosition:NxPosition, initializer:Null<Expr> = null, isConst:Bool = false) {
		this.nodeId = NodeIdGenerator.next();
		this.name = name;
		this.namePosition = namePosition;
		this.initializer = initializer;
		this.isConst = isConst;
	}

	public function toString():String {
		var kind = isConst ? "Const" : "Variable";
		return initializer == null
			? '${kind}Expr(${name})'
			: '${kind}Expr(${name}, ${initializer})';
	}
}

