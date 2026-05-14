package integration;
import nx.script.Interpreter;
import nx.script.Bytecode.Value;

class CallNOValues {
    public static function main() {
        var val_arr = VArray([VNumber(1), VNumber(2), VNumber(3)]);
        var not_val_arr = [1, 2, 3];
        trace('Testing VArray with Value array:');

        var interp = new Interpreter();
        interp.runDynamic('
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