package nx.ast.nodes;

import nx.ast.Expr;
import nx.ast.NodeId;
import nx.ast.NodeIdGenerator;
import nx.common.NxPosition;

class TryCatchExpr implements Expr {
	public final nodeId:NodeId;
	public final tryBody:Expr;
	public final errorName:String;
	public final errorPosition:NxPosition;
	public final catchBody:Expr;

	public function new(tryBody:Expr, errorName:String, errorPosition:NxPosition, catchBody:Expr) {
		this.nodeId = NodeIdGenerator.next();
		this.tryBody = tryBody;
		this.errorName = errorName;
		this.errorPosition = errorPosition;
		this.catchBody = catchBody;
	}
}
