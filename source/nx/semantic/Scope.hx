package nx.semantic;

import haxe.ds.StringMap;

class Scope {
	public final parent:Null<Scope>;
	public final depth:Int;
	final symbols:StringMap<Symbol>;

	public function new(?parent:Scope) {
		this.parent = parent;
		this.depth = parent == null ? 0 : parent.depth + 1;
		symbols = new StringMap<Symbol>();
	}

	public function declare(symbol:Symbol):Bool {
		if (symbols.exists(symbol.name))
			return false;

		symbols.set(symbol.name, symbol);
		return true;
	}

	public function resolveLocal(name:String):Null<Symbol> {
		return symbols.exists(name) ? symbols.get(name) : null;
	}

	public function resolve(name:String):Null<Symbol> {
		var local = resolveLocal(name);
		if (local != null)
			return local;

		return parent == null ? null : parent.resolve(name);
	}

	public function suggest(name:String, threshold:Float = 0.6):Null<Symbol> {
		var best:Null<Symbol> = null;
		var bestScore = threshold;
		var seen = new StringMap<Bool>();

		for (symbol in collectSymbols(seen)) {
			var score = similarity(name, symbol.name);
			if (score >= bestScore) {
				bestScore = score;
				best = symbol;
			}
		}

		return best;
	}

	public function collectSymbols(?seen:StringMap<Bool>, ?out:Array<Symbol>):Array<Symbol> {
		if (seen == null)
			seen = new StringMap<Bool>();

		if (out == null)
			out = [];

		for (key in symbols.keys()) {
			if (!seen.exists(key)) {
				seen.set(key, true);
				out.push(symbols.get(key));
			}
		}

		if (parent != null)
			parent.collectSymbols(seen, out);

		return out;
	}

	static function similarity(a:String, b:String):Float {
		if (a == b)
			return 1.0;

		var aLower = a.toLowerCase();
		var bLower = b.toLowerCase();

		if (aLower == bLower)
			return 1.0;

		if (aLower.indexOf(bLower) != -1 || bLower.indexOf(aLower) != -1)
			return 0.8;

		var maxLen = aLower.length > bLower.length ? aLower.length : bLower.length;
		if (maxLen == 0)
			return 1.0;

		var distance = levenshtein(aLower, bLower);
		return 1.0 - (distance / maxLen);
	}

	static function levenshtein(a:String, b:String):Int {
		var aLen = a.length;
		var bLen = b.length;
		var prev = [for (i in 0...bLen + 1) i];
		var curr = new Array<Int>();

		for (i in 1...aLen + 1) {
			curr = [i];
			for (j in 1...bLen + 1) {
				var cost = a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1;
				var deletion = prev[j] + 1;
				var insertion = curr[j - 1] + 1;
				var substitution = prev[j - 1] + cost;
				curr.push(minInt(deletion, minInt(insertion, substitution)));
			}
			prev = curr.copy();
		}

		return prev[bLen];
	}

	static inline function minInt(a:Int, b:Int):Int {
		return a < b ? a : b;
	}

	public function toString():String {
		var parts:Array<String> = [];
		for (key in symbols.keys())
			parts.push(symbols.get(key).label());
		return 'Scope(depth=${depth}, symbols=[${parts.join(", ")}])';
	}
}