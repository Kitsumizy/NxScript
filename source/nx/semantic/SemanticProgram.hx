package nx.semantic;

import haxe.ds.IntMap;
import nx.common.NxError;
import nx.ast.Expr;
import nx.ast.Statement;
import nx.ast.nodes.*;

class SemanticProgram {

	public final statements:Array<Statement>;
	public final diagnostics:Array<NxError>;
	final annotations:IntMap<Symbol>;


	public function new(statements:Array<Statement>, annotations:IntMap<Symbol>, diagnostics:Array<NxError>) {
		this.statements = statements;
		this.annotations = annotations;
		this.diagnostics = diagnostics;
	}

	public function toString():String {
		var lines:Array<String> = ["Annotated AST"];

		for (i in 0...statements.length)
			appendStatement(lines, statements[i], "", i == statements.length - 1);

		if (diagnostics.length > 0) {
			lines.push("");
			lines.push("Diagnostics");

			for (diagnostic in diagnostics) {
				for (line in diagnostic.toString().split("\n"))
					lines.push(" ├─ " + line);
			}
		}

		return lines.join("\n");
	}

	public function symbolFor(nodeId:Int):Null<Symbol> {
		return annotations.get(nodeId);
	}

	function appendStatement(lines:Array<String>, statement:Statement, prefix:String, isLast:Bool):Void {
		var connector = isLast ? " └─ " : " ├─ ";
		var childPrefix = prefix + (isLast ? "    " : " │   ");

		if (Std.isOfType(statement, FunctionStmt)) {
			var fn:FunctionStmt = cast statement;
			lines.push(prefix + connector + 'Function ${fn.name}(${fn.params.join(", ")})${suffix(statement)}');
			appendStatement(lines, fn.body, childPrefix, true);
			return;
		}

		if (Std.isOfType(statement, BlockStmt)) {
			var block:BlockStmt = cast statement;
			lines.push(prefix + connector + 'Block${suffix(statement)}');

			for (i in 0...block.statements.length)
				appendStatement(lines, block.statements[i], childPrefix, i == block.statements.length - 1);

			return;
		}

		if (Std.isOfType(statement, ExpressionStmt)) {
			var exprStmt:ExpressionStmt = cast statement;
			lines.push(prefix + connector + formatExpr(exprStmt.expression) + suffix(statement));
			return;
		}

		if (Std.isOfType(statement, VariableStmt)) {
			var variable:VariableStmt = cast statement;
			var kind = variable.isConst ? "Const" : "Var";
			var label = '${kind} ${variable.name}';

			if (variable.initializer != null)
				label += ' = ${formatExpr(variable.initializer)}';

			lines.push(prefix + connector + label + suffix(statement));
			return;
		}

		if (Std.isOfType(statement, ReturnStmt)) {
			var ret:ReturnStmt = cast statement;
			lines.push(prefix + connector + (ret.value == null ? "Return" : 'Return ${formatExpr(ret.value)}') + suffix(statement));
			return;
		}

		if (Std.isOfType(statement, IfStmt)) {
			var ifStmt:IfStmt = cast statement;
			lines.push(prefix + connector + 'If ${formatExpr(ifStmt.condition)}' + suffix(statement));
			appendStatement(lines, ifStmt.thenBranch, childPrefix, ifStmt.elseBranch == null);

			if (ifStmt.elseBranch != null) {
				lines.push(prefix + " └─ Else");
				appendStatement(lines, ifStmt.elseBranch, prefix + "    ", true);
			}

			return;
		}

		if (Std.isOfType(statement, WhileStmt)) {
			var whileStmt:WhileStmt = cast statement;
			lines.push(prefix + connector + 'While ${formatExpr(whileStmt.condition)}' + suffix(statement));
			appendStatement(lines, whileStmt.body, childPrefix, true);
			return;
		}

		lines.push(prefix + connector + Std.string(statement) + suffix(statement));
	}

	function formatExpr(expr:Expr):String {
		if (Std.isOfType(expr, IdentifierExpr)) {
			var identifier:IdentifierExpr = cast expr;
			return identifier.name + symbolSuffix(expr);
		}

		if (Std.isOfType(expr, LiteralExpr)) {
			var literal:LiteralExpr = cast expr;
			return formatLiteral(literal.value);
		}

		if (Std.isOfType(expr, CallExpr)) {
			var call:CallExpr = cast expr;
			var args = [for (arg in call.args) formatExpr(arg)];
			return '${formatExpr(call.callee)}(${args.join(", ")})' + symbolSuffix(expr);
		}

		if (Std.isOfType(expr, BinaryExpr)) {
			var binary:BinaryExpr<Dynamic> = cast expr;
			return '${formatExpr(binary.left)} ${formatOperator(binary.op)} ${formatExpr(binary.right)}';
		}

		if (Std.isOfType(expr, UnaryExpr)) {
			var unary:UnaryExpr<Dynamic> = cast expr;
			return '${formatOperator(unary.op)}${formatExpr(unary.right)}';
		}

		return Std.string(expr);
	}

	function formatLiteral(value:Dynamic):String {
		if (value == null)
			return "null";

		switch (Type.typeof(value)) {
			case TClass(c):
				if (Type.getClassName(c) == "String")
					return '"${Std.string(value)}"';
			default:
		}

		return Std.string(value);
	}

	function formatOperator(op:Dynamic):String {
		return Std.string(op);
	}

	function suffix(node:Dynamic):String {
		var symbol = annotations.get(node.nodeId);
		return symbol == null ? "" : ' [${symbol.label()}]';
	}

	function symbolSuffix(node:Dynamic):String {
		var symbol = annotations.get(node.nodeId);
		return symbol == null ? "" : ' [${symbol.label()}]';
	}
}