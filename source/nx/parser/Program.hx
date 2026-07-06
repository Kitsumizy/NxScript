package nx.parser;

import nx.ast.Expr;
import nx.ast.nodes.*;
import nx.lexer.TokenType;

class Program {
    public var exprs:Array<Expr>;
    public function new(exprs:Array<Expr>) {
        this.exprs = exprs;
    }
    public function toString():String {
        var lines:Array<String> = ["Program"];

        for (i in 0...exprs.length)
            appendTopLevelExpr(lines, exprs[i], "", i == exprs.length - 1);

        return lines.join("\n");
    }

    static function appendTopLevelExpr(lines:Array<String>, expr:Expr, prefix:String, isLast:Bool):Void {
        var connector = isLast ? " └─ " : " ├─ ";
        var childPrefix = prefix + (isLast ? "    " : " │   ");

        if (Std.isOfType(expr, FunctionExpr)) {
            var func:FunctionExpr = cast expr;
            lines.push(prefix + connector + 'Function ${func.name}(${func.params.join(", ")})');
            appendTopLevelExpr(lines, func.body, childPrefix, true);
            return;
        }

        if (Std.isOfType(expr, BlockExpr)) {
            var block:BlockExpr = cast expr;
            lines.push(prefix + connector + "Block");

            for (i in 0...block.exprs.length)
                appendTopLevelExpr(lines, block.exprs[i], childPrefix, i == block.exprs.length - 1);

            return;
        }

        if (Std.isOfType(expr, ExpressionExpr)) {
            var exprStmt:ExpressionExpr = cast expr;
            lines.push(prefix + connector + formatExpr(exprStmt.expression));
            return;
        }

        if (Std.isOfType(expr, VariableExpr)) {
            var variable:VariableExpr = cast expr;
            var kind = variable.isConst ? "Const" : "Var";
            var label = '${kind} ${variable.name}';

            if (variable.initializer != null)
                label += ' = ${formatExpr(variable.initializer)}';

            lines.push(prefix + connector + label);
            return;
        }

        if (Std.isOfType(expr, ReturnExpr)) {
            var ret:ReturnExpr = cast expr;
            lines.push(prefix + connector + (ret.value == null ? "Return" : 'Return ${formatExpr(ret.value)}'));
            return;
        }

        if (Std.isOfType(expr, IfExpr)) {
            var ifExpr:IfExpr = cast expr;
            lines.push(prefix + connector + 'If ${formatExpr(ifExpr.condition)}');
            appendTopLevelExpr(lines, ifExpr.thenBranch, childPrefix, ifExpr.elseBranch == null);

            if (ifExpr.elseBranch != null) {
                var elsePrefix = prefix + "    ";
                lines.push(prefix + " └─ Else");
                appendTopLevelExpr(lines, ifExpr.elseBranch, elsePrefix + "    ", true);
            }

            return;
        }

        if (Std.isOfType(expr, WhileExpr)) {
            var whileExpr:WhileExpr = cast expr;
            lines.push(prefix + connector + 'While ${formatExpr(whileExpr.condition)}');
            appendTopLevelExpr(lines, whileExpr.body, childPrefix, true);
            return;
        }

        if (Std.isOfType(expr, ForExpr)) {
            var forExpr:ForExpr = cast expr;
            lines.push(prefix + connector + 'For');
            if (forExpr.initializer != null)
                lines.push(childPrefix + "init " + formatExpr(forExpr.initializer));
            if (forExpr.condition != null)
                lines.push(childPrefix + "cond " + formatExpr(forExpr.condition));
            if (forExpr.increment != null)
                lines.push(childPrefix + "inc " + formatExpr(forExpr.increment));
            appendTopLevelExpr(lines, forExpr.body, childPrefix, true);
            return;
        }

        if (Std.isOfType(expr, BreakExpr)) {
            lines.push(prefix + connector + "Break");
            return;
        }

        if (Std.isOfType(expr, ContinueExpr)) {
            lines.push(prefix + connector + "Continue");
            return;
        }

        if (Std.isOfType(expr, UnsupportedExpr)) {
            var unsupported:UnsupportedExpr = cast expr;
            lines.push(prefix + connector + 'Unsupported ${unsupported.message}');
            return;
        }

        lines.push(prefix + connector + Std.string(expr));
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

        if (Std.isOfType(expr, ArrayExpr)) {
            var arrayExpr:ArrayExpr = cast expr;
            return '[${[for (element in arrayExpr.elements) formatExpr(element)].join(", ")}]';
        }

        if (Std.isOfType(expr, DictExpr)) {
            var dictExpr:DictExpr = cast expr;
            return '{${[for (entry in dictExpr.entries) formatExpr(entry.key) + ": " + formatExpr(entry.value)].join(", ")}}';
        }

        if (Std.isOfType(expr, IndexExpr)) {
            var indexExpr:IndexExpr = cast expr;
            return '${formatExpr(indexExpr.target)}[${formatExpr(indexExpr.index)}]';
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
            case QuestionQuestion: "??";
            case QuestionDot: "?.";
            case PlusEqual: "+=";
            case MinusEqual: "-=";
            case StarEqual: "*=";
            case SlashEqual: "/=";
            case Arrow: "=>";
            default: Std.string(op);
        };
    }
}
