package nx.lexer.nxscript;

import haxe.Timer;
import nx.common.NxPosition;
import nx.lexer.Lexer;
import nx.lexer.Token;
import nx.lexer.TokenType;

class NxLexer extends Lexer<NxKeyword> {


    override function lex():TokenStream<NxKeyword> {
        var start = Timer.stamp();
        var tokens:Array<Token<NxKeyword>> = [];

        while (!eof()) {
            var startLine = line;
            var startColumn = column;
            var startIndex = index;
            var c = peek();

            if (c == " " || c == "\t" || c == "\r" || c == "\n") {
                advance();
                continue;
            }

            if (c == "#") {
                while (!eof() && peek() != "\n")
                    advance();
                continue;
            }

            if (isAlpha(c)) {
                tokens.push(readIdentifier(startLine, startColumn, startIndex));
                continue;
            }

            if (isDigit(c)) {
                tokens.push(readNumber(startLine, startColumn, startIndex));
                continue;
            }

            switch (c) {
                case "(": pushSimpleToken(tokens, TokenType.LeftParen, advance(), startLine, startColumn, startIndex);
                case ")": pushSimpleToken(tokens, TokenType.RightParen, advance(), startLine, startColumn, startIndex);
                case "{": pushSimpleToken(tokens, TokenType.LeftBrace, advance(), startLine, startColumn, startIndex);
                case "}": pushSimpleToken(tokens, TokenType.RightBrace, advance(), startLine, startColumn, startIndex);
                case "[": pushSimpleToken(tokens, TokenType.LeftBracket, advance(), startLine, startColumn, startIndex);
                case "]": pushSimpleToken(tokens, TokenType.RightBracket, advance(), startLine, startColumn, startIndex);
                case ",": pushSimpleToken(tokens, TokenType.Comma, advance(), startLine, startColumn, startIndex);
                case ":": pushSimpleToken(tokens, TokenType.Colon, advance(), startLine, startColumn, startIndex);
                case ";": pushSimpleToken(tokens, TokenType.Semicolon, advance(), startLine, startColumn, startIndex);
                case ".": pushSimpleToken(tokens, TokenType.Dot, advance(), startLine, startColumn, startIndex);

                case "+":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.PlusEqual, "+=", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Plus, "+", startLine, startColumn, startIndex));
                    }

                case "-":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.MinusEqual, "-=", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Minus, "-", startLine, startColumn, startIndex));
                    }

                case "*":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.StarEqual, "*=", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Star, "*", startLine, startColumn, startIndex));
                    }

                case "/":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.SlashEqual, "/=", startLine, startColumn, startIndex));
                    } else if (matchChar("/")) {
                        while (!eof() && peek() != "\n")
                            advance();
                    } else if (matchChar("*")) {
                        while (!eof()) {
                            if (peek() == "*" && peek(1) == "/") {
                                advance();
                                advance();
                                break;
                            }
                            advance();
                        }
                    } else {
                        tokens.push(makeToken(TokenType.Slash, "/", startLine, startColumn, startIndex));
                    }

                case "%": pushSimpleToken(tokens, TokenType.Percent, advance(), startLine, startColumn, startIndex);

                case "=":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.EqualEqual, "==", startLine, startColumn, startIndex));
                    } else if (matchChar(">")) {
                        tokens.push(makeToken(TokenType.Arrow, "=>", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Equal, "=", startLine, startColumn, startIndex));
                    }

                case "!":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.BangEqual, "!=", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Bang, "!", startLine, startColumn, startIndex));
                    }

                case ">":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.GreaterEqual, ">=", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Greater, ">", startLine, startColumn, startIndex));
                    }

                case "<":
                    advance();
                    if (matchChar("=")) {
                        tokens.push(makeToken(TokenType.LessEqual, "<=", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Less, "<", startLine, startColumn, startIndex));
                    }

                case "&":
                    advance();
                    if (matchChar("&")) {
                        tokens.push(makeToken(TokenType.AndAnd, "&&", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Invalid, "&", startLine, startColumn, startIndex));
                    }

                case "|":
                    advance();
                    if (matchChar("|")) {
                        tokens.push(makeToken(TokenType.OrOr, "||", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Invalid, "|", startLine, startColumn, startIndex));
                    }

                case "?":
                    advance();
                    if (matchChar("?")) {
                        tokens.push(makeToken(TokenType.QuestionQuestion, "??", startLine, startColumn, startIndex));
                    } else if (matchChar(".")) {
                        tokens.push(makeToken(TokenType.QuestionDot, "?.", startLine, startColumn, startIndex));
                    } else {
                        tokens.push(makeToken(TokenType.Invalid, "?", startLine, startColumn, startIndex));
                    }

                case "\"", "'", "`":
                    tokens.push(readString(startLine, startColumn, startIndex));

                default:
                    tokens.push(makeToken(TokenType.Invalid, advance(), startLine, startColumn, startIndex));
            }
        }

        tokens.push(makeToken(TokenType.EOF, "", line, column, index));
        lexTime = Timer.stamp() - start;
        // return tokens;
        return new TokenStream(tokens);
    }

    function readIdentifier(startLine:Int, startColumn:Int, startIndex:Int):Token<NxKeyword> {
        var value = "";

        while (!eof() && isAlphaNumeric(peek()))
            value += advance();

        return makeToken(keywordType(value), value, startLine, startColumn, startIndex);
    }

    function readNumber(startLine:Int, startColumn:Int, startIndex:Int):Token<NxKeyword> {
        var value = "";

        while (!eof() && isDigit(peek()))
            value += advance();

        if (!eof() && peek() == "." && isDigit(peek(1))) {
            value += advance();

            while (!eof() && isDigit(peek()))
                value += advance();
        }

        return makeToken(TokenType.Number, value, startLine, startColumn, startIndex);
    }

    function readString(startLine:Int, startColumn:Int, startIndex:Int):Token<NxKeyword> {
        var quote = advance();
        var value = quote;

        while (!eof()) {
            var c = advance();
            value += c;

            if (c == quote)
                return makeToken(TokenType.String, value, startLine, startColumn, startIndex);

            if (c == "\\" && !eof())
                value += advance();
        }

        return makeToken(TokenType.Invalid, value, startLine, startColumn, startIndex);
    }

    function keywordType(value:String):TokenType<NxKeyword> {
        return switch (value) {
            case "if": TokenType.Keyword(NxKeyword.If);
            case "else": TokenType.Keyword(NxKeyword.Else);
            case "while": TokenType.Keyword(NxKeyword.While);
            case "for": TokenType.Keyword(NxKeyword.For);
            case "func" | "function": TokenType.Keyword(NxKeyword.Function);
            case "return": TokenType.Keyword(NxKeyword.Return);
            case "break": TokenType.Keyword(NxKeyword.Break);
            case "continue": TokenType.Keyword(NxKeyword.Continue);
            case "let": TokenType.Keyword(NxKeyword.Let);
            case "var", "meowvar": TokenType.Keyword(NxKeyword.Var);
            case "const": TokenType.Keyword(NxKeyword.Const);
            case "true": TokenType.Keyword(NxKeyword.True);
            case "false": TokenType.Keyword(NxKeyword.False);
            case "null": TokenType.Keyword(NxKeyword.Null);
            case "new": TokenType.Keyword(NxKeyword.New);
            case "this": TokenType.Keyword(NxKeyword.This);
            case "switch": TokenType.Keyword(NxKeyword.Switch);
            case "case": TokenType.Keyword(NxKeyword.Case);
            case "default": TokenType.Keyword(NxKeyword.Default);
            case "class": TokenType.Keyword(NxKeyword.Class);
            case "abstract": TokenType.Keyword(NxKeyword.Abstract);
            case "match": TokenType.Keyword(NxKeyword.Match);
            case "try": TokenType.Keyword(NxKeyword.Try);
            case "catch": TokenType.Keyword(NxKeyword.Catch);
            case "throw": TokenType.Keyword(NxKeyword.Throw);
            case "is": TokenType.Keyword(NxKeyword.Is);
            default: TokenType.Identifier;
        }
    }

    inline function pushSimpleToken(tokens:Array<Token<NxKeyword>>, type:TokenType<NxKeyword>, lexeme:String, startLine:Int, startColumn:Int, startIndex:Int):Void {
        tokens.push(makeToken(type, lexeme, startLine, startColumn, startIndex));
    }

    inline function matchChar(expected:String):Bool {
        if (eof() || peek() != expected)
            return false;

        advance();
        return true;
    }

    inline function makeToken(type:TokenType<NxKeyword>, lexeme:String, startLine:Int, startColumn:Int, startIndex:Int):Token<NxKeyword> {
        return new Token(type, lexeme, new NxPosition(startLine, startColumn, startIndex, "<input>", source.content));
    }

    
}
