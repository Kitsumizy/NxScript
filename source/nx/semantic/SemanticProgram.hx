package nx.semantic;

import haxe.ds.IntMap;
import nx.common.NxError;
import nx.ast.Expr;
import nx.ast.nodes.*;

class SemanticProgram {

	public final exprs:Array<Expr>;
	public final diagnostics:Array<NxError>;
	final annotations:IntMap<Symbol>;


	public function new(exprs:Array<Expr>, annotations:IntMap<Symbol>, diagnostics:Array<NxError>) {
		this.exprs = exprs;
		this.annotations = annotations;
		this.diagnostics = diagnostics;
	}

	public function toString():String {
		var lines:Array<String> = ["Annotated AST"];

		for (i in 0...exprs.length)
			appendTopLevelExpr(lines, exprs[i], "", i == exprs.length - 1);

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

	function appendTopLevelExpr(lines:Array<String>, expr:Expr, prefix:String, isLast:Bool):Void {
		var connector = isLast ? " └─ " : " ├─ ";
		var childPrefix = prefix + (isLast ? "    " : " │   ");

		if (Std.isOfType(expr, FunctionExpr)) {
			var fn:FunctionExpr = cast expr;
			lines.push(prefix + connector + 'Function ${fn.name}(${fn.params.join(", ")})${suffix(expr)}');
			appendTopLevelExpr(lines, fn.body, childPrefix, true);
			return;
		}

		if (Std.isOfType(expr, BlockExpr)) {
			var block:BlockExpr = cast expr;
			lines.push(prefix + connector + 'Block${suffix(expr)}');

			for (i in 0...block.exprs.length)
				appendTopLevelExpr(lines, block.exprs[i], childPrefix, i == block.exprs.length - 1);

			return;
		}

		if (Std.isOfType(expr, ExpressionExpr)) {
			var exprStmt:ExpressionExpr = cast expr;
			lines.push(prefix + connector + formatExpr(exprStmt.expression) + suffix(expr));
			return;
		}

		if (Std.isOfType(expr, VariableExpr)) {
			var variable:VariableExpr = cast expr;
			var kind = variable.isConst ? "Const" : "Var";
			var label = '${kind} ${variable.name}';

			if (variable.initializer != null)
				label += ' = ${formatExpr(variable.initializer)}';

			lines.push(prefix + connector + label + suffix(expr));
			return;
		}

		if (Std.isOfType(expr, ReturnExpr)) {
			var ret:ReturnExpr = cast expr;
			lines.push(prefix + connector + (ret.value == null ? "Return" : 'Return ${formatExpr(ret.value)}') + suffix(expr));
			return;
		}

		if (Std.isOfType(expr, IfExpr)) {
			var ifExpr:IfExpr = cast expr;
			lines.push(prefix + connector + 'If ${formatExpr(ifExpr.condition)}' + suffix(expr));
			appendTopLevelExpr(lines, ifExpr.thenBranch, childPrefix, ifExpr.elseBranch == null);

			if (ifExpr.elseBranch != null) {
				lines.push(prefix + " └─ Else");
				appendTopLevelExpr(lines, ifExpr.elseBranch, prefix + "    ", true);
			}

			return;
		}

		if (Std.isOfType(expr, WhileExpr)) {
			var whileExpr:WhileExpr = cast expr;
			lines.push(prefix + connector + 'While ${formatExpr(whileExpr.condition)}' + suffix(expr));
			appendTopLevelExpr(lines, whileExpr.body, childPrefix, true);
			return;
		}

		if (Std.isOfType(expr, ForExpr)) {
			var forExpr:ForExpr = cast expr;
			lines.push(prefix + connector + 'For${suffix(expr)}');
			if (forExpr.initializer != null)
				lines.push(childPrefix + "init " + formatExpr(forExpr.initializer));
			if (forExpr.condition != null)
				lines.push(childPrefix + "cond " + formatExpr(forExpr.condition));
			if (forExpr.increment != null)
				lines.push(childPrefix + "inc " + formatExpr(forExpr.increment));
			appendTopLevelExpr(lines, forExpr.body, childPrefix, true);
			return;
		}

		if (Std.isOfType(expr, BreakExpr)) {
			lines.push(prefix + connector + 'Break${suffix(expr)}');
			return;
		}

		if (Std.isOfType(expr, ContinueExpr)) {
			lines.push(prefix + connector + 'Continue${suffix(expr)}');
			return;
		}

		if (Std.isOfType(expr, UnsupportedExpr)) {
			var unsupported:UnsupportedExpr = cast expr;
			lines.push(prefix + connector + 'Unsupported ${unsupported.message}${suffix(expr)}');
			return;
		}

		lines.push(prefix + connector + Std.string(expr) + suffix(expr));
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

		if (Std.isOfType(expr, ArrayExpr)) {
			var arrayExpr:ArrayExpr = cast expr;
			return '[${[for (element in arrayExpr.elements) formatExpr(element)].join(", ")}]';
		}

		if (Std.isOfType(expr, DictExpr)) {
			var dictExpr:DictExpr = cast expr;
			return '{${[for (entry in dictExpr.entries) formatExpr(entry.key) + ": " + formatExpr(entry.value)].join(", ")}}';
		}

		if (Std.isOfType(expr, IndexExpr)) {
			var indexExpr:IndexExpr = cast expr;
			return '${formatExpr(indexExpr.target)}[${formatExpr(indexExpr.index)}]';
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
