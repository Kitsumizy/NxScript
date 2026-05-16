// Pattern Matching in Haxe

class PatternMatching {
    static function main() {
        // Switch with pattern matching
        var value:Null<Int> = 3;
        
        switch (value) {
            case null:
                trace("Value is null");
            case 0:
                trace("It's zero");
            case 1 | 2 | 3:
                trace("It's 1, 2, or 3");
            case x if x > 10:
                trace("It's greater than 10: " + x);
            case x:
                trace("Other value: " + x);
        }
        
        // Match on enum
        var result = evaluate(5);
        switch (result) {
            case Passed(grade):
                trace("Passed with " + grade);
            case Failed:
                trace("Failed");
        }
    }
    
    enum Result {
        Passed(grade:Int);
        Failed;
    }
    
    static function evaluate(grade:Int):Result {
        return grade >= 6 ? Passed(grade) : Failed;
    }
}
