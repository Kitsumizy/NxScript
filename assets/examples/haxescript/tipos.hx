// Types and Variables in Haxe

class Types {
    static function main() {
        // Static typing
        var name:String = "Haxe";
        var version:Float = 4.3;
        var isPowerful:Bool = true;
        var counter:Int = 0;
        
        trace("Language: " + name);
        trace("Version: " + version);
        trace("Is powerful?: " + isPowerful);
        
        // Type inference
        var automatic = "Haxe infers the type";
        trace(automatic);
        
        // Dynamic
        var dynamic:Any = 42;
        dynamic = "now it's a string";
        trace(dynamic);
    }
}
