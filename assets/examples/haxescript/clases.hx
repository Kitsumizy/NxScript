// Classes and Objects in Haxe

class Person {
    public var name:String;
    public var age:Int;
    
    public function new(name:String, age:Int) {
        this.name = name;
        this.age = age;
    }
    
    public function greet():String {
        return "Hello, I'm " + name + " and I'm " + age + " years old";
    }
}

class Main {
    static function main() {
        var person = new Person("Alice", 30);
        trace(person.greet());
        
        // Inheritance
        var student = new Student("Bob", 20, "Computer Science");
        trace(student.greet());
        trace(student.study());
    }
}

class Student extends Person {
    public var major:String;
    
    public function new(name:String, age:Int, major:String) {
        super(name, age);
        this.major = major;
    }
    
    public function study():String {
        return "Studying " + major;
    }
}
