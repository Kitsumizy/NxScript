package nx.semantic;

import haxe.ds.IntMap;
import nx.common.NxError;
import nx.common.NxPosition;
import nx.ast.Expr;
import nx.ast.nodes.*;
import nx.lexer.TokenType;
import nx.script.NxManager;
import nx.parser.Program;

class SemanticAnalyzer {
	public var analyzeTime(default, null):Float = 0;
	var annotations:IntMap<Symbol>;
	var diagnostics:Array<NxError>;
	var scopeStack:Array<Scope>;
	var builtinSymbols:Array<Symbol>;
	var loopDepth:Int;
	var classDepth:Int;

	public function new() {
		builtinSymbols = [
			new Symbol("trace", SymbolKind.Builtin, 0),
			new Symbol("call", SymbolKind.Builtin, 0),
		];
	}

	public function registerBuiltin(name:String, ?arity:Int):SemanticAnalyzer {
		builtinSymbols.push(new Symbol(name, SymbolKind.Builtin, 0, arity));
		return this;
	}

	public function registerBuiltins(names:Array<String>):SemanticAnalyzer {
		for (name in names)
			registerBuiltin(name);

		return this;
	}

	public function analyze(program:Program):SemanticProgram {
		analyzeTime = haxe.Timer.stamp();
		annotations = new IntMap<Symbol>();
		diagnostics = [];
		scopeStack = [];
		loopDepth = 0;
		classDepth = 0;

		pushScope();
		seedBuiltins(currentScope());

		analyzeTopLevelExprs(program.exprs);
		analyzeTime = haxe.Timer.stamp() - analyzeTime;
		return new SemanticProgram(program.exprs, annotations, diagnostics);
	}

	public inline function currentScope():Scope {
		return scopeStack[scopeStack.length - 1];
	}

	function pushScope():Scope {
		var parent = scopeStack.length == 0 ? null : currentScope();
		var scope = new Scope(parent);
		scopeStack.push(scope);
		return scope;
	}

	function popScope():Scope {
		return scopeStack.pop();
	}

	function seedBuiltins(scope:Scope):Void {
		for (builtin in builtinSymbols)
			scope.declare(new Symbol(builtin.name, builtin.kind, scope.depth, builtin.arity, builtin.captured, builtin.isConst));
	}

	function registerFunctionExprs(exprs:Array<Expr>):Void {
		var scope = currentScope();
		for (expr in exprs) {
			if (Std.isOfType(expr, ClassExpr)) {
				var classExpr:ClassExpr = cast expr;
				var symbol = new Symbol(classExpr.name, SymbolKind.Class, scope.depth);
				if (!scope.declare(symbol))
					reportError('Duplicate class ${classExpr.name}', classExpr.namePosition);
				else
					annotations.set(expr.nodeId, symbol);
			}

			if (Std.isOfType(expr, FunctionExpr)) {
				var fn:FunctionExpr = cast expr;
				var symbol = new Symbol(fn.name, SymbolKind.Function, scope.depth, fn.params.length);
				if (!scope.declare(symbol))
					reportError('Duplicate function ${fn.name}', fn.namePosition);
				else
					annotations.set(expr.nodeId, symbol);
			}
		}
	}

	function analyzeTopLevelExprs(exprs:Array<Expr>):Void {
		registerFunctionExprs(exprs);
		for (expr in exprs)
			analyzeTopLevelExpr(expr);
	}

	function analyzeTopLevelExpr(expr:Expr):Void {
		if (Std.isOfType(expr, ClassExpr)) {
			var classExpr:ClassExpr = cast expr;
			var symbol = currentScope().resolveLocal(classExpr.name);
			if (symbol != null)
				annotations.set(expr.nodeId, symbol);

			pushScope();
			classDepth++;
			currentScope().declare(new Symbol("this", SymbolKind.Parameter, currentScope().depth));
			registerClassFields(classExpr);
			registerFunctionExprs(classExpr.members);
			for (member in classExpr.members)
				analyzeTopLevelExpr(member);
			classDepth--;
			popScope();
			return;
		}

		if (Std.isOfType(expr, FunctionExpr)) {
			var fn:FunctionExpr = cast expr;
			var symbol = currentScope().resolveLocal(fn.name);
			if (symbol == null) {
				symbol = new Symbol(fn.name, SymbolKind.Function, currentScope().depth, fn.params.length);
				currentScope().declare(symbol);
			}

			annotations.set(expr.nodeId, symbol);

			pushScope();
			for (param in fn.params) {
				if (!currentScope().declare(new Symbol(param, SymbolKind.Parameter, currentScope().depth)))
					reportError('Duplicate parameter ${param}', fn.namePosition);
			}

			analyzeBlock(fn.body);
			popScope();
			return;
		}

		if (Std.isOfType(expr, BlockExpr)) {
			analyzeBlock(cast expr);
			return;
		}

		if (Std.isOfType(expr, ExpressionExpr)) {
			var exprStmt:ExpressionExpr = cast expr;
			analyzeExpr(exprStmt.expression);
			return;
		}

		if (Std.isOfType(expr, VariableExpr)) {
			var variable:VariableExpr = cast expr;
			if (variable.initializer != null)
				analyzeExpr(variable.initializer);

			if (classDepth > 0) {
				var field = currentScope().resolveLocal(variable.name);
				if (field != null && field.kind == SymbolKind.Field)
					annotations.set(expr.nodeId, field);
				else {
					var symbol = new Symbol(variable.name, SymbolKind.Field, currentScope().depth, null, false, variable.isConst);
					if (!currentScope().declare(symbol))
						reportError('Duplicate field ${variable.name}', variable.namePosition);
					else
						annotations.set(expr.nodeId, symbol);
				}
			} else {
				var symbol = new Symbol(variable.name, SymbolKind.Variable, currentScope().depth, null, false, variable.isConst);
				if (!currentScope().declare(symbol))
					reportError('Duplicate variable ${variable.name}', variable.namePosition);
				else
					annotations.set(expr.nodeId, symbol);
			}

			return;
		}

		if (Std.isOfType(expr, IfExpr)) {
			var ifExpr:IfExpr = cast expr;
			analyzeExpr(ifExpr.condition);
			analyzeTopLevelExpr(ifExpr.thenBranch);
			if (ifExpr.elseBranch != null)
				analyzeTopLevelExpr(ifExpr.elseBranch);
			return;
		}

		if (Std.isOfType(expr, WhileExpr)) {
			var whileExpr:WhileExpr = cast expr;
			analyzeExpr(whileExpr.condition);
			loopDepth++;
			analyzeTopLevelExpr(whileExpr.body);
			loopDepth--;
			return;
		}

		if (Std.isOfType(expr, ForExpr)) {
			analyzeFor(cast expr);
			return;
		}

		if (Std.isOfType(expr, BreakExpr)) {
			var breakExpr:BreakExpr = cast expr;
			if (loopDepth == 0)
				reportError("'break' can only be used inside a loop.", breakExpr.position);
			return;
		}

		if (Std.isOfType(expr, ContinueExpr)) {
			var continueExpr:ContinueExpr = cast expr;
			if (loopDepth == 0)
				reportError("'continue' can only be used inside a loop.", continueExpr.position);
			return;
		}

		if (Std.isOfType(expr, ReturnExpr)) {
			var returnExpr:ReturnExpr = cast expr;
			if (returnExpr.value != null)
				analyzeExpr(returnExpr.value);
			return;
		}

		if (Std.isOfType(expr, ThrowExpr)) {
			var throwExpr:ThrowExpr = cast expr;
			analyzeExpr(throwExpr.value);
			return;
		}

		if (Std.isOfType(expr, TryCatchExpr)) {
			analyzeTryCatch(cast expr);
			return;
		}

		if (Std.isOfType(expr, MatchExpr)) {
			analyzeMatch(cast expr);
			return;
		}

		if (Std.isOfType(expr, UnsupportedExpr)) {
			var unsupported:UnsupportedExpr = cast expr;
			reportError(unsupported.message, unsupported.position);
			return;
		}

		analyzeExpr(expr);
	}

	function analyzeBlock(block:BlockExpr):Void {
		pushScope();
		registerFunctionExprs(block.exprs);
		for (expr in block.exprs)
			analyzeTopLevelExpr(expr);
		popScope();
	}

	function registerClassFields(classExpr:ClassExpr):Void {
		for (member in classExpr.members) {
			if (!Std.isOfType(member, VariableExpr))
				continue;

			var field:VariableExpr = cast member;
			var symbol = new Symbol(field.name, SymbolKind.Field, currentScope().depth, null, false, field.isConst);
			if (!currentScope().declare(symbol))
				reportError('Duplicate field ${field.name}', field.namePosition);
			else
				annotations.set(member.nodeId, symbol);
		}
	}

	function analyzeFor(forExpr:ForExpr):Void {
		pushScope();

		if (forExpr.initializer != null)
			analyzeTopLevelExpr(forExpr.initializer);

		if (forExpr.condition != null)
			analyzeExpr(forExpr.condition);

		if (forExpr.increment != null)
			analyzeExpr(forExpr.increment);

		loopDepth++;
		analyzeTopLevelExpr(forExpr.body);
		loopDepth--;

		popScope();
	}

	function analyzeTryCatch(tryCatch:TryCatchExpr):Void {
		analyzeTopLevelExpr(tryCatch.tryBody);
		pushScope();
		currentScope().declare(new Symbol(tryCatch.errorName, SymbolKind.Variable, currentScope().depth));
		analyzeTopLevelExpr(tryCatch.catchBody);
		popScope();
	}

	function analyzeMatch(matchExpr:MatchExpr):Void {
		analyzeExpr(matchExpr.target);
		for (matchCase in matchExpr.cases) {
			analyzeExpr(matchCase.pattern);
			analyzeTopLevelExpr(matchCase.body);
		}

		if (matchExpr.defaultBranch != null)
			analyzeTopLevelExpr(matchExpr.defaultBranch);
	}

	function analyzeExpr(expr:Expr):Void {
		if (Std.isOfType(expr, IdentifierExpr)) {
			var identifier:IdentifierExpr = cast expr;
			var symbol = currentScope().resolve(identifier.name);
			if (symbol == null) {
				var suggestion = currentScope().suggest(identifier.name, 0.7);
				var undefinedSymbol = new Symbol(identifier.name, SymbolKind.Undefined, -1);
				annotations.set(expr.nodeId, undefinedSymbol);
				reportError(formatUndefinedMessage(identifier.name, suggestion), identifier.position);
				return;
			}

			if (symbol.kind != SymbolKind.Builtin && symbol.kind != SymbolKind.Undefined && symbol.scopeDepth < currentScope().depth)
				symbol.captured = true;

			annotations.set(expr.nodeId, symbol);
			return;
		}

		if (Std.isOfType(expr, CallExpr)) {
			var call:CallExpr = cast expr;
			analyzeExpr(call.callee);
			for (arg in call.args)
				analyzeExpr(arg);

			var resolved = resolveSymbolFromExpr(call.callee);
			if (resolved != null)
				annotations.set(expr.nodeId, resolved);
			return;
		}

		if (Std.isOfType(expr, BinaryExpr)) {
			var binary:BinaryExpr<Dynamic> = cast expr;
			if (isAssignmentOperator(binary.op)) {
				analyzeAssignment(binary);
				return;
			}

			analyzeExpr(binary.left);
			analyzeExpr(binary.right);
			return;
		}

		if (Std.isOfType(expr, NewExpr)) {
			var newExpr:NewExpr = cast expr;
			analyzeExpr(newExpr.callee);
			for (arg in newExpr.args)
				analyzeExpr(arg);
			return;
		}

		if (Std.isOfType(expr, UnaryExpr)) {
			var unary:UnaryExpr<Dynamic> = cast expr;
			analyzeExpr(unary.right);
			return;
		}

		if (Std.isOfType(expr, ArrayExpr)) {
			var arrayExpr:ArrayExpr = cast expr;
			for (element in arrayExpr.elements)
				analyzeExpr(element);
			return;
		}

		if (Std.isOfType(expr, DictExpr)) {
			var dictExpr:DictExpr = cast expr;
			for (entry in dictExpr.entries) {
				analyzeExpr(entry.key);
				analyzeExpr(entry.value);
			}
			return;
		}

		if (Std.isOfType(expr, IndexExpr)) {
			var indexExpr:IndexExpr = cast expr;
			analyzeExpr(indexExpr.target);
			analyzeExpr(indexExpr.index);
			return;
		}

		if (Std.isOfType(expr, MemberExpr)) {
			var memberExpr:MemberExpr = cast expr;
			analyzeExpr(memberExpr.target);
			return;
		}

		if (Std.isOfType(expr, TemplateExpr)) {
			var templateExpr:TemplateExpr = cast expr;
			for (part in templateExpr.parts)
				analyzeExpr(part);
			return;
		}

		if (Std.isOfType(expr, UnsupportedExpr)) {
			var unsupported:UnsupportedExpr = cast expr;
			reportError(unsupported.message, unsupported.position);
			return;
		}
	}

	function resolveSymbolFromExpr(expr:Expr):Null<Symbol> {
		return annotations.get(expr.nodeId);
	}

	function analyzeAssignment(binary:BinaryExpr<Dynamic>):Void {
		analyzeExpr(binary.right);

		if (!Std.isOfType(binary.left, IdentifierExpr)) {
			reportError("Invalid assignment target.", syntheticPosition());
			analyzeExpr(binary.left);
			return;
		}

		var identifier:IdentifierExpr = cast binary.left;
		analyzeExpr(identifier);
		var symbol = resolveSymbolFromExpr(identifier);
		if (symbol == null || symbol.kind == SymbolKind.Undefined)
			return;

		if (symbol.kind != SymbolKind.Variable && symbol.kind != SymbolKind.Parameter && symbol.kind != SymbolKind.Field) {
			reportError('Cannot assign to ${symbol.kind}.', identifier.position);
			return;
		}

		if (symbol.isConst)
			reportError('Cannot reassign const ${symbol.name}.', identifier.position);
	}

	function isAssignmentOperator(op:TokenType<Dynamic>):Bool {
		return switch (op) {
			case Equal | PlusEqual | MinusEqual | StarEqual | SlashEqual: true;
			default: false;
		}
	}

	function reportError(message:String, position:NxPosition):Void {
		var error = new NxError(message, position);
		diagnostics.push(error);
		NxManager.onException.emit(error);
	}

	function formatUndefinedMessage(name:String, suggestion:Null<Symbol>):String {
		if (suggestion == null)
			return 'Undefined symbol ${name}';

		return 'Undefined symbol ${name}. Did you mean "${suggestion.name}"?';
	}

	function syntheticPosition():NxPosition {
		return new NxPosition(1, 1, 0, "<semantic>", "");
	}

}
