// Funciones en Haxe

class Funciones {
    static function main() {
        trace(saludar("Haxe"));
        trace(sumar(5, 3));
        trace(potencia(2, 8));
    }
    
    static function saludar(nombre:String):String {
        return "Hola " + nombre + "!";
    }
    
    static function sumar(a:Int, b:Int):Int {
        return a + b;
    }
    
    // Parámetros opcionales
    static function saludarConHora(nombre:String, hora:String = "día"):String {
        return "Buenas " + hora + ", " + nombre;
    }
    
    // Función inline
    inline function potencia(base:Float, exp:Int):Float {
        return Math.pow(base, exp);
    }
}
