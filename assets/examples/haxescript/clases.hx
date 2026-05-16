// Clases y objetos en Haxe

class Persona {
    public var nombre:String;
    public var edad:Int;
    
    public function new(nombre:String, edad:Int) {
        this.nombre = nombre;
        this.edad = edad;
    }
    
    public function saludar():String {
        return "Hola, soy " + nombre + " y tengo " + edad + " años";
    }
}

class Main {
    static function main() {
        var persona = new Persona("Ana", 30);
        trace(persona.saludar());
        
        // Herencia
        var estudiante = new Estudiante("Carlos", 20, "Informática");
        trace(estudiante.saludar());
        trace(estudiante.estudiar());
    }
}

class Estudiante extends Persona {
    public var carrera:String;
    
    public function new(nombre:String, edad:Int, carrera:String) {
        super(nombre, edad);
        this.carrera = carrera;
    }
    
    public function estudiar():String {
        return "Estudiando " + carrera;
    }
}
