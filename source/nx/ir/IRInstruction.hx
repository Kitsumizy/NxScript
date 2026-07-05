package nx.ir;

enum IRInstruction {

    // valores
    PushConst(value:Dynamic);

    // variables
    LoadLocal(slot:Int);
    StoreLocal(slot:Int);
    LoadGlobal(slot:Int);
    StoreGlobal(slot:Int);
    LoadUpvalue(slot:Int);
    StoreUpvalue(slot:Int);

    // funciones
    LoadCallable(target:IRCallTarget);
    Call(target:IRCallTarget, argc:Int);
    Return;

    // control flow
    Jump(label:IRLabel);
    JumpIfFalse(label:IRLabel);
    Label(label:IRLabel);

    // operaciones
    Add;
    Sub;
    Mul;
    Div;
}
