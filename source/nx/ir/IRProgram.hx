package nx.ir;

class IRProgram {
	public final buildTime:Float;
	public var classes:Array<IRClass>;
	public var functions:Array<IRFunction>;
	public var globals:Array<IRInstruction>;
	public var globalCount:Int;
	public var scriptLocalCount:Int;

	public function new(classes:Array<IRClass>, functions:Array<IRFunction>, globals:Array<IRInstruction>, globalCount:Int, scriptLocalCount:Int, buildTime:Float) {
		this.classes = classes;
		this.functions = functions;
		this.globals = globals;
		this.globalCount = globalCount;
		this.scriptLocalCount = scriptLocalCount;
		this.buildTime = buildTime;
	}

	public function toString():String {
		var lines:Array<String> = ["IRProgram"];

		if (classes.length > 0) {
			lines.push(" |- classes");
			for (i in 0...classes.length) {
				var cls = classes[i];
				var isLastClass = i == classes.length - 1 && functions.length == 0;
				lines.push((isLastClass ? " |   `- " : " |   |- ") + '#${cls.id} ${cls.name}');

				if (cls.fields.length > 0) {
					lines.push(" |   |   fields");
					for (field in cls.fields) {
						lines.push(" |   |     " + field.name);
						for (inst in field.initializer)
							lines.push(" |   |       " + Std.string(inst));
					}
				}

				if (cls.methods.length > 0) {
					lines.push(" |   |   methods");
					for (method in cls.methods)
						lines.push(" |   |     " + method.name + " -> " + Std.string(method.target));
				}
			}
		}

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
