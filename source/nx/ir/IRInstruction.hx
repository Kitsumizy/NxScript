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
    Construct(argc:Int);
    Return;

    // clases
    LoadClass(id:Int);

    // control flow
    Jump(label:IRLabel);
    JumpIfFalse(label:IRLabel);
    Label(label:IRLabel);
    BeginTry(catchLabel:IRLabel);
    EndTry;
    Throw;
    MatchStart(caseCount:Int, hasDefault:Bool);
    MatchCase;
    MatchDefault;
    MatchEnd;

    // operaciones
    Add;
    Sub;
    Mul;
    Div;
    Neg;
    Not;
    Is;
    NullCoalesce;
    BuildArray(count:Int);
    BuildDict(count:Int);
    LoadIndex;
    LoadProperty(name:String);
    LoadOptionalProperty(name:String);
    StoreProperty(name:String);
    BuildTemplate(count:Int);
}
