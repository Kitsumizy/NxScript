// Functions in Haxe

class Functions {
    static function main() {
        trace(greet("Haxe"));
        trace(sum(5, 3));
        trace(power(2, 8));
    }
    
    static function greet(name:String):String {
        return "Hello " + name + "!";
    }
    
    static function sum(a:Int, b:Int):Int {
        return a + b;
    }
    
    // Optional parameters
    static function greetWithTime(name:String, timeOfDay:String = "day"):String {
        return "Good " + timeOfDay + ", " + name;
    }
    
    // Inline function
    inline function power(base:Float, exp:Int):Float {
        return Math.pow(base, exp);
    }
}
