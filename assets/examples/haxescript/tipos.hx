// Tipos y variables en Haxe

class Tipos {
    static function main() {
        // Tipado estático
        var nombre:String = "Haxe";
        var version:Float = 4.3;
        var esPotente:Bool = true;
        var contador:Int = 0;
        
        trace("Lenguaje: " + nombre);
        trace("Versión: " + version);
        trace("¿Es potente?: " + esPotente);
        
        // Inferencia de tipos
        var automatico = "Haxe infiere el tipo";
        trace(automatico);
        
        // Dynamic
        var dinámico:Dynamic = 42;
        dinámico = "ahora es string";
        trace(dinámico);
    }
}
