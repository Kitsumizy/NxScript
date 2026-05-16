// Arrays y Maps en Haxe

class Colecciones {
    static function main() {
        // Array
        var frutas:Array<String> = ["manzana", "banana", "naranja"];
        trace("Primera: " + frutas[0]);
        trace("Longitud: " + frutas.length);
        
        frutas.push("uva");
        trace("Después de push: " + frutas);
        
        // Iterar
        for (fruta in frutas) {
            trace("Fruta: " + fruta);
        }
        
        // Map (diccionario)
        var edades:Map<String, Int> = new Map();
        edades.set("Ana", 30);
        edades.set("Carlos", 25);
        
        trace("Edad de Ana: " + edades.get("Ana"));
        
        for (nombre in edades.keys()) {
            trace(nombre + " tiene " + edades.get(nombre) + " años");
        }
    }
}
