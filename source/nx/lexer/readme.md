# Lexers

This directory contains all language lexers for NxScript.

A lexer **must only tokenize source code**. It should not perform parsing, semantic analysis, optimization, or VM-specific logic. Every lexer should produce a standard `TokenStream` that any parser can consume.

If the language you need is not available, feel free to open an issue before implementing it.

## Example

```haxe
var lexer = new NxLexer(new NxSource("""
function hello() {
    trace("Hello, World!")
}
"""));

var tokens = lexer.lex();
trace(tokens);
```

Output:

```text
TokenStream
 ├─ Token(type=Keyword(Function), lexeme="function")
 ├─ Token(type=Identifier, lexeme="hello")
 ├─ Token(type=LeftParen, lexeme="(")
 ├─ Token(type=RightParen, lexeme=")")
 ├─ Token(type=LeftBrace, lexeme="{")
 ├─ Token(type=Identifier, lexeme="trace")
 ├─ Token(type=LeftParen, lexeme="(")
 ├─ Token(type=String, lexeme="Hello, World!")
 ├─ Token(type=RightParen, lexeme=")")
 ├─ Token(type=RightBrace, lexeme="}")
 └─ Token(type=EOF, lexeme="")
```

# How to make my own lexer

Creating a lexer is simple.

1. Create a keyword enum for your language.

```haxe
enum MyKeyword {
    Function;
    If;
    Else;
    Return;
}
```

2. Extend the generic `Lexer`.

```haxe
package mylang;

class MyLexer extends Lexer<MyKeyword> {
    public function new(source:NxSource) {
        super(source);
    }

    override function lex():TokenStream<MyKeyword> {
        // Recognize identifiers and keywords here.
    }

}
```

3. Produce a valid `TokenStream`.

```haxe
var lexer = new MyLexer(source);
var tokens = lexer.lex();
```

That's it. As long as your lexer generates a valid `TokenStream`, it can be used by any parser compatible with your language.
