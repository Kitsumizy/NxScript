package nx.ir;

class IRFunction {
    public var id:Int;
    public var name:String;
    public var params:Int;
    public var localCount:Int;
    public var body:Array<IRInstruction>;

    public function new(id:Int, name:String, params:Int, localCount:Int, body:Array<IRInstruction>) {
        this.id = id;
        this.name = name;
        this.params = params;
        this.localCount = localCount;
        this.body = body;
    }

    public function toString():String {
        return 'IRFunction(#${id} ${name}/${params}, locals=${localCount}, body=${body.join(", ")})';
    }
}
