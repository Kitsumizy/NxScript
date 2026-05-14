package ;

import nx.script.Interpreter;

class MyFuckingSillyAss {
    public var a:Int = 0;
    private var _did_call_scope_test:Bool = false;
    public function new() {
        var interp = new Interpreter();
        interp.withParent(this);

        interp.runDynamic("
            a = 5;
            trace(a);
            call_fn_test()
            func scope_test() {
                trace('Overrided scope_test.');
            }
            scope_test();

        ");
        trace(' "a" = ${a}');
        if (a != 5) {
            trace("Failed var assignment.");
        } else {
            trace("Passed var assignment.");
        }
        if (_did_call_scope_test) {
            trace("Failed scope test.");
        } else {
            trace("Passed scope test.");
        }
    }
    function call_fn_test()
    {
        trace("Called call_fn_test.");
    }
    public function scope_test()
    {
        trace("Failed scope test.");
        _did_call_scope_test = true;
    }
    public static function main()
    {
        new MyFuckingSillyAss();
    }
}