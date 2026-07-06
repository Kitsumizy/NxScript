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

- [x] `IRBuilder`'s `UnaryExpr` case doesn't emit the operator's opcode -
      `-x` compiles as just `x`
- [x] `emitTopLevelExpr` / `emitExpr` have no default case for unknown nodes -
      unhandled node types silently do nothing instead of erroring
- [x] `for`, `break`, `continue` are reserved keywords but have no AST node,
      no semantic case, no IR case. Implement them or remove from the lexer.

## Missing language features (keywords already reserved, not implemented)

- [x] `class`, `new`, `this` - frontend + high-level IR only; no bytecode/runtime yet
      Classes are represented separately in `IRProgram.classes`; globals only load/store class refs.
- [x] `switch` / `match` / `case` / `default` - parsed/analyzed/emitted as high-level IR
- [x] `try` / `catch` / `throw` - parsed/analyzed/emitted as high-level IR
- [x] `is` operator - parsed/analyzed/emitted as high-level IR
- [x] arrays and dicts - literals + indexing parse/analyze/emitted as high-level IR
- [x] template strings - basic `${identifier}` interpolation parsed/analyzed/emitted as high-level IR
- [x] `??` and `?.` - parsed/analyzed/emitted as high-level IR

## Semantic analyzer

- [x] `let` / `const` / `var` are all treated as the same kind - no error on
      reassigning a `const`
- [x] check that `break` / `continue` are inside a loop (once `for` exists)

## Testing

- [ ] No `test/` folder on this branch. `main` claims 195 passing tests; `rewritte` has zero
