package nx.semantic;

import haxe.ds.IntMap;
import nx.common.NxError;
import nx.common.NxPosition;
import nx.ast.Expr;
import nx.ast.Statement;
import nx.ast.nodes.*;
import nx.script.NxManager;
import nx.parser.Program;

class SemanticAnalyzer {
	public var analyzeTime(default, null):Float = 0;
	var annotations:IntMap<Symbol>;
	var diagnostics:Array<NxError>;
	var scopeStack:Array<Scope>;
	var builtinSymbols:Array<Symbol>;

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

		pushScope();
		seedBuiltins(currentScope());

		analyzeStatements(program.statements);
		analyzeTime = haxe.Timer.stamp() - analyzeTime;
		return new SemanticProgram(program.statements, annotations, diagnostics);
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
			scope.declare(new Symbol(builtin.name, builtin.kind, scope.depth, builtin.arity, builtin.captured));
	}

	function registerFunctionDeclarations(statements:Array<Statement>):Void {
		var scope = currentScope();
		for (statement in statements) {
			if (Std.isOfType(statement, FunctionStmt)) {
				var fn:FunctionStmt = cast statement;
				var symbol = new Symbol(fn.name, SymbolKind.Function, scope.depth, fn.params.length);
				if (!scope.declare(symbol))
					reportError('Duplicate function ${fn.name}', fn.namePosition);
				else
					annotations.set(statement.nodeId, symbol);
			}
		}
	}

	function analyzeStatements(statements:Array<Statement>):Void {
		registerFunctionDeclarations(statements);
		for (statement in statements)
			analyzeStatement(statement);
	}

	function analyzeStatement(statement:Statement):Void {
		if (Std.isOfType(statement, FunctionStmt)) {
			var fn:FunctionStmt = cast statement;
			var symbol = currentScope().resolveLocal(fn.name);
			if (symbol == null) {
				symbol = new Symbol(fn.name, SymbolKind.Function, currentScope().depth, fn.params.length);
				currentScope().declare(symbol);
			}

			annotations.set(statement.nodeId, symbol);

			pushScope();
			for (param in fn.params) {
				if (!currentScope().declare(new Symbol(param, SymbolKind.Parameter, currentScope().depth)))
					reportError('Duplicate parameter ${param}', fn.namePosition);
			}

			analyzeBlock(fn.body);
			popScope();
			return;
		}

		if (Std.isOfType(statement, BlockStmt)) {
			analyzeBlock(cast statement);
			return;
		}

		if (Std.isOfType(statement, ExpressionStmt)) {
			var exprStmt:ExpressionStmt = cast statement;
			analyzeExpr(exprStmt.expression);
			return;
		}

		if (Std.isOfType(statement, VariableStmt)) {
			var variable:VariableStmt = cast statement;
			if (variable.initializer != null)
				analyzeExpr(variable.initializer);

			var symbol = new Symbol(variable.name, SymbolKind.Variable, currentScope().depth);
			if (!currentScope().declare(symbol))
				reportError('Duplicate variable ${variable.name}', variable.namePosition);
			else
				annotations.set(statement.nodeId, symbol);

			return;
		}

		if (Std.isOfType(statement, IfStmt)) {
			var ifStmt:IfStmt = cast statement;
			analyzeExpr(ifStmt.condition);
			analyzeStatement(ifStmt.thenBranch);
			if (ifStmt.elseBranch != null)
				analyzeStatement(ifStmt.elseBranch);
			return;
		}

		if (Std.isOfType(statement, WhileStmt)) {
			var whileStmt:WhileStmt = cast statement;
			analyzeExpr(whileStmt.condition);
			analyzeStatement(whileStmt.body);
			return;
		}

		if (Std.isOfType(statement, ReturnStmt)) {
			var returnStmt:ReturnStmt = cast statement;
			if (returnStmt.value != null)
				analyzeExpr(returnStmt.value);
			return;
		}
	}

	function analyzeBlock(block:BlockStmt):Void {
		pushScope();
		registerFunctionDeclarations(block.statements);
		for (statement in block.statements)
			analyzeStatement(statement);
		popScope();
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
			analyzeExpr(binary.left);
			analyzeExpr(binary.right);
			return;
		}

		if (Std.isOfType(expr, UnaryExpr)) {
			var unary:UnaryExpr<Dynamic> = cast expr;
			analyzeExpr(unary.right);
			return;
		}
	}

	function resolveSymbolFromExpr(expr:Expr):Null<Symbol> {
		return annotations.get(expr.nodeId);
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

}