# Parsers

This directory contains all language parsers for NxScript.

A parser **must only transform a `TokenStream` into an AST (`Program`)**. It should not perform semantic analysis, optimization, IR generation, or VM-specific logic.

Every parser is expected to consume the standard `TokenStream` produced by its corresponding lexer and return a valid `Program`.

If the language you need is not available, feel free to open an issue before implementing it.

## Example

```haxe
var lexer = new NxLexer(new NxSource('
function hello() {
    trace("Hello, World!")
}
'));

var tokens = lexer.lex();

var parser = new NxParser(tokens);
var program = parser.parse();

trace(program);
```

Output:

```text
Program
 └─ Function hello()
     └─ Block
         └─ trace("Hello, World!")
```

# How to make my own parser

Creating a parser is straightforward.

1. Create a parser that extends the generic `Parser`.

```haxe
package mylang;

class MyParser extends Parser<MyKeyword> {
    public function new(tokens:TokenStream<MyKeyword>) {
        super(tokens);
    }

    override function parse():Program {
        // Parse the token stream and return an AST.
    }
}
```

2. Read tokens from the `TokenStream`.

```haxe
if (matchKeyword(MyKeyword.Function))
    return parseFunction();
```

3. Build AST nodes.

```haxe
return new FunctionExpr(
    name,
    position,
    parameters,
    body
);
```

4. Return the completed program.

```haxe
return new Program(exprs);
```

That's it. As long as your parser consumes a valid `TokenStream` and produces a valid `Program`, it can be used with the rest of the NxScript pipeline.
