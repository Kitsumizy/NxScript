package nx.script.parsers;

import nx.script.Token;

using StringTools;

/**
 * Tokenizer for Latino language (Spanish-based programming language).
 * 
 * Keywords: variable, funcion, clase, retornar, si, sino, mientras, para, etc.
 * Comments: // line, /* * / block
 * Strings: "..." and '...' with ${} interpolation
 */
class LatinoTokenizer {
	var input:String;
	var pos:Int = 0;
	var line:Int = 1;
	var col:Int = 1;
	var pendingTokens:Array<TokenPos> = [];

	static var keywords = [
		"variable" => KVar,
		"var" => KVar,
		"const" => KConst,
		"funcion" => KFunc,
		"fun" => KFunc,
		"function" => KFunction,
		"clase" => KClass,
		"class" => KClass,
		"extiende" => KExtends,
		"extends" => KExtends,
		"nuevo" => KNew,
		"new" => KNew,
		"esto" => KThis,
		"this" => KThis,
		"retornar" => KReturn,
		"return" => KReturn,
		"si" => KIf,
		"if" => KIf,
		"sino" => KElse,
		"else" => KElse,
		"si_no" => KElse,
		"mientras" => KWhile,
		"while" => KWhile,
		"para" => KFor,
		"for" => KFor,
		"desde" => KFrom,
		"hasta" => KUntil,
		"en" => KIn,
		"in" => KIn,
		"romper" => KBreak,
		"break" => KBreak,
		"continuar" => KContinue,
		"continue" => KContinue,
		"verdadero" => KTrue,
		"true" => KTrue,
		"falso" => KFalse,
		"false" => KFalse,
		"nulo" => KNull,
		"null" => KNull,
		"intentar" => KTry,
		"try" => KTry,
		"capturar" => KCatch,
		"catch" => KCatch,
		"lanzar" => KThrow,
		"throw" => KThrow,
		"seleccionar" => KSwitch,
		"switch" => KSwitch,
		"caso" => KCase,
		"case" => KCase,
		"defecto" => KDefault,
		"default" => KDefault,
		"otro" => KDefault,
		"importar" => KImport,
		"import" => KImport,
		"publico" => KPublic,
		"public" => KPublic,
		"privado" => KPrivate,
		"private" => KPrivate,
		"estatico" => KStatic,
		"static" => KStatic,
		"abstracto" => KAbstract,
		"abstract" => KAbstract,
		"enumeracion" => KEnum,
		"enum" => KEnum,
		"fin" => KEnd,
		"lista" => KList,
		"diccionario" => KDict,
		"repetir" => KRepeat,
		"elegir" => KElect,
		"incluir" => KInclude
	];

	public function new(input:String) {
		this.input = input.replace('\r\n', '\n').replace('\r', '\n');
	}

	public function tokenize():Array<TokenPos> {
		var tokens:Array<TokenPos> = [];

		while (!isEOF() || pendingTokens.length > 0) {
			if (pendingTokens.length > 0) {
				for (t in pendingTokens)
					tokens.push(t);
				pendingTokens = [];
				continue;
			}

			skipWhitespaceExceptNewline();

			if (isEOF())
				break;

			var startLine = line;
			var startCol = col;
			var token = nextToken();

			if (pendingTokens.length > 0) {
				var allPending = pendingTokens.copy();
				pendingTokens = [];
				for (t in allPending)
					tokens.push(t);
			} else if (token != null) {
				tokens.push({token: token, line: startLine, col: startCol});
			}
		}

		tokens.push({token: TEOF, line: line, col: col});
		return tokens;
	}

	function nextToken():Token {
		if (isEOF())
			return null;

		var c = peek();

		// Comments
		if (c == '#') {
			skipLineComment();
			return null;
		}
		if (c == '/' && peekNext() == '/') {
			skipLineComment();
			return null;
		}
		if (c == '/' && peekNext() == '*') {
			skipBlockComment();
			return null;
		}

		// Newlines
		if (c == '\n') {
			advance();
			line++;
			col = 1;
			return TNewLine;
		}

		// Strings
		if (c == '"' || c == "'") {
			return readString();
		}
		if (c == '`') {
			readTemplateString();
			return null;
		}

		// Numbers
		if (isDigit(c) || (c == '.' && isDigit(peekNext()))) {
			advance();
			return readNumber(c);
		}

		// Identifiers and keywords
		if (isAlpha(c) || c == '_') {
			return readIdentifier();
		}

		// Operators and delimiters
		return readOperatorOrDelimiter();
	}

	function skipLineComment():Void {
		advance(); advance();
		while (!isEOF() && peek() != '\n')
			advance();
	}

	function skipBlockComment():Void {
		advance(); advance();
		while (!isEOF()) {
			if (peek() == '*' && peekNext() == '/') {
				advance(); advance();
				return;
			}
			if (peek() == '\n') {
				line++;
				col = 0;
			}
			advance();
		}
		throw 'Comentario sin cerrar en linea $line, col $col';
	}

	function readString():Token {
		var quote = advance();
		var value = '';
		var hasInterp = false;

		while (!isEOF() && peek() != quote) {
			if (peek() == '$' && (peekNext() == '{' || isAlpha(peekNext()) || peekNext() == '_')) {
				hasInterp = true;
				break;
			}
			if (peek() == '\\') {
				advance();
				if (isEOF())
					throw 'Cadena sin cerrar en linea $line, col $col';
				var escaped = advance();
				switch (escaped) {
					case 'n': value += '\n';
					case 't': value += '\t';
					case 'r': value += '\r';
					case '\\': value += '\\';
					case '"': value += '"';
					case "'": value += "'";
					default: value += escaped;
				}
			} else {
				if (peek() == '\n') {
					line++;
					col = 0;
				}
				value += advance();
			}
		}

		if (!hasInterp) {
			if (isEOF())
				throw 'Cadena sin cerrar en linea $line, col $col';
			advance();
			return TString(value);
		}

		readStringInterpolation(quote, value);
		return null;
	}

	function readStringInterpolation(quote:String, prefix:String):Void {
		var startLine = line;
		var startCol = col;
		var parts:Array<TokenPos> = [];
		var hasContent = false;

		inline function pushStr(s:String, l:Int, c:Int) {
			if (s.length > 0) {
				if (hasContent)
					parts.push({token: TOperator(OAdd), line: l, col: c});
				parts.push({token: TString(s), line: l, col: c});
				hasContent = true;
			}
		}

		pushStr(prefix, startLine, startCol);

		var literal = new StringBuf();
		var litLine = line;
		var litCol = col;

		while (!isEOF() && peek() != quote) {
			if (peek() == '$' && peekNext() != '{' && (isAlpha(peekNext()) || peekNext() == '_')) {
				pushStr(literal.toString(), litLine, litCol);
				literal = new StringBuf();
				advance();
				var identStart = pos;
				while (!isEOF() && (isAlphaNumeric(peek()) || peek() == '_'))
					advance();
				var identName = input.substring(identStart, pos);
				if (hasContent)
					parts.push({token: TOperator(OAdd), line: line, col: col});
				parts.push({token: TIdentifier(identName), line: line, col: col});
				hasContent = true;
				litLine = line;
				litCol = col;
			} else if (peek() == '$' && peekNext() == '{') {
				pushStr(literal.toString(), litLine, litCol);
				literal = new StringBuf();
				advance(); advance();
				var depth = 1;
				var exprStart = pos;
				while (!isEOF() && depth > 0) {
					if (peek() == '{') depth++;
					else if (peek() == '}') depth--;
					if (peek() == '\n') {
						line++;
						col = 0;
					}
					advance();
				}
				var exprCode = input.substring(exprStart, pos - 1);
				var subTokens = createSubTokenizer(exprCode).tokenize();
				var lastToken = subTokens[subTokens.length - 1];
				if (lastToken != null && lastToken.token == TEOF)
					subTokens.pop();
				for (t in subTokens)
					parts.push({token: t.token, line: startLine, col: startCol});
				litLine = line;
				litCol = col;
			} else {
				if (peek() == '\n') {
					line++;
					col = 0;
				}
				literal.add(advance());
			}
		}

		if (isEOF())
			throw 'Cadena sin cerrar en linea $line, col $col';
		advance();

		parts.push({token: TNewLine, line: line, col: col});
		pendingTokens = parts;
	}

	function readTemplateString():Void {
		advance();
		var startLine = line;
		var startCol = col;
		var parts:Array<TokenPos> = [];
		var hasContent = false;

		inline function pushStr(s:String, l:Int, c:Int) {
			if (s.length > 0) {
				if (hasContent)
					parts.push({token: TOperator(OAdd), line: l, col: c});
				parts.push({token: TString(s), line: l, col: c});
				hasContent = true;
			}
		}

		var literal = new StringBuf();
		var litLine = line;
		var litCol = col;

		while (!isEOF() && peek() != '`') {
			if (peek() == '$' && peekNext() == '{') {
				pushStr(literal.toString(), litLine, litCol);
				literal = new StringBuf();
				advance(); advance();
				var depth = 1;
				var exprStart = pos;
				while (!isEOF() && depth > 0) {
					if (peek() == '{') depth++;
					else if (peek() == '}') depth--;
					if (peek() == '\n') {
						line++;
						col = 0;
					}
					advance();
				}
				var exprCode = input.substring(exprStart, pos - 1);
				var subTokens = createSubTokenizer(exprCode).tokenize();
				var lastToken = subTokens[subTokens.length - 1];
				if (lastToken != null && lastToken.token == TEOF)
					subTokens.pop();
				for (t in subTokens)
					parts.push({token: t.token, line: startLine, col: startCol});
				litLine = line;
				litCol = col;
			} else {
				if (peek() == '\n') {
					line++;
					col = 0;
				}
				literal.add(advance());
			}
		}

		if (isEOF())
			throw 'Template string sin cerrar en linea $line, col $col';
		advance();

		pushStr(literal.toString(), litLine, litCol);
		parts.push({token: TNewLine, line: line, col: col});
		pendingTokens = parts;
	}

	function readNumber(startChar:String):Token {
		var value = startChar;
		var isFloat = startChar == '.';

		while (!isEOF() && (isDigit(peek()) || (peek() == '.' && !isFloat))) {
			if (peek() == '.')
				isFloat = true;
			value += advance();
		}

		if (isFloat)
			return TNumber(Std.parseFloat(value));
		return TNumber(Std.parseInt(value));
	}

	function readIdentifier():Token {
		var start = pos;
		while (!isEOF() && (isAlphaNumeric(peek()) || peek() == '_'))
			advance();
		var ident = input.substring(start, pos);

		if (keywords.exists(ident)) {
			var keyword = keywords.get(ident);
			// Map Latino keywords to proper token types
			switch (keyword) {
				case KTrue: return TBool(true);
				case KFalse: return TBool(false);
				case KNull: return TNull;
				default: return TKeyword(keyword);
			}
		}

		return TIdentifier(ident);
	}

	function readOperatorOrDelimiter():Token {
		var c = peek();
		var next = peekNext();

		switch (c) {
			case '(': advance(); return TLeftParen;
			case ')': advance(); return TRightParen;
			case '{': advance(); return TLeftBrace;
			case '}': advance(); return TRightBrace;
			case '[': advance(); return TLeftBracket;
			case ']': advance(); return TRightBracket;
			case ',': advance(); return TComma;
			case ';': advance(); return TSemicolon;
			case ':': advance(); return TColon;
			case '?': advance(); return TQuestion;
			case '.':
				if (next == '.') { advance(); advance(); return TOperator(OConcat); }
				advance(); return TDot;

			case '=':
				if (next == '=') { advance(); advance(); return TOperator(OEqual); }
				if (next == '>') { advance(); advance(); return TArrow; }
				advance(); return TOperator(OAssign);

			case '+':
				if (next == '+') { advance(); advance(); return TOperator(OIncrement); }
				if (next == '=') { advance(); advance(); return TOperator(OAddAssign); }
				advance(); return TOperator(OAdd);

			case '-':
				if (next == '>') { advance(); advance(); return TArrow; }
				if (next == '-') { advance(); advance(); return TOperator(ODecrement); }
				if (next == '=') { advance(); advance(); return TOperator(OSubAssign); }
				advance(); return TOperator(OSub);

			case '*':
				if (next == '=') { advance(); advance(); return TOperator(OMulAssign); }
				advance(); return TOperator(OMul);

			case '/':
				if (next == '=') { advance(); advance(); return TOperator(ODivAssign); }
				advance(); return TOperator(ODiv);

			case '%':
				if (next == '=') { advance(); advance(); return TOperator(OModAssign); }
				advance(); return TOperator(OMod);

			case '<':
				if (next == '=') { advance(); advance(); return TOperator(OLessEq); }
				if (next == '<') { advance(); advance(); return TOperator(OShiftLeft); }
				advance(); return TOperator(OLess);

			case '>':
				if (next == '=') { advance(); advance(); return TOperator(OGreaterEq); }
				if (next == '>') { advance(); advance(); return TOperator(OShiftRight); }
				advance(); return TOperator(OGreater);

			case '!':
				if (next == '=') { advance(); advance(); return TOperator(ONotEqual); }
				advance(); return TOperator(ONot);

			case '~':
				if (next == '=') { advance(); advance(); return TOperator(ORegex); }
				advance(); return TOperator(OBitNot);

			case '&':
				if (next == '&') { advance(); advance(); return TOperator(OAnd); }
				advance(); return TOperator(OBitAnd);

			case '|':
				if (next == '|') { advance(); advance(); return TOperator(OOr); }
				advance(); return TOperator(OBitOr);

			case '^': advance(); return TOperator(OBitXor);

			default:
				advance();
				throw 'Caracter desconocido: $c en linea $line, col $col';
		}
	}

	inline function peek():String {
		return pos < input.length ? input.charAt(pos) : '';
	}

	inline function peekNext():String {
		return pos + 1 < input.length ? input.charAt(pos + 1) : '';
	}

	inline function advance():String {
		return input.charAt(pos++);
	}

	inline function isEOF():Bool {
		return pos >= input.length;
	}

	inline function isDigit(c:String):Bool {
		return c >= '0' && c <= '9';
	}

	inline function isAlpha(c:String):Bool {
		return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
	}

	inline function isAlphaNumeric(c:String):Bool {
		return isAlpha(c) || isDigit(c);
	}

	function skipWhitespaceExceptNewline():Void {
		while (!isEOF() && peek() == ' ' || peek() == '\t') {
			advance();
			col++;
		}
	}

	function createSubTokenizer(input:String):LatinoTokenizer {
		return new LatinoTokenizer(input);
	}
}
