// Pattern matching en Haxe

class PatternMatching {
    static function main() {
        // Switch con pattern matching
        var valor:Null<Int> = 3;
        
        switch (valor) {
            case null:
                trace("Valor es null");
            case 0:
                trace("Es cero");
            case 1 | 2 | 3:
                trace("Es 1, 2 o 3");
            case x if x > 10:
                trace("Es mayor que 10: " + x);
            case x:
                trace("Otro valor: " + x);
        }
        
        // Match en enum
        var resultado = evaluar(5);
        switch (resultado) {
            case Aprobado(nota):
                trace("Aprobado con " + nota);
            case Reprobado:
                trace("Reprobado");
        }
    }
    
    enum Resultado {
        Aprobado(nota:Int);
        Reprobado;
    }
    
    static function evaluar(nota:Int):Resultado {
        return nota >= 6 ? Aprobado(nota) : Reprobado;
    }
}
