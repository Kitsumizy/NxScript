package nx.ir;

class IRLabel {
    public final id:Int;
    public function new(id:Int) {
        this.id = id;
    }
    public function toString():String {
        return 'IRLabel(${id})';
    }
}