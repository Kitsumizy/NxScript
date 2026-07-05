package nx.parser;

import nx.ast.Expr;
import nx.ast.Statement;
import nx.ast.nodes.*;
import nx.lexer.TokenType;

class Program {
    public var statements:Array<Statement>;
    public function new(statements:Array<Statement>) {
        this.statements = statements;
    }
    public function toString():String {
        var lines:Array<String> = ["Program"];

        for (i in 0...statements.length)
            appendStatement(lines, statements[i], "", i == statements.length - 1);

        return lines.join("\n");
    }

    static function appendStatement(lines:Array<String>, statement:Statement, prefix:String, isLast:Bool):Void {
        var connector = isLast ? " └─ " : " ├─ ";
        var childPrefix = prefix + (isLast ? "    " : " │   ");

        if (Std.isOfType(statement, FunctionStmt)) {
            var func:FunctionStmt = cast statement;
            lines.push(prefix + connector + 'Function ${func.name}(${func.params.join(", ")})');
            appendStatement(lines, func.body, childPrefix, true);
            return;
        }

        if (Std.isOfType(statement, BlockStmt)) {
            var block:BlockStmt = cast statement;
            lines.push(prefix + connector + "Block");

            for (i in 0...block.statements.length)
                appendStatement(lines, block.statements[i], childPrefix, i == block.statements.length - 1);

            return;
        }

        if (Std.isOfType(statement, ExpressionStmt)) {
            var exprStmt:ExpressionStmt = cast statement;
            lines.push(prefix + connector + formatExpr(exprStmt.expression));
            return;
        }

        if (Std.isOfType(statement, VariableStmt)) {
            var variable:VariableStmt = cast statement;
            var kind = variable.isConst ? "Const" : "Var";
            var label = '${kind} ${variable.name}';

            if (variable.initializer != null)
                label += ' = ${formatExpr(variable.initializer)}';

            lines.push(prefix + connector + label);
            return;
        }

        if (Std.isOfType(statement, ReturnStmt)) {
            var ret:ReturnStmt = cast statement;
            lines.push(prefix + connector + (ret.value == null ? "Return" : 'Return ${formatExpr(ret.value)}'));
            return;
        }

        if (Std.isOfType(statement, IfStmt)) {
            var ifStmt:IfStmt = cast statement;
            lines.push(prefix + connector + 'If ${formatExpr(ifStmt.condition)}');
            appendStatement(lines, ifStmt.thenBranch, childPrefix, ifStmt.elseBranch == null);

            if (ifStmt.elseBranch != null) {
                var elsePrefix = prefix + "    ";
                lines.push(prefix + " └─ Else");
                appendStatement(lines, ifStmt.elseBranch, elsePrefix + "    ", true);
            }

            return;
        }

        if (Std.isOfType(statement, WhileStmt)) {
            var whileStmt:WhileStmt = cast statement;
            lines.push(prefix + connector + 'While ${formatExpr(whileStmt.condition)}');
            appendStatement(lines, whileStmt.body, childPrefix, true);
            return;
        }

        lines.push(prefix + connector + Std.string(statement));
    }

    static function formatExpr(expr:Expr):String {
        if (Std.isOfType(expr, IdentifierExpr)) {
            var identifier:IdentifierExpr = cast expr;
            return identifier.name;
        }

        if (Std.isOfType(expr, LiteralExpr)) {
            var literal:LiteralExpr = cast expr;
            return formatLiteral(literal.value);
        }

        if (Std.isOfType(expr, CallExpr)) {
            var call:CallExpr = cast expr;
            var args = [for (arg in call.args) formatExpr(arg)];
            return '${formatExpr(call.callee)}(${args.join(", ")})';
        }

        if (Std.isOfType(expr, BinaryExpr)) {
            var binary:BinaryExpr<Dynamic> = cast expr;
            return '${formatExpr(binary.left)} ${formatOperator(cast binary.op)} ${formatExpr(binary.right)}';
        }

        if (Std.isOfType(expr, UnaryExpr)) {
            var unary:UnaryExpr<Dynamic> = cast expr;
            return '${formatOperator(cast unary.op)}${formatExpr(unary.right)}';
        }

        return Std.string(expr);
    }

    static function formatLiteral(value:Dynamic):String {
        if (value == null)
            return "null";

        switch (Type.typeof(value)) {
            case TClass(c):
                if (Type.getClassName(c) == "String")
                    return '"${Std.string(value)}"';
            default:
        }

        return Std.string(value);
    }

    static function formatOperator(op:TokenType<Dynamic>):String {
        return switch (op) {
            case Plus: "+";
            case Minus: "-";
            case Star: "*";
            case Slash: "/";
            case Percent: "%";
            case Equal: "=";
            case EqualEqual: "==";
            case Bang: "!";
            case BangEqual: "!=";
            case Greater: ">";
            case GreaterEqual: ">=";
            case Less: "<";
            case LessEqual: "<=";
            case AndAnd: "&&";
            case OrOr: "||";
            case PlusEqual: "+=";
            case MinusEqual: "-=";
            case StarEqual: "*=";
            case SlashEqual: "/=";
            case Arrow: "=>";
            default: Std.string(op);
        };
    }
}