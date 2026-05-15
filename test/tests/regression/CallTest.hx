package regression;

import nx.script.Interpreter;
import nx.script.Bytecode.Value;

class CallTest {
	public static function main() {
		var note:Note = {
			type: "note",
			value: 60,
			im_gay_super_gay: true
		};
		var interp = new Interpreter();
		interp.parent = note;
		interp.runDynamic('
        func onNote(e) {
            trace(e);
        }');
		interp.call("onNote", [note]);
		trace(note);
	}
}

@:structInit
class Note {
	public var e:String = "note";
	public var trace:Int = 123;
	public var type:String;
	public var value:Int;
	public var im_gay_super_gay:Bool;

	public function toString() {
		return "Note(type: " + type + ", value: " + value + ", im_gay_super_gay: " + im_gay_super_gay + ")";
	}
}
