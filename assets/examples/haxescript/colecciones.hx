// Arrays and Maps in Haxe

class Collections {
    static function main() {
        // Array
        var fruits:Array<String> = ["apple", "banana", "orange"];
        trace("First: " + fruits[0]);
        trace("Length: " + fruits.length);
        
        fruits.push("grape");
        trace("After push: " + fruits);
        
        // Iterate
        for (fruit in fruits) {
            trace("Fruit: " + fruit);
        }
        
        // Map (dictionary)
        var ages:Map<String, Int> = new Map();
        ages.set("Alice", 30);
        ages.set("Bob", 25);
        
        trace("Alice's age: " + ages.get("Alice"));
        
        for (name in ages.keys()) {
            trace(name + " is " + ages.get(name) + " years old");
        }
    }
}
