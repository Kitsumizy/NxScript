package nx.parser.nxscript;

import haxe.Timer;
import nx.ast.nodes.*;
import nx.ast.Expr;
import nx.lexer.TokenType;
import nx.ast.Statement;
import nx.parser.Program;
import nx.lexer.nxscript.NxKeyword;
import nx.parser.Parser;


class NxParser extends Parser<NxKeyword> {
    override function parse():Program {
        parserTime = Timer.stamp();
        var statements:Array<Statement> = [];

        while (!isAtEnd()) {
            statements.push(parseDeclaration());
        }
        parserTime = Timer.stamp() - parserTime;
        return new Program(statements);
    }

    function parseDeclaration():Statement {
        if (matchKeyword(NxKeyword.Function))
            return parseFunctionDeclaration();

        if (matchKeyword(NxKeyword.Const))
            return parseVariableDeclaration(true);

        if (matchKeyword(NxKeyword.Var) || matchKeyword(NxKeyword.Let))
            return parseVariableDeclaration(false);

        return parseStatement();
    }

    function parseStatement():Statement {
        if (match(TokenType.LeftBrace))
            return parseBlock();

        if (matchKeyword(NxKeyword.If))
            return parseIfStatement();

        if (matchKeyword(NxKeyword.While))
            return parseWhileStatement();

        if (matchKeyword(NxKeyword.Return))
            return parseReturnStatement();

        return parseExpressionStatement();
    }

    function parseBlock():BlockStmt {
        var statements:Array<Statement> = [];

        while (!check(TokenType.RightBrace) && !isAtEnd()) {
            statements.push(parseDeclaration());
        }

        expect(TokenType.RightBrace, "Expected '}' after block.");
        return new BlockStmt(statements);
    }

    function parseFunctionDeclaration():Statement {
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

        return new FunctionStmt(nameToken.lexeme, nameToken.position, params, parseBlock());
    }

    function parseVariableDeclaration(isConst:Bool):Statement {
        var nameToken = expect(TokenType.Identifier, "Expected variable name.");
        var initializer:Null<Expr> = null;

        if (match(TokenType.Equal))
            initializer = parseExpression();

        match(TokenType.Semicolon);
        return new VariableStmt(nameToken.lexeme, nameToken.position, initializer, isConst);
    }

    function parseIfStatement():Statement {
        expect(TokenType.LeftParen, "Expected '(' after 'if'.");
        var condition = parseExpression();
        expect(TokenType.RightParen, "Expected ')' after if condition.");

        var thenBranch = parseStatement();
        var elseBranch:Null<Statement> = null;

        if (matchKeyword(NxKeyword.Else))
            elseBranch = parseStatement();

        return new IfStmt(condition, thenBranch, elseBranch);
    }

    function parseWhileStatement():Statement {
        expect(TokenType.LeftParen, "Expected '(' after 'while'.");
        var condition = parseExpression();
        expect(TokenType.RightParen, "Expected ')' after while condition.");

        return new WhileStmt(condition, parseStatement());
    }

    function parseReturnStatement():Statement {
        var value:Null<Expr> = null;

        if (!check(TokenType.RightBrace) && !isAtEnd())
            value = parseExpression();

        match(TokenType.Semicolon);
        return new ReturnStmt(value);
    }

    function parseExpressionStatement():Statement {
        var expression = parseExpression();
        match(TokenType.Semicolon);
        return new ExpressionStmt(expression);
    }

    function parseExpression():Expr {
        return parseAssignment();
    }

    function parseAssignment():Expr {
        var expr = parseOr();

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
            return parseUnary();

        return parseCall();
    }

    function parseCall():Expr {
        var expr = parsePrimary();

        while (match(TokenType.LeftParen)) {
            var args:Array<Expr> = [];

            if (!check(TokenType.RightParen)) {
                do {
                    args.push(parseExpression());
                } while (match(TokenType.Comma));
            }

            expect(TokenType.RightParen, "Expected ')' after arguments.");
            expr = new CallExpr(expr, args);
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

        if (match(TokenType.LeftParen)) {
            var expr = parseExpression();
            expect(TokenType.RightParen, "Expected ')' after expression.");
            return expr;
        }

        var token = advance();
        return new LiteralExpr(token.lexeme);
    }
}