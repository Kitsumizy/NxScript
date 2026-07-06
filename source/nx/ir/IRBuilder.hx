package nx.ir;

import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import nx.common.NxError;
import nx.common.NxPosition;
import nx.ast.Expr;
import nx.ast.nodes.*;
import nx.lexer.TokenType;
import nx.semantic.SemanticProgram;
import nx.semantic.Symbol;
import nx.semantic.SymbolKind;
import nx.script.NxManager;
import nx.ir.IRClass.IRField;
import nx.ir.IRClass.IRMethod;

class IRBuilder {
	var out:Array<IRInstruction>;
	var classes:Array<IRClass>;
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
	var breakLabels:Array<IRLabel>;
	var continueLabels:Array<IRLabel>;

	public function new() {}

	public function build(program:SemanticProgram):IRProgram {
		var startTime = haxe.Timer.stamp();
		currentProgram = program;
		out = [];
		classes = [];
		functions = [];
		bindings = [];
		bindingBySymbol = new ObjectMap();
		builtinSlots = new StringMap();
		labelCounter = 0;
		nextGlobalSlot = 0;
		nextBuiltinId = 0;
		failed = false;
		breakLabels = [];
		continueLabels = [];
		scriptFrame = new IRFrameLayout("script", 0);
		currentFrame = scriptFrame;

		if (program.diagnostics.length > 0) {
			reportError(
				'Cannot build IR: semantic analysis produced ${program.diagnostics.length} diagnostic(s).',
				program.diagnostics[0].infopos
			);
			return emptyProgram();
		}

		predeclareFunctions(program.exprs);

		for (expr in program.exprs)
			emitTopLevelExpr(expr, out);

		if (failed)
			return emptyProgram();

		var buildTime = haxe.Timer.stamp() - startTime;
		return new IRProgram(classes, functions, out, nextGlobalSlot, scriptFrame.localCount, buildTime);
	}

	function predeclareFunctions(exprs:Array<Expr>):Void {
		for (expr in exprs) {
			if (Std.isOfType(expr, FunctionExpr) || Std.isOfType(expr, ClassExpr)) {
				var symbol = currentProgram.symbolFor(expr.nodeId);
				if (symbol != null)
					ensureBinding(symbol);
			}

			if (Std.isOfType(expr, BlockExpr))
				predeclareFunctions((cast expr : BlockExpr).exprs);

			if (Std.isOfType(expr, ClassExpr))
				predeclareFunctions((cast expr : ClassExpr).members);
		}
	}

	function emitTopLevelExpr(expr:Expr, into:Array<IRInstruction>):Void {
		if (Std.isOfType(expr, ClassExpr)) {
			emitClass(cast expr, into);
			return;
		}

		if (Std.isOfType(expr, FunctionExpr)) {
			emitFunction(cast expr, into);
			return;
		}

		if (Std.isOfType(expr, BlockExpr)) {
			var block:BlockExpr = cast expr;
			for (inner in block.exprs)
				emitTopLevelExpr(inner, into);
			return;
		}

		if (Std.isOfType(expr, ExpressionExpr)) {
			var exprStmt:ExpressionExpr = cast expr;
			emitExpr(exprStmt.expression, into);
			return;
		}

		if (Std.isOfType(expr, VariableExpr)) {
			var variable:VariableExpr = cast expr;
			var symbol = currentProgram.symbolFor(expr.nodeId);
			var binding = symbol == null ? null : ensureBinding(symbol);

			if (variable.initializer != null)
				emitExpr(variable.initializer, into);
			else
				into.push(IRInstruction.PushConst(null));

			emitStore(binding, into);
			return;
		}

		if (Std.isOfType(expr, ReturnExpr)) {
			var ret:ReturnExpr = cast expr;
			if (ret.value != null)
				emitExpr(ret.value, into);
			into.push(IRInstruction.Return);
			return;
		}

		if (Std.isOfType(expr, IfExpr)) {
			var ifExpr:IfExpr = cast expr;
			var elseLabel = nextLabel();
			var endLabel = nextLabel();

			emitExpr(ifExpr.condition, into);
			into.push(IRInstruction.JumpIfFalse(elseLabel));
			emitTopLevelExpr(ifExpr.thenBranch, into);
			into.push(IRInstruction.Jump(endLabel));
			into.push(IRInstruction.Label(elseLabel));

			if (ifExpr.elseBranch != null)
				emitTopLevelExpr(ifExpr.elseBranch, into);

			into.push(IRInstruction.Label(endLabel));
			return;
		}

		if (Std.isOfType(expr, WhileExpr)) {
			var whileExpr:WhileExpr = cast expr;
			var startLabel = nextLabel();
			var endLabel = nextLabel();

			breakLabels.push(endLabel);
			continueLabels.push(startLabel);
			into.push(IRInstruction.Label(startLabel));
			emitExpr(whileExpr.condition, into);
			into.push(IRInstruction.JumpIfFalse(endLabel));
			emitTopLevelExpr(whileExpr.body, into);
			into.push(IRInstruction.Jump(startLabel));
			into.push(IRInstruction.Label(endLabel));
			continueLabels.pop();
			breakLabels.pop();
			return;
		}

		if (Std.isOfType(expr, ForExpr)) {
			emitFor(cast expr, into);
			return;
		}

		if (Std.isOfType(expr, BreakExpr)) {
			if (breakLabels.length == 0)
				reportError("Cannot emit 'break' outside a loop.");
			else
				into.push(IRInstruction.Jump(breakLabels[breakLabels.length - 1]));
			return;
		}

		if (Std.isOfType(expr, ContinueExpr)) {
			if (continueLabels.length == 0)
				reportError("Cannot emit 'continue' outside a loop.");
			else
				into.push(IRInstruction.Jump(continueLabels[continueLabels.length - 1]));
			return;
		}

		if (Std.isOfType(expr, ThrowExpr)) {
			var throwExpr:ThrowExpr = cast expr;
			emitExpr(throwExpr.value, into);
			into.push(IRInstruction.Throw);
			return;
		}

		if (Std.isOfType(expr, TryCatchExpr)) {
			emitTryCatch(cast expr, into);
			return;
		}

		if (Std.isOfType(expr, MatchExpr)) {
			emitMatch(cast expr, into);
			return;
		}

		emitExpr(expr, into);
	}

	function emitClass(classExpr:ClassExpr, into:Array<IRInstruction>):Void {
		var symbol = currentProgram.symbolFor(classExpr.nodeId);
		var binding = symbol == null ? null : ensureBinding(symbol);
		var methodIds = new StringMap<Int>();
		var classId = classes.length;
		var fields:Array<IRField> = [];
		var methods:Array<IRMethod> = [];

		for (member in classExpr.members) {
			if (!Std.isOfType(member, FunctionExpr))
				continue;

			var method:FunctionExpr = cast member;
			var methodSymbol = currentProgram.symbolFor(method.nodeId);
			var methodBinding = methodSymbol == null ? null : ensureBinding(methodSymbol);
			methodIds.set(method.name, methodBinding == null ? functions.length : functionSlot(methodBinding));
			emitFunction(method, into, true);
		}

		for (member in classExpr.members) {
			if (Std.isOfType(member, VariableExpr)) {
				var field:VariableExpr = cast member;
				var initializer:Array<IRInstruction> = [];
				if (field.initializer != null)
					emitExpr(field.initializer, initializer);
				else
					initializer.push(IRInstruction.PushConst(null));
				fields.push(new IRField(field.name, initializer));
				continue;
			}

			if (Std.isOfType(member, FunctionExpr)) {
				var method:FunctionExpr = cast member;
				methods.push(new IRMethod(method.name, IRCallTarget.FunctionId(methodIds.get(method.name))));
			}
		}

		classes.push(new IRClass(classId, classExpr.name, fields, methods));
		into.push(IRInstruction.LoadClass(classId));
		emitStore(binding, into);
	}

	function emitFunction(fn:FunctionExpr, into:Array<IRInstruction>, implicitThis:Bool = false):Void {
		var symbol = currentProgram.symbolFor(fn.nodeId);
		var binding = symbol == null ? null : ensureBinding(symbol);
		var functionId = binding == null ? functions.length : functionSlot(binding);
		var previousFrame = currentFrame;
		var body:Array<IRInstruction> = [];
		var paramOffset = implicitThis ? 1 : 0;

		currentFrame = new IRFrameLayout(fn.name, fn.params.length + paramOffset);

		if (implicitThis)
			currentFrame.reserveParam("this", 0);

		for (i in 0...fn.params.length)
			currentFrame.reserveParam(fn.params[i], i + paramOffset);

		for (inner in fn.body.exprs)
			emitTopLevelExpr(inner, body);

		if (body.length == 0 || body[body.length - 1] != IRInstruction.Return)
			body.push(IRInstruction.Return);

		functions.push(new IRFunction(functionId, fn.name, fn.params.length, currentFrame.localCount, body));
		currentFrame = previousFrame;
	}

	function emitFor(forExpr:ForExpr, into:Array<IRInstruction>):Void {
		var conditionLabel = nextLabel();
		var incrementLabel = nextLabel();
		var endLabel = nextLabel();

		if (forExpr.initializer != null)
			emitTopLevelExpr(forExpr.initializer, into);

		breakLabels.push(endLabel);
		continueLabels.push(incrementLabel);

		into.push(IRInstruction.Label(conditionLabel));
		if (forExpr.condition != null) {
			emitExpr(forExpr.condition, into);
			into.push(IRInstruction.JumpIfFalse(endLabel));
		}

		emitTopLevelExpr(forExpr.body, into);

		into.push(IRInstruction.Label(incrementLabel));
		if (forExpr.increment != null)
			emitExpr(forExpr.increment, into);

		into.push(IRInstruction.Jump(conditionLabel));
		into.push(IRInstruction.Label(endLabel));

		continueLabels.pop();
		breakLabels.pop();
	}

	function emitTryCatch(tryCatch:TryCatchExpr, into:Array<IRInstruction>):Void {
		var catchLabel = nextLabel();
		var endLabel = nextLabel();
		into.push(IRInstruction.BeginTry(catchLabel));
		emitTopLevelExpr(tryCatch.tryBody, into);
		into.push(IRInstruction.EndTry);
		into.push(IRInstruction.Jump(endLabel));
		into.push(IRInstruction.Label(catchLabel));
		emitTopLevelExpr(tryCatch.catchBody, into);
		into.push(IRInstruction.Label(endLabel));
	}

	function emitMatch(matchExpr:MatchExpr, into:Array<IRInstruction>):Void {
		emitExpr(matchExpr.target, into);
		into.push(IRInstruction.MatchStart(matchExpr.cases.length, matchExpr.defaultBranch != null));
		for (matchCase in matchExpr.cases) {
			emitExpr(matchCase.pattern, into);
			into.push(IRInstruction.MatchCase);
			emitTopLevelExpr(matchCase.body, into);
		}

		if (matchExpr.defaultBranch != null) {
			into.push(IRInstruction.MatchDefault);
			emitTopLevelExpr(matchExpr.defaultBranch, into);
		}

		into.push(IRInstruction.MatchEnd);
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
			if (symbol != null && symbol.kind == SymbolKind.Field) {
				emitLoadThisField(symbol.name, into);
				return;
			}
			var binding = symbol == null ? null : ensureBinding(symbol);
			emitLoad(binding, into);
			return;
		}

		if (Std.isOfType(expr, CallExpr)) {
			emitCall(cast expr, into);
			return;
		}

		if (Std.isOfType(expr, NewExpr)) {
			var newExpr:NewExpr = cast expr;
			emitExpr(newExpr.callee, into);
			for (arg in newExpr.args)
				emitExpr(arg, into);
			into.push(IRInstruction.Construct(newExpr.args.length));
			return;
		}

		if (Std.isOfType(expr, BinaryExpr)) {
			var binary:BinaryExpr<Dynamic> = cast expr;
			if (isAssignmentOperator(binary.op)) {
				emitAssignment(binary, into);
				return;
			}

			emitExpr(binary.left, into);
			emitExpr(binary.right, into);

			switch (binary.op) {
				case Plus: into.push(IRInstruction.Add);
				case Minus: into.push(IRInstruction.Sub);
				case Star: into.push(IRInstruction.Mul);
				case Slash: into.push(IRInstruction.Div);
				case QuestionQuestion: into.push(IRInstruction.NullCoalesce);
				case Keyword(_): into.push(IRInstruction.Is);
				default:
					reportError('Unsupported binary operator ${Std.string(binary.op)}.');
			}
			return;
		}

		if (Std.isOfType(expr, UnaryExpr)) {
			var unary:UnaryExpr<Dynamic> = cast expr;
			emitExpr(unary.right, into);
			switch (unary.op) {
				case Minus: into.push(IRInstruction.Neg);
				case Bang: into.push(IRInstruction.Not);
				case Plus:
				default:
					reportError('Unsupported unary operator ${Std.string(unary.op)}.');
			}
			return;
		}

		if (Std.isOfType(expr, ArrayExpr)) {
			var arrayExpr:ArrayExpr = cast expr;
			for (element in arrayExpr.elements)
				emitExpr(element, into);
			into.push(IRInstruction.BuildArray(arrayExpr.elements.length));
			return;
		}

		if (Std.isOfType(expr, DictExpr)) {
			var dictExpr:DictExpr = cast expr;
			for (entry in dictExpr.entries) {
				emitExpr(entry.key, into);
				emitExpr(entry.value, into);
			}
			into.push(IRInstruction.BuildDict(dictExpr.entries.length));
			return;
		}

		if (Std.isOfType(expr, IndexExpr)) {
			var indexExpr:IndexExpr = cast expr;
			emitExpr(indexExpr.target, into);
			emitExpr(indexExpr.index, into);
			into.push(IRInstruction.LoadIndex);
			return;
		}

		if (Std.isOfType(expr, MemberExpr)) {
			var memberExpr:MemberExpr = cast expr;
			emitExpr(memberExpr.target, into);
			into.push(memberExpr.optional ? IRInstruction.LoadOptionalProperty(memberExpr.name) : IRInstruction.LoadProperty(memberExpr.name));
			return;
		}

		if (Std.isOfType(expr, TemplateExpr)) {
			var templateExpr:TemplateExpr = cast expr;
			for (part in templateExpr.parts)
				emitExpr(part, into);
			into.push(IRInstruction.BuildTemplate(templateExpr.parts.length));
			return;
		}

		reportError('Unsupported AST expression ${Type.getClassName(Type.getClass(expr))}.');
	}

	function emitAssignment(binary:BinaryExpr<Dynamic>, into:Array<IRInstruction>):Void {
		if (!Std.isOfType(binary.left, IdentifierExpr)) {
			reportError("Cannot emit assignment for non-identifier target.");
			return;
		}

		var identifier:IdentifierExpr = cast binary.left;
		var symbol = currentProgram.symbolFor(identifier.nodeId);

		if (symbol != null && symbol.kind == SymbolKind.Field) {
			emitFieldAssignment(symbol, binary, into);
			return;
		}

		var binding = symbol == null ? null : ensureBinding(symbol);

		switch (binary.op) {
			case Equal:
				emitExpr(binary.right, into);
			case PlusEqual | MinusEqual | StarEqual | SlashEqual:
				emitLoad(binding, into);
				emitExpr(binary.right, into);
				switch (binary.op) {
					case PlusEqual: into.push(IRInstruction.Add);
					case MinusEqual: into.push(IRInstruction.Sub);
					case StarEqual: into.push(IRInstruction.Mul);
					case SlashEqual: into.push(IRInstruction.Div);
					default:
				}
			default:
				reportError('Unsupported assignment operator ${Std.string(binary.op)}.');
				return;
		}

		emitStore(binding, into);
	}

	function emitFieldAssignment(symbol:Symbol, binary:BinaryExpr<Dynamic>, into:Array<IRInstruction>):Void {
		into.push(IRInstruction.LoadLocal(0));

		switch (binary.op) {
			case Equal:
				emitExpr(binary.right, into);
			case PlusEqual | MinusEqual | StarEqual | SlashEqual:
				emitLoadThisField(symbol.name, into);
				emitExpr(binary.right, into);
				switch (binary.op) {
					case PlusEqual: into.push(IRInstruction.Add);
					case MinusEqual: into.push(IRInstruction.Sub);
					case StarEqual: into.push(IRInstruction.Mul);
					case SlashEqual: into.push(IRInstruction.Div);
					default:
				}
			default:
				reportError('Unsupported field assignment operator ${Std.string(binary.op)}.');
				return;
		}

		into.push(IRInstruction.StoreProperty(symbol.name));
	}

	function isAssignmentOperator(op:TokenType<Dynamic>):Bool {
		return switch (op) {
			case Equal | PlusEqual | MinusEqual | StarEqual | SlashEqual: true;
			default: false;
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
			case Class:
				IRAddress.Global(nextGlobalSlot++);
			case Field:
				reportError('Cannot allocate standalone IR storage for field ${symbol.name}.');
				IRAddress.Local(-1);
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

	function emitLoadThisField(name:String, into:Array<IRInstruction>):Void {
		into.push(IRInstruction.LoadLocal(0));
		into.push(IRInstruction.LoadProperty(name));
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
		return new IRProgram([], [], [], 0, 0, 0);
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
