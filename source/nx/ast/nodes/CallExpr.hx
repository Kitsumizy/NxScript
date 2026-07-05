package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;

class CallExpr implements Expr {
	public final nodeId:NodeId;
	public final callee:Expr;
	public final args:Array<Expr>;
    
	public function new(callee:Expr, args:Array<Expr>) {
		this.nodeId = NodeIdGenerator.next();
		this.callee = callee;
		this.args = args;
	}

	public function toString():String {
		return 'CallExpr(${callee}, [${args.join(", ")}])';
	}
}

