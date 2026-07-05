package nx.ir;

import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import nx.common.NxError;
import nx.common.NxPosition;
import nx.ast.Expr;
import nx.ast.Statement;
import nx.ast.nodes.*;
import nx.semantic.SemanticProgram;
import nx.semantic.Symbol;
import nx.semantic.SymbolKind;
import nx.script.NxManager;

class IRBuilder {
	var out:Array<IRInstruction>;
	var functions:Array<IRFunction>;
	var bindings:Array<IRBinding>;
	var bindingBySymbol:ObjectMap<Symbol, IRBinding>;
	var builtinSlots:StringMap<Int>;
	var labelCounter:Int;
	var nextGlobalSlot:Int;
	var nextBuiltinId:Int;
	var currentProgram:SemanticProgram;
	var currentFrame:IRFrameLayout;
	var scriptFrame:IRFrameLayout;
	var failed:Bool;

	public function new() {}

	public function build(program:SemanticProgram):IRProgram {
		var startTime = haxe.Timer.stamp();
		currentProgram = program;
		out = [];
		functions = [];
		bindings = [];
		bindingBySymbol = new ObjectMap();
		builtinSlots = new StringMap();
		labelCounter = 0;
		nextGlobalSlot = 0;
		nextBuiltinId = 0;
		failed = false;
		scriptFrame = new IRFrameLayout("script", 0);
		currentFrame = scriptFrame;

		if (program.diagnostics.length > 0) {
			reportError(
				'Cannot build IR: semantic analysis produced ${program.diagnostics.length} diagnostic(s).',
				program.diagnostics[0].infopos
			);
			return emptyProgram();
		}

		predeclareFunctions(program.statements);

		for (statement in program.statements)
			emitStatement(statement, out);

		if (failed)
			return emptyProgram();

		var buildTime = haxe.Timer.stamp() - startTime;
		return new IRProgram(functions, out, nextGlobalSlot, scriptFrame.localCount, buildTime);
	}

	function predeclareFunctions(statements:Array<Statement>):Void {
		for (statement in statements) {
			if (Std.isOfType(statement, FunctionStmt)) {
				var symbol = currentProgram.symbolFor(statement.nodeId);
				if (symbol != null)
					ensureBinding(symbol);
			}

			if (Std.isOfType(statement, BlockStmt))
				predeclareFunctions((cast statement : BlockStmt).statements);
		}
	}

	function emitStatement(statement:Statement, into:Array<IRInstruction>):Void {
		if (Std.isOfType(statement, FunctionStmt)) {
			var fn:FunctionStmt = cast statement;
			var symbol = currentProgram.symbolFor(statement.nodeId);
			var binding = symbol == null ? null : ensureBinding(symbol);
			var functionId = binding == null ? functions.length : functionSlot(binding);
			var previousFrame = currentFrame;
			var body:Array<IRInstruction> = [];

			currentFrame = new IRFrameLayout(fn.name, fn.params.length);

			for (i in 0...fn.params.length)
				currentFrame.reserveParam(fn.params[i], i);

			for (inner in fn.body.statements)
				emitStatement(inner, body);

			if (body.length == 0 || body[body.length - 1] != IRInstruction.Return)
				body.push(IRInstruction.Return);

			functions.push(new IRFunction(functionId, fn.name, fn.params.length, currentFrame.localCount, body));
			currentFrame = previousFrame;
			return;
		}

		if (Std.isOfType(statement, BlockStmt)) {
			var block:BlockStmt = cast statement;
			for (inner in block.statements)
				emitStatement(inner, into);
			return;
		}

		if (Std.isOfType(statement, ExpressionStmt)) {
			var exprStmt:ExpressionStmt = cast statement;
			emitExpr(exprStmt.expression, into);
			return;
		}

		if (Std.isOfType(statement, VariableStmt)) {
			var variable:VariableStmt = cast statement;
			var symbol = currentProgram.symbolFor(statement.nodeId);
			var binding = symbol == null ? null : ensureBinding(symbol);

			if (variable.initializer != null)
				emitExpr(variable.initializer, into);
			else
				into.push(IRInstruction.PushConst(null));

			emitStore(binding, into);
			return;
		}

		if (Std.isOfType(statement, ReturnStmt)) {
			var ret:ReturnStmt = cast statement;
			if (ret.value != null)
				emitExpr(ret.value, into);
			into.push(IRInstruction.Return);
			return;
		}

		if (Std.isOfType(statement, IfStmt)) {
			var ifStmt:IfStmt = cast statement;
			var elseLabel = nextLabel();
			var endLabel = nextLabel();

			emitExpr(ifStmt.condition, into);
			into.push(IRInstruction.JumpIfFalse(elseLabel));
			emitStatement(ifStmt.thenBranch, into);
			into.push(IRInstruction.Jump(endLabel));
			into.push(IRInstruction.Label(elseLabel));

			if (ifStmt.elseBranch != null)
				emitStatement(ifStmt.elseBranch, into);

			into.push(IRInstruction.Label(endLabel));
			return;
		}

		if (Std.isOfType(statement, WhileStmt)) {
			var whileStmt:WhileStmt = cast statement;
			var startLabel = nextLabel();
			var endLabel = nextLabel();

			into.push(IRInstruction.Label(startLabel));
			emitExpr(whileStmt.condition, into);
			into.push(IRInstruction.JumpIfFalse(endLabel));
			emitStatement(whileStmt.body, into);
			into.push(IRInstruction.Jump(startLabel));
			into.push(IRInstruction.Label(endLabel));
			return;
		}
	}

	function emitExpr(expr:Expr, into:Array<IRInstruction>):Void {
		if (Std.isOfType(expr, LiteralExpr)) {
			var literal:LiteralExpr = cast expr;
			into.push(IRInstruction.PushConst(literal.value));
			return;
		}

		if (Std.isOfType(expr, IdentifierExpr)) {
			var identifier:IdentifierExpr = cast expr;
			var symbol = currentProgram.symbolFor(identifier.nodeId);
			var binding = symbol == null ? null : ensureBinding(symbol);
			emitLoad(binding, into);
			return;
		}

		if (Std.isOfType(expr, CallExpr)) {
			emitCall(cast expr, into);
			return;
		}

		if (Std.isOfType(expr, BinaryExpr)) {
			var binary:BinaryExpr<Dynamic> = cast expr;
			emitExpr(binary.left, into);
			emitExpr(binary.right, into);

			switch (binary.op) {
				case Plus: into.push(IRInstruction.Add);
				case Minus: into.push(IRInstruction.Sub);
				case Star: into.push(IRInstruction.Mul);
				case Slash: into.push(IRInstruction.Div);
				default:
			}
			return;
		}

		if (Std.isOfType(expr, UnaryExpr)) {
			var unary:UnaryExpr<Dynamic> = cast expr;
			emitExpr(unary.right, into);
			return;
		}
	}

	function emitCall(call:CallExpr, into:Array<IRInstruction>):Void {
		var directTarget = directCallTarget(call.callee);

		if (directTarget == null)
			emitExpr(call.callee, into);

		for (arg in call.args)
			emitExpr(arg, into);

		into.push(IRInstruction.Call(directTarget == null ? IRCallTarget.Dynamic : directTarget, call.args.length));
	}

	function directCallTarget(callee:Expr):Null<IRCallTarget> {
		if (!Std.isOfType(callee, IdentifierExpr))
			return null;

		var symbol = currentProgram.symbolFor(callee.nodeId);
		if (symbol == null)
			return null;

		var binding = ensureBinding(symbol);
		return switch (binding.address) {
			case Builtin(id): IRCallTarget.BuiltinId(id);
			case Function(id): IRCallTarget.FunctionId(id);
			case Global(_) | Local(_) | Upvalue(_): null;
		}
	}

	function ensureBinding(symbol:Symbol):IRBinding {
		var existing = bindingBySymbol.get(symbol);
		if (existing != null)
			return existing;

		var address = allocateAddress(symbol);
		var binding = new IRBinding(symbol.name, address, symbol.arity);
		bindingBySymbol.set(symbol, binding);
		bindings.push(binding);
		return binding;
	}

	function allocateAddress(symbol:Symbol):IRAddress {
		return switch (symbol.kind) {
			case Builtin:
				var id = builtinSlots.exists(symbol.name) ? builtinSlots.get(symbol.name) : nextBuiltinId++;
				builtinSlots.set(symbol.name, id);
				IRAddress.Builtin(id);
			case Function:
				var slot = functionBindingCount();
				IRAddress.Function(slot);
			case Variable:
				if (currentFrame == scriptFrame && symbol.scopeDepth == 0)
					IRAddress.Global(nextGlobalSlot++);
				else
					IRAddress.Local(currentFrame.reserveLocal(symbol.name));
			case Parameter:
				IRAddress.Local(currentFrame.reserveParam(symbol.name));
			case Undefined:
				reportError('Cannot allocate IR storage for undefined symbol ${symbol.name}.');
				IRAddress.Global(-1);
		}
	}

	function functionBindingCount():Int {
		var count = 0;
		for (binding in bindings) {
			switch (binding.address) {
				case Function(_): count++;
				default:
			}
		}
		return count;
	}

	function emitLoad(binding:Null<IRBinding>, into:Array<IRInstruction>):Void {
		if (binding == null) {
			reportError("Cannot emit load for missing IR binding.");
			return;
		}

		switch (binding.address) {
			case Builtin(id): into.push(IRInstruction.LoadCallable(IRCallTarget.BuiltinId(id)));
			case Function(id): into.push(IRInstruction.LoadCallable(IRCallTarget.FunctionId(id)));
			case Global(slot): into.push(IRInstruction.LoadGlobal(slot));
			case Local(slot): into.push(IRInstruction.LoadLocal(slot));
			case Upvalue(slot): into.push(IRInstruction.LoadUpvalue(slot));
		}
	}

	function emitStore(binding:Null<IRBinding>, into:Array<IRInstruction>):Void {
		if (binding == null) {
			reportError("Cannot emit store for missing IR binding.");
			return;
		}

		switch (binding.address) {
			case Global(slot): into.push(IRInstruction.StoreGlobal(slot));
			case Local(slot): into.push(IRInstruction.StoreLocal(slot));
			case Upvalue(slot): into.push(IRInstruction.StoreUpvalue(slot));
			default:
				reportError('Cannot store into non-assignable IR binding ${binding.name}.');
		}
	}

	function functionSlot(binding:IRBinding):Int {
		return switch (binding.address) {
			case Function(id): id;
			default: functions.length;
		}
	}

	function nextLabel():IRLabel {
		return new IRLabel(labelCounter++);
	}

	function emptyProgram():IRProgram {
		return new IRProgram([], [], 0, 0, 0);
	}

	function reportError(message:String, ?position:NxPosition):Void {
		failed = true;
		NxManager.onException.emit(new NxError(message, position == null ? syntheticPosition() : position));
	}

	function syntheticPosition():NxPosition {
		return new NxPosition(1, 1, 0, "<ir>", "");
	}
}

private class IRFrameLayout {
	public final name:String;
	public final paramCount:Int;
	public var localCount(default, null):Int;
	final slots:StringMap<Int>;

	public function new(name:String, paramCount:Int) {
		this.name = name;
		this.paramCount = paramCount;
		this.localCount = paramCount;
		this.slots = new StringMap();
	}

	public function reserveParam(name:String, ?slot:Int):Int {
		if (slots.exists(name))
			return slots.get(name);

		var resolvedSlot = slot == null ? localCount : slot;
		slots.set(name, resolvedSlot);
		if (resolvedSlot >= localCount)
			localCount = resolvedSlot + 1;
		return resolvedSlot;
	}

	public function reserveLocal(name:String):Int {
		if (slots.exists(name))
			return slots.get(name);

		var slot = localCount++;
		slots.set(name, slot);
		return slot;
	}
}
