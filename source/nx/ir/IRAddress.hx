package nx.ir;

enum IRAddress {
	Builtin(id:Int);
	Function(id:Int);
	Global(slot:Int);
	Local(slot:Int);
	Upvalue(slot:Int);
}
