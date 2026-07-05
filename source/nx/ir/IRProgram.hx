package nx.ir;

class IRProgram {
	public final buildTime:Float;
	public var functions:Array<IRFunction>;
	public var globals:Array<IRInstruction>;
	public var globalCount:Int;
	public var scriptLocalCount:Int;

	public function new(functions:Array<IRFunction>, globals:Array<IRInstruction>, globalCount:Int, scriptLocalCount:Int, buildTime:Float) {
		this.functions = functions;
		this.globals = globals;
		this.globalCount = globalCount;
		this.scriptLocalCount = scriptLocalCount;
		this.buildTime = buildTime;
	}

	public function toString():String {
		var lines:Array<String> = ["IRProgram"];

		if (functions.length > 0) {
			lines.push(" |- functions");
			for (i in 0...functions.length) {
				var fn = functions[i];
				var isLast = i == functions.length - 1;
				lines.push((isLast ? " |   `- " : " |   |- ") + '#${fn.id} ${fn.name}/${fn.params} locals=${fn.localCount}');
				for (inst in fn.body)
					lines.push(" |       " + Std.string(inst));
			}
		}

		if (globals.length > 0) {
			lines.push(" `- globals slots=" + globalCount + " scriptLocals=" + scriptLocalCount);
			for (inst in globals)
				lines.push("     " + Std.string(inst));
		}

		return lines.join("\n");
	}
}
