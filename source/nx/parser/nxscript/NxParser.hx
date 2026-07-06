package nx.parser.nxscript;

import haxe.Timer;
import nx.ast.nodes.*;
import nx.ast.nodes.DictExpr.DictEntry;
import nx.ast.nodes.MatchExpr.MatchCase;
import nx.ast.Expr;
import nx.lexer.TokenType;
import nx.parser.Program;
import nx.lexer.nxscript.NxKeyword;
import nx.parser.Parser;
import nx.script.NxManager;


class NxParser extends Parser<NxKeyword> {
    override function parse():Program {
        parserTime = Timer.stamp();
        var exprs:Array<Expr> = [];

        while (!isAtEnd()) {
            exprs.push(parseDeclaration());
        }
        parserTime = Timer.stamp() - parserTime;
        return new Program(exprs);
    }

    function parseDeclaration():Expr {
        if (matchKeyword(NxKeyword.Function))
            return parseFunctionDeclaration();

        if (matchKeyword(NxKeyword.Class))
            return parseClassDeclaration();

        if (matchKeyword(NxKeyword.Const))
            return parseVariableDeclaration(true);

        if (matchKeyword(NxKeyword.Var) || matchKeyword(NxKeyword.Let))
            return parseVariableDeclaration(false);

        return parseTopLevelExpr();
    }

    function parseTopLevelExpr():Expr {
        if (match(TokenType.LeftBrace))
            return parseBlock();

        if (matchKeyword(NxKeyword.If))
            return parseIfExpr();

        if (matchKeyword(NxKeyword.While))
            return parseWhileExpr();

        if (matchKeyword(NxKeyword.For))
            return parseForExpr();

        if (matchKeyword(NxKeyword.Return))
            return parseReturnExpr();

        if (matchKeyword(NxKeyword.Break))
            return parseBreakExpr();

        if (matchKeyword(NxKeyword.Continue))
            return parseContinueExpr();

        if (matchKeyword(NxKeyword.Match) || matchKeyword(NxKeyword.Switch))
            return parseMatchExpr();

        if (matchKeyword(NxKeyword.Try))
            return parseTryCatchExpr();

        if (matchKeyword(NxKeyword.Throw))
            return parseThrowExpr();

        return parseExpressionExpr();
    }

    function parseBlock():BlockExpr {
        var exprs:Array<Expr> = [];

        while (!check(TokenType.RightBrace) && !isAtEnd()) {
            exprs.push(parseDeclaration());
        }

        expect(TokenType.RightBrace, "Expected '}' after block.");
        return new BlockExpr(exprs);
    }

    function parseFunctionDeclaration():Expr {
        var nameToken = expect(TokenType.Identifier, "Expected function name.");
        expect(TokenType.LeftParen, "Expected '(' after function name.");

        var params:Array<String> = [];
        if (!check(TokenType.RightParen)) {
            do {
                params.push(expect(TokenType.Identifier, "Expected parameter name.").lexeme);
            } while (match(TokenType.Comma));
        }

        expect(TokenType.RightParen, "Expected ')' after parameter list.");
        expect(TokenType.LeftBrace, "Expected '{' before function body.");

        return new FunctionExpr(nameToken.lexeme, nameToken.position, params, parseBlock());
    }

    function parseClassDeclaration():Expr {
        var nameToken = expect(TokenType.Identifier, "Expected class name.");
        expect(TokenType.LeftBrace, "Expected '{' before class body.");
        var members:Array<Expr> = [];

        while (!check(TokenType.RightBrace) && !isAtEnd()) {
            if (matchKeyword(NxKeyword.Function)) {
                members.push(parseFunctionDeclaration());
                continue;
            }

            if (matchKeyword(NxKeyword.Const)) {
                members.push(parseVariableDeclaration(true));
                continue;
            }

            if (matchKeyword(NxKeyword.Var) || matchKeyword(NxKeyword.Let)) {
                members.push(parseVariableDeclaration(false));
                continue;
            }

            members.push(parseTopLevelExpr());
        }

        expect(TokenType.RightBrace, "Expected '}' after class body.");
        return new ClassExpr(nameToken.lexeme, nameToken.position, members);
    }

    function parseVariableDeclaration(isConst:Bool, consumeSemicolon:Bool = true):Expr {
        var nameToken = expect(TokenType.Identifier, "Expected variable name.");
        var initializer:Null<Expr> = null;

        if (match(TokenType.Equal))
            initializer = parseExpression();

        if (consumeSemicolon)
            match(TokenType.Semicolon);
        return new VariableExpr(nameToken.lexeme, nameToken.position, initializer, isConst);
    }

    function parseIfExpr():Expr {
        expect(TokenType.LeftParen, "Expected '(' after 'if'.");
        var condition = parseExpression();
        expect(TokenType.RightParen, "Expected ')' after if condition.");

        var thenBranch = parseTopLevelExpr();
        var elseBranch:Null<Expr> = null;

        if (matchKeyword(NxKeyword.Else))
            elseBranch = parseTopLevelExpr();

        return new IfExpr(condition, thenBranch, elseBranch);
    }

    function parseWhileExpr():Expr {
        expect(TokenType.LeftParen, "Expected '(' after 'while'.");
        var condition = parseExpression();
        expect(TokenType.RightParen, "Expected ')' after while condition.");

        return new WhileExpr(condition, parseTopLevelExpr());
    }

    function parseForExpr():Expr {
        expect(TokenType.LeftParen, "Expected '(' after 'for'.");

        var initializer:Null<Expr> = null;
        if (match(TokenType.Semicolon)) {
        } else if (matchKeyword(NxKeyword.Const)) {
            initializer = parseVariableDeclaration(true, false);
            expect(TokenType.Semicolon, "Expected ';' after for initializer.");
        } else if (matchKeyword(NxKeyword.Var) || matchKeyword(NxKeyword.Let)) {
            initializer = parseVariableDeclaration(false, false);
            expect(TokenType.Semicolon, "Expected ';' after for initializer.");
        } else {
            initializer = parseExpression();
            expect(TokenType.Semicolon, "Expected ';' after for initializer.");
        }

        var condition:Null<Expr> = null;
        if (!check(TokenType.Semicolon))
            condition = parseExpression();

        expect(TokenType.Semicolon, "Expected ';' after for condition.");

        var increment:Null<Expr> = null;
        if (!check(TokenType.RightParen))
            increment = parseExpression();

        expect(TokenType.RightParen, "Expected ')' after for clauses.");
        return new ForExpr(initializer, condition, increment, parseTopLevelExpr());
    }

    function parseReturnExpr():Expr {
        var value:Null<Expr> = null;

        if (!check(TokenType.RightBrace) && !isAtEnd())
            value = parseExpression();

        match(TokenType.Semicolon);
        return new ReturnExpr(value);
    }

    function parseBreakExpr():Expr {
        var token = previous();
        match(TokenType.Semicolon);
        return new BreakExpr(token.position);
    }

    function parseContinueExpr():Expr {
        var token = previous();
        match(TokenType.Semicolon);
        return new ContinueExpr(token.position);
    }

    function parseThrowExpr():Expr {
        var token = previous();
        var value = parseExpression();
        match(TokenType.Semicolon);
        return new ThrowExpr(value, token.position);
    }

    function parseTryCatchExpr():Expr {
        var tryBody = parseTopLevelExpr();
        if (!matchKeyword(NxKeyword.Catch))
            NxManager.onException.emit(peek().error("Expected 'catch' after try body."));
        expect(TokenType.LeftParen, "Expected '(' after 'catch'.");
        var errorToken = expect(TokenType.Identifier, "Expected catch binding name.");
        expect(TokenType.RightParen, "Expected ')' after catch binding.");
        var errorName = errorToken == null ? "error" : errorToken.lexeme;
        var errorPosition = errorToken == null ? previous().position : errorToken.position;
        return new TryCatchExpr(tryBody, errorName, errorPosition, parseTopLevelExpr());
    }

    function parseMatchExpr():Expr {
        var target:Expr;
        if (match(TokenType.LeftParen)) {
            target = parseExpression();
            expect(TokenType.RightParen, "Expected ')' after match target.");
        } else {
            target = parseExpression();
        }

        expect(TokenType.LeftBrace, "Expected '{' before match cases.");
        var cases:Array<MatchCase> = [];
        var defaultBranch:Null<Expr> = null;

        while (!check(TokenType.RightBrace) && !isAtEnd()) {
            if (matchKeyword(NxKeyword.Case)) {
                var pattern = parseExpression();
                consumeCaseSeparator();
                cases.push(new MatchCase(pattern, parseCaseBody()));
                continue;
            }

            if (matchKeyword(NxKeyword.Default)) {
                consumeCaseSeparator();
                defaultBranch = parseCaseBody();
                continue;
            }

            NxManager.onException.emit(peek().error("Expected 'case' or 'default' in match body."));
            advance();
        }

        expect(TokenType.RightBrace, "Expected '}' after match body.");
        return new MatchExpr(target, cases, defaultBranch);
    }

    function consumeCaseSeparator():Void {
        if (match(TokenType.Arrow) || match(TokenType.Colon))
            return;

        NxManager.onException.emit(peek().error("Expected '=>' or ':' after case pattern."));
    }

    function parseCaseBody():Expr {
        if (match(TokenType.LeftBrace))
            return parseBlock();

        return parseTopLevelExpr();
    }

    function parseExpressionExpr():Expr {
        var expression = parseExpression();
        match(TokenType.Semicolon);
        return new ExpressionExpr(expression);
    }

    function parseExpression():Expr {
        return parseAssignment();
    }

    function parseAssignment():Expr {
        var expr = parseNullCoalesce();

        if (match(TokenType.Equal))
            return new BinaryExpr<NxKeyword>(expr, TokenType.Equal, parseAssignment());

        if (match(TokenType.PlusEqual))
            return new BinaryExpr<NxKeyword>(expr, TokenType.PlusEqual, parseAssignment());

        if (match(TokenType.MinusEqual))
            return new BinaryExpr<NxKeyword>(expr, TokenType.MinusEqual, parseAssignment());

        if (match(TokenType.StarEqual))
            return new BinaryExpr<NxKeyword>(expr, TokenType.StarEqual, parseAssignment());

        if (match(TokenType.SlashEqual))
            return new BinaryExpr<NxKeyword>(expr, TokenType.SlashEqual, parseAssignment());

        return expr;
    }

    function parseNullCoalesce():Expr {
        var expr = parseOr();

        while (match(TokenType.QuestionQuestion))
            expr = new BinaryExpr<NxKeyword>(expr, TokenType.QuestionQuestion, parseOr());

        return expr;
    }

    function parseOr():Expr {
        var expr = parseAnd();

        while (match(TokenType.OrOr))
            expr = new BinaryExpr<NxKeyword>(expr, TokenType.OrOr, parseAnd());

        return expr;
    }

    function parseAnd():Expr {
        var expr = parseEquality();

        while (match(TokenType.AndAnd))
            expr = new BinaryExpr<NxKeyword>(expr, TokenType.AndAnd, parseEquality());

        return expr;
    }

    function parseEquality():Expr {
        var expr = parseComparison();

        while (true) {
            if (match(TokenType.EqualEqual)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.EqualEqual, parseComparison());
                continue;
            }

            if (match(TokenType.BangEqual)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.BangEqual, parseComparison());
                continue;
            }

            break;
        }

        return expr;
    }

    function parseComparison():Expr {
        var expr = parseTerm();

        while (true) {
            if (matchKeyword(NxKeyword.Is)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Keyword(NxKeyword.Is), parseTerm());
                continue;
            }

            if (match(TokenType.Greater)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Greater, parseTerm());
                continue;
            }

            if (match(TokenType.GreaterEqual)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.GreaterEqual, parseTerm());
                continue;
            }

            if (match(TokenType.Less)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Less, parseTerm());
                continue;
            }

            if (match(TokenType.LessEqual)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.LessEqual, parseTerm());
                continue;
            }

            break;
        }

        return expr;
    }

    function parseTerm():Expr {
        var expr = parseFactor();

        while (true) {
            if (match(TokenType.Plus)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Plus, parseFactor());
                continue;
            }

            if (match(TokenType.Minus)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Minus, parseFactor());
                continue;
            }

            break;
        }

        return expr;
    }

    function parseFactor():Expr {
        var expr = parseUnary();

        while (true) {
            if (match(TokenType.Star)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Star, parseUnary());
                continue;
            }

            if (match(TokenType.Slash)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Slash, parseUnary());
                continue;
            }

            if (match(TokenType.Percent)) {
                expr = new BinaryExpr<NxKeyword>(expr, TokenType.Percent, parseUnary());
                continue;
            }

            break;
        }

        return expr;
    }

    function parseUnary():Expr {
        if (match(TokenType.Bang))
            return new UnaryExpr<NxKeyword>(TokenType.Bang, parseUnary());

        if (match(TokenType.Minus))
            return new UnaryExpr<NxKeyword>(TokenType.Minus, parseUnary());

        if (match(TokenType.Plus))
            return new UnaryExpr<NxKeyword>(TokenType.Plus, parseUnary());

        if (matchKeyword(NxKeyword.New))
            return parseNewExpr(previous().position);

        return parseCall();
    }

    function parseNewExpr(position):Expr {
        var callee = parseCall();
        var args:Array<Expr> = [];

        if (Std.isOfType(callee, CallExpr)) {
            var call:CallExpr = cast callee;
            callee = call.callee;
            args = call.args;
        }

        return new NewExpr(callee, args, position);
    }

    function parseCall():Expr {
        var expr = parsePrimary();

        while (true) {
            if (match(TokenType.LeftParen)) {
                var args:Array<Expr> = [];

                if (!check(TokenType.RightParen)) {
                    do {
                        args.push(parseExpression());
                    } while (match(TokenType.Comma));
                }

                expect(TokenType.RightParen, "Expected ')' after arguments.");
                expr = new CallExpr(expr, args);
                continue;
            }

            if (match(TokenType.LeftBracket)) {
                var index = parseExpression();
                expect(TokenType.RightBracket, "Expected ']' after index expression.");
                expr = new IndexExpr(expr, index);
                continue;
            }

            if (match(TokenType.Dot)) {
                var name = expect(TokenType.Identifier, "Expected property name after '.'.");
                expr = new MemberExpr(expr, name.lexeme, name.position);
                continue;
            }

            if (match(TokenType.QuestionDot)) {
                var name = expect(TokenType.Identifier, "Expected property name after '?.'.");
                expr = new MemberExpr(expr, name.lexeme, name.position, true);
                continue;
            }

            break;
        }

        return expr;
    }

    function parsePrimary():Expr {
        if (check(TokenType.Number)) {
            var token = advance();
            return new LiteralExpr(Std.parseFloat(token.lexeme));
        }

        if (check(TokenType.String)) {
            var token = advance();
            var raw = token.lexeme;
            if (raw.length >= 2 && raw.charAt(0) == "`")
                return parseTemplateLiteral(raw);
            if (raw.length >= 2)
                raw = raw.substr(1, raw.length - 2);
            return new LiteralExpr(raw);
        }

        if (matchKeyword(NxKeyword.True))
            return new LiteralExpr(true);

        if (matchKeyword(NxKeyword.False))
            return new LiteralExpr(false);

        if (matchKeyword(NxKeyword.Null))
            return new LiteralExpr(null);

        if (matchKeyword(NxKeyword.This))
            return new IdentifierExpr("this", previous().position);

        if (check(TokenType.Identifier)) {
            var token = advance();
            return new IdentifierExpr(token.lexeme, token.position);
        }

        if (match(TokenType.LeftBracket))
            return parseArrayLiteral();

        if (match(TokenType.LeftBrace))
            return parseDictLiteral();

        if (match(TokenType.LeftParen)) {
            var expr = parseExpression();
            expect(TokenType.RightParen, "Expected ')' after expression.");
            return expr;
        }

        switch (peek().type) {
            case Keyword(keyword):
                var token = advance();
                var message = 'Keyword ${Std.string(keyword)} is reserved but not implemented here.';
                NxManager.onException.emit(token.error(message));
                return new UnsupportedExpr(message, token.position);
            default:
        }

        var token = advance();
        return new LiteralExpr(token.lexeme);
    }

    function parseArrayLiteral():Expr {
        var elements:Array<Expr> = [];

        if (!check(TokenType.RightBracket)) {
            do {
                elements.push(parseExpression());
            } while (match(TokenType.Comma));
        }

        expect(TokenType.RightBracket, "Expected ']' after array literal.");
        return new ArrayExpr(elements);
    }

    function parseDictLiteral():Expr {
        var entries:Array<DictEntry> = [];

        if (!check(TokenType.RightBrace)) {
            do {
                var key = parseExpression();
                expect(TokenType.Colon, "Expected ':' between dict key and value.");
                var value = parseExpression();
                entries.push(new DictEntry(key, value));
            } while (match(TokenType.Comma));
        }

        expect(TokenType.RightBrace, "Expected '}' after dict literal.");
        return new DictExpr(entries);
    }

    function parseTemplateLiteral(raw:String):Expr {
        var body = raw.length >= 2 ? raw.substr(1, raw.length - 2) : raw;
        var parts:Array<Expr> = [];
        var cursor = 0;

        while (cursor < body.length) {
            var start = body.indexOf("${", cursor);
            if (start < 0) {
                if (cursor < body.length)
                    parts.push(new LiteralExpr(body.substr(cursor)));
                break;
            }

            if (start > cursor)
                parts.push(new LiteralExpr(body.substr(cursor, start - cursor)));

            var end = body.indexOf("}", start + 2);
            if (end < 0) {
                parts.push(new LiteralExpr(body.substr(start)));
                break;
            }

            var name = StringTools.trim(body.substr(start + 2, end - start - 2));
            parts.push(new IdentifierExpr(name, previous().position));
            cursor = end + 1;
        }

        return new TemplateExpr(parts);
    }
}
