package integration;

import nx.script.Interpreter;
import nx.script.Bytecode.Value;

class CallNOValues {
	public static function main() {
		var val_arr = VArray([VNumber(1), VNumber(2), VNumber(3)]);
		var not_val_arr = [1, 2, 3];
		trace('Testing VArray with Value array:');

		var interp = new Interpreter();
		interp.set('TempClass', TempClass);
		interp.runDynamic('
        var obj = new TempClass(10);
        obj.add(5);
        trace(obj.getX());
        function callAdd(obj, y) {
            return obj.add(y);
        }
        function test(arr) {
            trace("In test function:");
            for (a in arr) {
                trace(a);
            }
        }');
		interp.call("test", [val_arr]);
		interp.call("test", [not_val_arr]);
	}
}

class TempClass {
	public var x:Int;

	public function new(x:Int) {
		this.x = x;
	}

	public function toString() {
		return "TempClass(" + x + ")";
	}

	public function add(y:Int) {
		trace('Adding ' + y + ' to ' + this.x);
		return this.x + y;
	}

	public function getX() {
		return this.x;
	}

	public function setX(newX:Int) {
		this.x = newX;
	}
}
