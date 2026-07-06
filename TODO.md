# TODO

Current state of `rewritte`: lexer -> parser -> semantic -> IR all work.
That's where it stops. Nothing actually runs yet.

## Blocking - no execution yet

- [ ] Design bytecode opcodes (based on existing IR: PushConst, Add/Sub/Mul/Div,
      Jump/JumpIfFalse, Call, Load/StoreGlobal/Local/Upvalue)
- [ ] `BytecodeBuilder` - empty file, just `package nx.backend;`
- [ ] `ProgramCode` - empty. Needs a constant pool + function table + bytecode buffer
- [ ] Stack-based VM to run the bytecode (doesn't exist yet)
- [ ] Wire `NxScript.hx` to call the backend after `createIRBuilder()`
      (pipeline currently stops at IR)

## Bugs

- [ ] `IRBuilder`'s `UnaryExpr` case doesn't emit the operator's opcode -
      `-x` compiles as just `x`
- [ ] `emitStatement` / `emitExpr` have no default case for unknown nodes -
      unhandled node types silently do nothing instead of erroring
- [ ] `for`, `break`, `continue` are reserved keywords but have no AST node,
      no semantic case, no IR case. Implement them or remove from the lexer.

## Missing language features (keywords already reserved, not implemented)

- [ ] `class`, `new`, `this`
- [ ] `switch` / `match` / `case` / `default`
- [ ] `try` / `catch` / `throw`
- [ ] `is` operator
- [ ] arrays and dicts (literals + indexing)
- [ ] template strings
- [ ] `??` and `?.` - not even tokenized yet

## Semantic analyzer

- [ ] `let` / `const` / `var` are all treated as the same kind - no error on
      reassigning a `const`
- [ ] check that `break` / `continue` are inside a loop (once `for` exists)

## Testing

- [ ] No `test/` folder on this branch. `main` claims 195 passing tests; `rewritte` has zero
