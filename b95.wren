/*
** B95 - A Lua to Wren compiler in Wren.
**
** For the latest info, see https://github.com/paladin-t/b95/
**
** Copyright (C) 2019 Tony Wang
**
** Permission is hereby granted, free of charge, to any person obtaining a copy of
** this software and associated documentation files (the "Software"), to deal in
** the Software without restriction, including without limitation the rights to
** use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
** the Software, and to permit persons to whom the Software is furnished to do so,
** subject to the following conditions:
**
** The above copyright notice and this permission notice shall be included in all
** copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
** FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
** COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
** IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
** CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
** {========================================================
** Utilities
*/

class Stack is Sequence {
	construct new() {
		_list = [ ]
	}

	count {
		return _list.count
	}
	isEmpty {
		return _list.isEmpty
	}
	clear() {
		_list.clear()
	}

	peek {
		if (_list.isEmpty) {
			Fiber.abort("Peeking from empty stack.")
		}

		return _list[_list.count - 1]
	}
	pop() {
		if (_list.isEmpty) {
			Fiber.abort("Popping from empty stack.")
		}

		var ret = _list[_list.count - 1]
		_list.removeAt(_list.count - 1)

		return ret
	}
	push(val) {
		_list.add(val)

		return this
	}

	// Iterates top-down, but doesn't pop anything.
	iterate(iterator) {
		if (iterator == null) {
			iterator = _list.count
		}
		iterator = iterator - 1
		if (iterator < 0) {
			return null
		}

		return iterator
	}
	iteratorValue(iterator) {
		return _list[iterator]
	}
}

class Format {
	construct new(fmt) {
		_format = fmt
	}
	construct new(fmt, arg0) {
		_format = fmt
		_arg0 = arg0
	}
	construct new(fmt, arg0, arg1) {
		_format = fmt
		_arg0 = arg0
		_arg1 = arg1
	}
	construct new(fmt, arg0, arg1, arg2) {
		_format = fmt
		_arg0 = arg0
		_arg1 = arg1
		_arg2 = arg2
	}

	toString {
		var result = _format
		if (result.contains("{0}")) {
			result = result.replace("{0}", _arg0.toString)
		}
		if (result.contains("{1}")) {
			result = result.replace("{1}", _arg1.toString)
		}
		if (result.contains("{2}")) {
			result = result.replace("{2}", _arg2.toString)
		}

		return result
	}
}

class Location {
	construct new(ln, col) {
		_line = ln
		_column = col
	}

	toString {
		return toString(true)
	}
	toString(includeCol) {
		var result = "[Ln " + (line + 1).toString
		if (includeCol) {
			result = result + ", Col " + (column + 1).toString
		}
		result = result + "]"

		return result
	}

	line { _line } // Starts from 0.
	line = (value) { _line = value }
	column { _column } // Starts from 0.
	column = (value) { _column = value }

	copy {
		return Location.new(line, column)
	}
}

class Except {
	static InvalidProgram { "Invalid program." }
	static InvalidString(what, where) { Format.new("Invalid string: {1}.", what, where).toString }
	static InvalidCharacter(what, where) { Format.new("Invalid character '{0}': {1}.", what).toString }

	static ExpectSomething(what, where) { Format.new("{0} expected: {1}.", what, where).toString }
	static ExpectString(where) { Except.ExpectSomething("String", where) }
	static ExpectIdentifier(where) { Except.ExpectSomething("Identifier", where) }
	static ExpectLParenthesis(where) { Except.ExpectSomething("'('", where) }
	static ExpectRParenthesis(where) { Except.ExpectSomething("')'", where) }
	static ExpectLBracket(where) { Except.ExpectSomething("'['", where) }
	static ExpectRBracket(where) { Except.ExpectSomething("']'", where) }
	static ExpectLBrace(where) { Except.ExpectSomething("'{'", where) }
	static ExpectRBrace(where) { Except.ExpectSomething("'}'", where) }
	static ExpectDo(where) { Except.ExpectSomething("'do'", where) }
	static ExpectThen(where) { Except.ExpectSomething("'then'", where) }
	static ExpectEnd(where) { Except.ExpectSomething("'end'", where) }
	static ExpectAssign(where) { Except.ExpectSomething("'='", where) }
	static ExpectAssignOrIn(where) { Except.ExpectSomething("'=' or 'in'", where) }
	static ExpectObjectTable(where) { Except.ExpectSomething("Object table", where) }

	static SyntaxNotImplemented(what, where) { Format.new("{0} not implemented: {1}.", what, where).toString }
	static SyntaxSomethingNotMatch(what, where) { Format.new("{0} not match: {1}.", what, where).toString }
	static SyntaxSomethingAlreadyDefined(what, where) { Format.new("{0} already defined: {1}.", what, where).toString }
	static SyntaxRParenthesisNotMatch(where) { Except.SyntaxSomethingNotMatch("')'", where) }
	static SyntaxRBracketNotMatch(where) { Except.SyntaxSomethingNotMatch("']'", where) }
	static SyntaxRBraceNotMatch(where) { Except.SyntaxSomethingNotMatch("'}'", where) }
	static SyntaxConditionAndBranchNotMatch(where) { Except.SyntaxSomethingNotMatch("Condition and branch", where) }
	static SyntaxSymbolAlreadyDefined(what, where) { Except.SyntaxSomethingAlreadyDefined(Format.new("Symbol {0}", what).toString, where) }
	static SyntaxInvalidRange(where) { Format.new("Invalid range: {0}.", where).toString }
	static SyntaxBreakOutsideLoop(where) { Format.new("Cannot use 'break' outside of a loop: {0}.", where).toString }
	static SyntaxInvalidClass(where) { Format.new("Invalid class: {0}.", where).toString }
}

/* ========================================================} */

/*
** {========================================================
** Lexer
*/

class TokenTypes {
	static None { 0 }
	static Invalid { 1 << 0 }
	static Space { 1 << 1 }
	static Symbol { TokenTypes.Keyword | TokenTypes.Meta | TokenTypes.Identifier }
		static Keyword { 1 << 2 }
		static Meta { 1 << 3 }
		static Identifier { 1 << 4 }
	static Operator { 1 << 5 }
	static Nil { 1 << 6 }
	static False { 1 << 7 }
	static True { 1 << 8 }
	static Number { 1 << 9 }
	static String { 1 << 10 }
	static Comment { 1 << 11 }
	static Newline { 1 << 12 }
	static EndOfFile { 1 << 13 }

	static toString(y) {
		return {
			TokenTypes.None: "NONE",
			TokenTypes.Invalid: "INVALID",
			TokenTypes.Space: "SPACE",
			TokenTypes.Symbol: "SYMBOL",
				TokenTypes.Keyword: "KEYWORD",
				TokenTypes.Meta: "META",
				TokenTypes.Identifier: "IDENTIFIER",
			TokenTypes.Operator: "OPERATOR",
			TokenTypes.Nil: "NIL",
			TokenTypes.False: "FALSE",
			TokenTypes.True: "TRUE",
			TokenTypes.Number: "NUMBER",
			TokenTypes.String: "STRING",
			TokenTypes.Comment: "COMMENT",
			TokenTypes.Newline: "NEWLINE",
			TokenTypes.EndOfFile: "EOF"
		}[y]
	}

	static match(x, y) {
		return (x & y) != TokenTypes.None
	}
}

class Token {
	static CharSpace { " \t" }
	static CharOperator { "+-*/\%^#&~|<>/=(){}[];:,." }
	static TextSingleQuote { "'" }
	static TextDoubleQuote { "\"" }
	static TextCommentHead { "-" }
	static TextComment { "--" }
	static TextCommentBegin { "--[[" }
	static TextCommentEnd { "--]]" }
	static IsDigital(ch) { "0123456789".contains(ch) }
	static IsExponental(ch) { "0123456789-.eE".contains(ch) }
	static IsHexadecimal(ch) { "0123456789abcdefABCDEFxX-".contains(ch) }
	static IsSymbolic(ch) {
		var zero = 48
		var nine = 57
		var A = 65
		var Z = 90
		var u = 95 // Underscore `_`.
		var a = 97
		var z = 122
		var cp = ch.codePoints[0]
		if (cp == u) {
			return true
		}
		if (cp >= zero && cp <= nine) {
			return true
		}
		if (cp >= A && cp <= Z) {
			return true
		}
		if (cp >= a && cp <= z) {
			return true
		}

		return cp > 255
	}

	static Any { null }
	static Keywords {
		return [
			"and", "break", "do", "else", "elseif", "end",
			"false", "for", "function", "goto", "if", "in",
			"local", "nil", "not", "or", "repeat", "return",
			"then", "true", "until", "while"
		]
	}
	static Metas {
		return [
			"__add", "__sub", "__mul", "__div", "__mod",
			"__pow", "__unm", "__idiv",
			"__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
			"__concat", "__len",
			"__eq", "__lt", "__le",
			"__index", "__newindex", "__call"
		]
	}
	static Operators {
		return [
			"+", "-", "*", "/", "\%", "^", "#",
			"&", "~", "|", "<<", ">>", "//",
			"==", "~=", "<=", ">=", "<", ">", "=",
			"(", ")", "{", "}", "[", "]", "::",
			";", ":", ",", ".", "..", "..."
		]
	}

	static SpacesOfTab { 4 }
	static SpacesOf(ch) {
		if (ch == " ") {
			return 1
		} else if (ch == "\t") {
			return Token.SpacesOfTab
		} else {
			return 0
		}
	}

	static match(tk, data) {
		if (data is String) {
			return tk.data == data
		} else if (data is List) {
			for (d in data) {
				if (tk.data == d) {
					return true
				}
			}

			return false
		} else {
			return false
		}
	}

	construct new(raiser) {
		_raiser = raiser

		type = TokenTypes.Invalid
		text = ""
	}

	toString {
		if (TokenTypes.match(type, TokenTypes.Space)) {
			if (data == 1) {
				return "{ " + "type: " + TokenTypes.toString(type) + ", text: '_' }"
			} else {
				return "{ " + "type: " + TokenTypes.toString(type) + ", text: '_'*" + data.toString + " }"
			}
		} else if (TokenTypes.match(type, TokenTypes.Newline)) {
			return "{ " + "type: " + TokenTypes.toString(type) + ", text: '\\n' }"
		} else if (TokenTypes.match(type, TokenTypes.EndOfFile)) {
			return "{ " + "type: " + TokenTypes.toString(type) + ", text: 'EOF' }"
		}

		return "{ " + "type: " + TokenTypes.toString(type) + ", text: " + text + " }"
	}

	type { _type }
	type = (value) { _type = value }
	begin { _begin }
	begin = (value) { _begin = value }
	end { _end }
	end = (value) { _end = value }
	text { _text }
	text = (value) { _text = value }
	data { _data }
	data = (value) { _data = value }

	add(txt) {
		text = text + txt
	}
	seal() {
		if (TokenTypes.match(type, TokenTypes.Space)) {
			data = data / Token.SpacesOfTab
		} else if (TokenTypes.match(type, TokenTypes.Number)) {
			data = Num.fromString(text)
		} else if (TokenTypes.match(type, TokenTypes.String)) {
			if (text.startsWith(Token.TextSingleQuote)) {
				data = text.skip(1).take(text.count - 2).join("")
				data = data.replace("\\'", "'")
				data = data.replace("\\", "\\\\")
				data = data.replace("\"", "\\\"")
			} else if (text.startsWith(Token.TextDoubleQuote)) {
				data = text.skip(1).take(text.count - 2).join("")
				data = data.replace("\\", "\\\\")
				data = data.replace("\"", "\\\"")
			} else {
				_raiser.call(Except.InvalidString(null, begin).toString)
			}
		} else if (TokenTypes.match(type, TokenTypes.Symbol)) {
			if (Token.Keywords.contains(text)) {
				type = TokenTypes.Keyword
			} else if (Token.Metas.contains(text)) {
				type = TokenTypes.Meta
			} else if (Token.Operators.contains(text)) {
				type = TokenTypes.Operator
			} else {
				type = TokenTypes.Identifier
			}
			data = text
		} else if (TokenTypes.match(type, TokenTypes.Newline)) {
			data = "\n"
		} else {
			data = text
		}
	}
}

class LexStates {
	static Normal { 0 }
	static SingleQuoteString { 1 }
	static DoubleQuoteString { 2 }
	static SinglelineComment { 3 }
	static MultilineComment { 4 }
}

/**
 * @brief Lua lexer that tokenizes Lua source code.
 */
class Lexer {
	/**< Public. */

	construct new(raiser) {
		_raiser = raiser

		_state = LexStates.Normal
		_location = Location.new(0, 0)

		_cursor = 0
		_tokens = null
		_token = null
	}

	load(data) {
		_state = LexStates.Normal
		_location = Location.new(0, 0)

		_tokens = [ ]
		_token = null

		data = preprocess_(data)

		for (i in 0...data.count) {
			var ln = data[i]
			tokenize_(ln)

			_location.line = _location.line + 1
			_location.column = 0
		}
		token_(TokenTypes.EndOfFile)
		add_("\0")
		seal_()
		var tokens = _tokens

		_state = LexStates.Normal
		_location = Location.new(0, 0)

		_tokens = null
		_token = null

		return tokens
	}

	/**< Private. */

	preprocess_(data) {
		return data.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	}
	tokenize_(ln) {
		cursor_ = 0

		var newline = true
		while (cursor_ < ln.count) {
			var ch = ln[cursor_]
			var step = 0
			if (on_(LexStates.Normal)) {
				if (ch == Token.TextCommentHead) {
					var n = forward_(ln, Token.TextCommentBegin, cursor_)
					var m = forward_(ln, Token.TextComment, cursor_)
					if (n != 0) {
						transfer_(LexStates.MultilineComment)
						token_(TokenTypes.Comment)
						add_(Token.TextCommentBegin)

						step = n
					} else if (m != 0) {
						transfer_(LexStates.SinglelineComment)
						token_(TokenTypes.Comment)
						add_(Token.TextComment)

						step = m
					}
				} else if (ch == Token.TextSingleQuote) {
					transfer_(LexStates.SingleQuoteString)
					token_(TokenTypes.String)
					add_(Token.TextSingleQuote)

					step = 1
				} else if (ch == Token.TextDoubleQuote) {
					transfer_(LexStates.DoubleQuoteString)
					token_(TokenTypes.String)
					add_(Token.TextDoubleQuote)

					step = 1
				}
				if (step == 0) {
					var met = null
					if (Token.CharSpace.contains(ch)) {
						if (!is_(TokenTypes.Space)) {
							if (location_.column == 0) {
								token_(TokenTypes.Space)
								add_(ch)
								data_ = Token.SpacesOf(ch)
							} else {
								seal_()
							}
						} else {
							add_(ch)
							data_ = data_ + Token.SpacesOf(ch)
						}
						met = TokenTypes.Space
					} else if (is_(TokenTypes.Symbol) && Token.IsSymbolic(ch)) {
						// Does nothing.
					} else if (!is_(TokenTypes.Number) && Token.IsDigital(ch)) {
						token_(TokenTypes.Number)
						add_(ch)
						met = TokenTypes.Number
					} else if (is_(TokenTypes.Number)) {
						if ((equals_("0") && (ch == "x" || ch == "X")) || (startsWith_("0x") || startsWith_("0X"))) {
							if (Token.IsHexadecimal(ch)) {
								add_(ch)
								met = TokenTypes.Number
							}
						} else if (Token.IsExponental(ch)) {
							if (ch == "-" && !backward_(ln, [ "e", "E" ], cursor_ - 1)) {
								// Does nothing.
							} else if (ch == "." && contains_(".")) {
								// Does nothing.
							} else {
								add_(ch)
								met = TokenTypes.Number
							}
						}
					}
					if (met != null) {
						// Does nothing.
					} else if (Token.CharOperator.contains(ch)) {
						if (!is_(TokenTypes.Operator)) {
							token_(TokenTypes.Operator)
							add_(ch)
						} else {
							if (!Token.Operators.contains(token_.text + ch)) {
								token_(TokenTypes.Operator)
							}
							add_(ch)
						}
						met = TokenTypes.Operator
					} else if (Token.IsSymbolic(ch)) {
						if (!is_(TokenTypes.Symbol) && !Token.IsDigital(ch)) {
							token_(TokenTypes.Symbol)
							add_(ch)
							met = TokenTypes.Symbol
						} else if (is_(TokenTypes.Symbol)) {
							add_(ch)
							met = TokenTypes.Symbol
						} else {
							raise_(Except.InvalidCharacter(ch, location_))
						}
					} else {
						raise_(Except.InvalidCharacter(ch, location_))
					}

					step = 1
				}
			} else if (on_(LexStates.SingleQuoteString)) {
				if (ch == Token.TextSingleQuote) {
					transfer_(LexStates.Normal)
					add_(Token.TextSingleQuote)
					seal_()
				} else {
					add_(ch)
				}

				step = 1
			} else if (on_(LexStates.DoubleQuoteString)) {
				if (ch == Token.TextDoubleQuote) {
					transfer_(LexStates.Normal)
					add_(Token.TextDoubleQuote)
					seal_()
				} else {
					add_(ch)
				}

				step = 1
			} else if (on_(LexStates.SinglelineComment)) {
				add_(ch)

				step = 1
			} else if (on_(LexStates.MultilineComment)) {
				if (ch == Token.TextCommentHead) {
					var n = forward_(ln, Token.TextCommentEnd, cursor_)
					if (n != 0) {
						newline = false
						transfer_(LexStates.Normal)
						add_(Token.TextCommentEnd)
						seal_()

						step = n
					}
				}
				if (step == 0) {
					add_(ch)

					step = 1
				}
			}

			next_(step)
		}
		if (newline) {
			if (on_(LexStates.Normal)) {
				token_(TokenTypes.Newline)
				add_("\n")
			} else if (on_(LexStates.SingleQuoteString) || on_(LexStates.DoubleQuoteString)) {
				add_("\n")
			} else if (on_(LexStates.SinglelineComment)) {
				transfer_(LexStates.Normal)
				seal_()
			}
		}

		cursor_ = 0
	}

	raise_(err) {
		_raiser.call(err)
	}

	/**< FSM operation. */

	on_(s) {
		return _state == s
	}
	transfer_(s) {
		_state = s
	}

	/**< Token operation. */

	token_ {
		return _token
	}
	token_(y) {
		if (_token != null) {
			_location.column = _location.column - 1
			seal_()
			_location.column = _location.column + 1
		}

		_token = Token.new(_raiser)
		_token.type = y
		_token.begin = _location.copy
		_tokens.add(_token)

		return _token
	}
	add_(txt) {
		_token.add(txt)
	}
	seal_() {
		if (_token == null) {
			return
		}
		_token.end = _location.copy
		_token.seal()
		_token = null
	}

	is_(y) {
		return _token != null && TokenTypes.match(_token.type, y)
	}
	data_ {
		return _token.data
	}
	data_ = (data) {
		_token.data = data
	}
	equals_(what) {
		return _token.text == what
	}
	startsWith_(part) {
		return _token.text.startsWith(part)
	}
	contains_(part) {
		return _token.text.contains(part)
	}

	/**< Source code traversing. */

	location_ { _location }

	cursor_ { _cursor }
	cursor_ = (value) { _cursor = value }

	next_(n) {
		_location.column = _location.column + n
		_cursor = _cursor + n
	}

	anyway_(ln, what, offset, fn) {
		if (!(what is List)) {
			return fn.call(ln, what, offset)
		}
		for (i in 0...what.count) {
			if (fn.call(ln, what[i], offset)) {
				return true
			}
		}

		return false
	}
	forward_(ln, what, offset) {
		return anyway_(
			ln, what, offset,
			Fn.new { | ln, what, offset |
				if (offset < 0 || offset + what.count > ln.count) {
					return 0
				}
				for (i in 0...what.count) {
					if (what[i] != ln[offset + i]) {
						return 0
					}
				}

				return what.count
			}
		)
	}
	backward_(ln, what, offset) {
		return anyway_(
			ln, what, offset,
			Fn.new { | ln, what, offset |
				if (offset < 0 || offset + 1 - what.count < 0) {
					return 0
				}
				for (i in 0...what.count) {
					if (what[i] != ln[offset + 1 - what.count + i]) {
						return 0
					}
				}

				return what.count
			}
		)
	}
}

/* ========================================================} */

/*
** {========================================================
** Parser
*/

// Syntax nodes that construct into AST.
class Node {
	construct new() {
		_type = null
		_tokens = [ ]

		_head = [ ]
		_body = [ ]
	}

	toString {
		return toString(0)
	}
	toString(indent) {
		var result = space(indent) + tag + "[" + tokens.count.toString + "]"
		result = result + " "
		result = result + "{"
		result = result + newline
		if (!head.isEmpty) {
			result = result + space(indent + 1) + "("
			result = result + newline
			for (n in head) {
				result = result + n.toString(indent + 2)
			}
			result = result + space(indent + 1) + ")"
			result = result + newline
		}
		for (n in body) {
			result = result + n.toString(indent + 1)
		}
		result = result + space(indent) + "}"
		result = result + newline

		return result
	}

	toDebug(gen, indent, debug) {
		if (!debug) {
			return ""
		}
		if (tokens.isEmpty) {
			return ""
		}

		gen.use("debug") // for `LDebug`.
		var result = ""
		result = result + space(indent)
		result = result + "ldebug.setLastLocation(" + tokens[0].begin.line.toString + ", " + tokens[0].begin.column.toString + ")"
		result = result + " // " + tokens[0].begin.toString
		result = result + newline

		return result
	}
	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = toDebug(gen, indent, debug)
		if (!body.isEmpty) {
			for (n in body) {
				result = result + n.toCode(gen, indent, debug)
			}
		}

		gen.context.pop()

		return result
	}

	newline {
		return "\r\n"
	}
	space(indent) {
		return indent <= 0 ? "" : List.filled(indent, "  ").join("") // Indent with space.
	}

	tag { "NODE" }
	type { _type }
	type = (value) { _type = value }
	tokens { _tokens }
	isLoop { false }

	head { _head }
	body { _body }

	any {
		if (!tokens.isEmpty) {
			return this
		}

		for (n in body) {
			var r = n.any
			if (r != null) {
				return r
			}
		}

		return null
	}

	declare(gen, param, debug) {
		declare(gen, param, debug, false)
	}
	declare(gen, param, debug, global) {
		if (!(param is ParameterNode)) {
			return // Ignores.
		}

		var sym = param.toCode(gen, 0, debug)
		var val = param.tokens[0]
		gen.setSymbol(sym, Symbol.new(SymbolTypes.Variable, val))

		if (global) {
			if (!gen.containsGlobal(sym)) {
				gen.addGlobal(sym)
			}
		}
	}

	maybe(map, key, default) {
		return map.containsKey(key) ? map[key] : default
	}
	must(map, key) {
		if (!map.containsKey(key)) {
			Fiber.abort(Format.new("Cannot find '{0}' in {1}.", key, map).toString)
		}

		return map[key]
	}
}

class ProgramNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		indent = indent - 1
		var result = space(indent)
		gen.scopes.push(Scope.new())
		for (n in body) {
			result = result + n.toCode(gen, indent + 1, debug)
		}
		gen.scopes.pop()

		gen.context.pop()

		return result
	}

	tag { "PROGRAM" }
}

class RequireNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = toDebug(gen, indent, debug)
		var path = tokens[tokens.count - 1].data
		var klasses = [ ]
		if (!head.isEmpty) {
			for (k in head[0].head) {
				var l = k.toCode(gen, 0, debug)
				var required = gen.require(path, l)
				if (required == null) {
					klasses.add(k)
				} else {
					result = result + required
				}
			}
		}
		if (head.isEmpty) {
			result = space(indent) + "import "
			result = result + "\"" + path + "\""
		} else if (!klasses.isEmpty) {
			result = space(indent) + "import "
			result = result + "\"" + path + "\""
			result = result + " for "
			result = result + klasses.map(Fn.new { | sym | sym.toCode(gen, 0, debug) }).join(", ")
		}
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "REQUIRE" }
}

class TableNode is Node {
	static Array { 0 }
	static Object { 1 }

	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		gen.use("table") // for `LTable`.
		var result = toDebug(gen, indent, debug)
		if (body.isEmpty) {
			result = result + "LTable.new()"
		} else if (type == TableNode.Array) {
			result = result + "LTable.new("
			result = result + newline
			result = result + space(indent)

			result = result + "["
			result = result + newline
			for (i in 0...body.count) {
				var n = body[i]
				result = result + space(indent + 1) + n.toCode(gen, 0, debug)
				if (i < body.count - 1) {
					result = result + ","
					result = result + newline
				}
			}
			result = result + newline
			result = result + space(indent)
			result = result + "]"

			result = result + newline
			result = result + space(indent - 1)
			result = result + ")"
		} else if (type == TableNode.Object) {
			result = result + "LTable.new("
			result = result + newline
			result = result + space(indent)

			result = result + "{"
			result = result + newline
			for (i in 0...head.count) {
				var k = head[i]
				var v = body[i]
				result = result + space(indent + 1) + k.toCode(gen, 0, debug)
				result = result + ": "
				result = result + v.toCode(gen, 0, debug)
				if (i < head.count - 1) {
					result = result + ","
					result = result + newline
				}
			}
			result = result + newline
			result = result + space(indent)
			result = result + "}"

			result = result + newline
			result = result + space(indent - 1)
			result = result + ")"
		}

		gen.context.pop()

		return result
	}

	tag { "TABLE" }
}

class PrototypeNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = toDebug(gen, indent, debug)
		if (body.isEmpty) {
			// Does nothing.
		} else if (type == TableNode.Array) {
			gen.raise(Except.SyntaxInvalidClass(tokens[0].begin))
		} else if (type == TableNode.Object) {
			for (i in 0...head.count) {
				var k = head[i]
				var v = body[i]
				var vany = v.any
				result = result + space(indent)
				if (vany is FunctionNode) {
					if (vany.id == null) {
						var ktk = k.any.tokens[0]
						var tmp = fromMeta(ktk)
						if (ktk.data != tmp) {
							ktk.data = tmp
						}
						To.id.call(vany, ktk)
					}
					result = result + v.toCode(gen, indent, debug)
				} else {
					var sym = k.toCode(gen, 0, debug)

					result = result + sym
					result = result + " "
					result = result + "{"
					result = result + newline
					result = result + space(indent + 1)
					result = result + "if"
					result = result + " ("
					result = result + "_" + sym + " == null"
					result = result + ") "
					result = result + "{"
					result = result + newline
					result = result + space(indent + 2)
					result = result + "_" + sym + " = " + v.toCode(gen, 0, debug)
					result = result + newline
					result = result + space(indent + 1)
					result = result + "}"
					result = result + newline
					result = result + space(indent + 1)
					result = result + "return "
					result = result + "_" + sym
					result = result + newline
					result = result + space(indent)
					result = result + "}"

					result = result + newline
					result = result + space(indent)
					result = result + sym + " = (value)"
					result = result + " "
					result = result + "{"
					result = result + newline
					result = result + space(indent + 1)
					result = result + "_" + sym + " = value"
					result = result + newline
					result = result + space(indent)
					result = result + "}"
				}
				if (i < head.count - 1) {
					result = result + newline
				}
			}
		}

		gen.context.pop()

		return result
	}

	tag { "PROTOTYPE" }

	fromMeta(tk) {
		var str = tk.data
		if (!TokenTypes.match(tk.type, TokenTypes.Meta)) {
			return str
		}
		if (Token.match(tk, "__add")) {
			str = "+"
		} else if (Token.match(tk, "__sub")) {
			str = "-"
		} else if (Token.match(tk, "__mul")) {
			str = "*"
		} else if (Token.match(tk, "__div")) {
			str = "/"
		} else if (Token.match(tk, "__mod")) {
			str = "\%"
		} else if (Token.match(tk, "__pow")) {
			gen.raise(Except.SyntaxNotImplemented("'__pow'", tokens[0].begin))
		} else if (Token.match(tk, "__unm")) {
			gen.raise(Except.SyntaxNotImplemented("'__unm'", tokens[0].begin))
		} else if (Token.match(tk, "__idiv")) {
			gen.raise(Except.SyntaxNotImplemented("'__idiv'", tokens[0].begin))
		} else if (Token.match(tk, "__band")) {
			str = "&"
		} else if (Token.match(tk, "__bor")) {
			str = "|"
		} else if (Token.match(tk, "__bxor")) {
			gen.raise(Except.SyntaxNotImplemented("'__bxor'", tokens[0].begin))
		} else if (Token.match(tk, "__bnot")) {
			gen.raise(Except.SyntaxNotImplemented("'__bnot'", tokens[0].begin))
		} else if (Token.match(tk, "__shl")) {
			gen.raise(Except.SyntaxNotImplemented("'__shl'", tokens[0].begin))
		} else if (Token.match(tk, "__shr")) {
			gen.raise(Except.SyntaxNotImplemented("'__shr'", tokens[0].begin))
		} else if (Token.match(tk, "__concat")) {
			str = "+"
		} else if (Token.match(tk, "__len")) {
			str = "len__"
		} else if (Token.match(tk, "__eq")) {
			gen.raise(Except.SyntaxNotImplemented("'__eq'", tokens[0].begin))
		} else if (Token.match(tk, "__lt")) {
			str = "<"
		} else if (Token.match(tk, "__le")) {
			str = "<="
		} else if (Token.match(tk, "__index")) {
			gen.raise(Except.SyntaxNotImplemented("'__index'", tokens[0].begin))
		} else if (Token.match(tk, "__newindex")) {
			gen.raise(Except.SyntaxNotImplemented("'__newindex'", tokens[0].begin))
		} else if (Token.match(tk, "__call")) {
			gen.raise(Except.SyntaxNotImplemented("'__call'", tokens[0].begin))
		}

		return str
	}
}

// Identifier `class` is extended to support Wren's OOP model.
// It matches a valid Lua syntax which is possible to make a workaround in C-Lua.
class ClassNode is Node {
	construct new() {
		super()

		_id = null
		_base = null
	}

	toCode(gen, indent, debug) {
		var top = gen.context.peek
		if (!(top is ProgramNode)) {
			gen.raise(Except.SyntaxInvalidClass(tokens[0].begin))
		}

		gen.context.push(this)

		if (gen.getSymbol(id.data)) {
			gen.raise(Except.SyntaxSymbolAlreadyDefined(id.data, tokens[0].begin))
		} else {
			gen.setSymbol(id.data, Symbol.new(SymbolTypes.Class, id))
		}

		var result = toDebug(gen, indent, debug)
		result = result + space(indent)
		result = result + "class " + id.data + " is "
		if (base == null) {
			gen.use("table") // for `LTable`.
			result = result + "LTable"
		} else {
			var tmp = null
			var sym = gen.getSymbol(base.data)
			if (sym == null) {
				sym = gen.newSymbol(SymbolTypes.Class)

				tmp = Library.LTable
				var btag = "class LTable"
				var etag = "// `LTable`."
				var begin = tmp.indexOf(btag)
				var end = tmp.indexOf(etag)
				tmp = tmp.take(end - 1).skip(begin).join("")
				tmp = tmp.replace("class LTable", "class " + sym.toString + " is " + base.data)
				tmp = tmp.replace("LTable", sym.toString)
				if (indent > 0) {
					tmp = tmp.split("\r\n").map(Fn.new { | ln | space(indent) + ln }).join("\r\n")
				}
				tmp = tmp + newline
				tmp = tmp + newline
			}

			result = result + sym.toString
			if (tmp != null) {
				result = tmp + result
			}
		}
		result = result + " "
		result = result + "{"
		var bany = body[0].body.isEmpty ? null : body[0].body[0].any
		if (bany == null) {
			result = result + " "
		} else {
			result = result + newline
			gen.scopes.push(Scope.new())
			for (n in body) {
				result = result + n.toCode(gen, indent + 1, debug)
			}
			gen.scopes.pop()
			result = result + newline
			result = result + space(indent)
		}
		result = result + "}"
		result = result + newline
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "CLASS" }

	id { _id } // Class name.
	id = (value) { _id = value }
	base { _base } // Base class, optional.
	base = (value) { _base = value }
}

class FunctionNode is Node {
	construct new() {
		super()

		_id = null
	}

	toCode(gen, indent, debug) {
		var ismethod = false
		var isgetter = false
		var issetter = false
		var isinline = false
		if (gen.context.count >= 4) {
			var tmp = gen.context.take(3).toList
			ismethod = (tmp[0] is ExpressionNode) && (tmp[1] is PrototypeNode) && (tmp[2] is ClassNode)
			isgetter = ismethod && id.data.startsWith("get_")
			issetter = ismethod && id.data.startsWith("set_")
			isinline = (tmp[0] is ExpressionNode) && (tmp[1] is ExpressionsNode) && (tmp[2] is CallNode)
		}

		gen.context.push(this)

		var scope = Scope.new()
		var result = toDebug(gen, indent, debug)
		var params = head[0]
		if (ismethod && (!isgetter && !issetter)) {
			var isctor = id.data == "new"
			var isinstance = !params.head.isEmpty && params.head[0].toCode(gen, 0, debug) == "self"

			if (gen.getSymbol(id.data)) {
				gen.raise(Except.SyntaxSymbolAlreadyDefined(id.data, tokens[0].begin))
			} else {
				gen.setSymbol(id.data, Symbol.new(SymbolTypes.Function, id))
			}

			if (isctor) {
				result = result + "construct "
			} else if (!isinstance) {
				result = result + "static "
			}
			result = result + id.data
			result = result + "("
			if (!params.head.isEmpty) {
				gen.scopes.push(scope)
				var start = isinstance ? 1 : 0
				for (i in start...params.head.count) {
					var p = params.head[i]
					result = result + p.toCode(gen, 0, debug)
					if (i < params.head.count - 1) {
						result = result + ", "
					}
					declare(gen, p, debug)
				}
				gen.scopes.pop()
			}
			result = result + ")"
			result = result + " "
			result = result + "{"
			result = result + newline
			gen.scopes.push(scope)
			for (n in body) {
				result = result + n.toCode(gen, indent + 1, debug)
			}
			gen.scopes.pop()
			result = result + space(indent) + "}"
		} else if (isgetter || issetter) {
			var isinstance = !params.head.isEmpty && params.head[0].toCode(gen, 0, debug) == "self"

			if (gen.getSymbol(id.data)) {
				gen.raise(Except.SyntaxSymbolAlreadyDefined(id.data, tokens[0].begin))
			} else {
				gen.setSymbol(id.data, Symbol.new(SymbolTypes.Function, id))
			}

			if (!isinstance) {
				result = result + "static "
			}
			result = result + id.data.skip(4).join("")
			if (issetter) {
				result = result + " = "
				result = result + "("
			}
			if (!params.head.isEmpty) {
				gen.scopes.push(scope)
				var start = isinstance ? 1 : 0
				for (i in start...params.head.count) {
					var p = params.head[i]
					result = result + p.toCode(gen, 0, debug)
					if (i < params.head.count - 1) {
						result = result + ", "
					}
					declare(gen, p, debug)
				}
				gen.scopes.pop()
			}
			if (issetter) {
				result = result + ")"
			}
			result = result + " "
			result = result + "{"
			result = result + newline
			gen.scopes.push(scope)
			for (n in body) {
				result = result + n.toCode(gen, indent + 1, debug)
			}
			gen.scopes.pop()
			result = result + space(indent) + "}"
		} else {
			result = result + space(indent)
			if (id != null) {
				if (gen.getSymbol(id.data)) {
					gen.raise(Except.SyntaxSymbolAlreadyDefined(id.data, tokens[0].begin))
				} else {
					gen.setSymbol(id.data, Symbol.new(SymbolTypes.Function, id))
				}

				result = result + "var " + id.data + " = null"
				result = result + newline
				result = result + space(indent)
				result = result + id.data + " = "
			}
			result = result + "Fn.new"
			result = result + " "
			result = result + "{"
			if (!params.head.isEmpty) {
				gen.scopes.push(scope)
				result = result + " | "
				result = result + params.toCode(gen, 0, debug)
				for (p in params.head) {
					declare(gen, p, debug)
				}
				result = result + " |"
				gen.scopes.pop()
			}
			result = result + newline
			gen.scopes.push(scope)
			for (n in body) {
				result = result + n.toCode(gen, indent + 1, debug)
			}
			gen.scopes.pop()
			result = result + space(indent) + "}"
			if (!isinline) {
				result = result + newline
			}
		}

		gen.context.pop()

		return result
	}

	tag { "FUNCTION" }

	id { _id } // Function name.
	id = (value) { _id = value }
}

// Parameter node is a single identifier, eg. `a`, `b`, `c`.
class ParameterNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = tokens[0].data.toString

		gen.context.pop()

		return result
	}

	tag { "PARAMETER" }
}

// List of parameters, eg. `a, b, c`.
class ParametersNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = ""
		if (!head.isEmpty) {
			result = result + head.map(Fn.new { | n | n.toCode(gen, 0, debug) }).join(", ")
		}

		gen.context.pop()

		return result
	}

	tag { "PARAMETERS" }
}

// Object field, eg. `obj.foo`, `obj[expr]`.
class FieldNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = ""
		for (n in body) {
			result = result + n.toCode(gen, 0, debug)
		}

		gen.context.pop()

		return result
	}

	tag { "FIELD" }
}

// List of fields.
class FieldsNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = ""
		if (!head.isEmpty) {
			result = result + head.map(Fn.new { | n | n.toCode(gen, 0, debug) }).join(", ")
		}

		gen.context.pop()

		return result
	}

	tag { "FIELDS" }
}

// Expression, eg. `obj.foo["bar"].baz(1, 2)`, `21 * 2`.
class ExpressionNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var lst = [ ]
		for (i in 0...body.count) {
			var n = body[i]
			if (n is CallNode) {
				var matched = matchCall(lst)
				if (matched > 1) { // Merges atoms.
					var atom = AtomNode.new()
					var tk = Token.new(null)
					tk.type = TokenTypes.Identifier
					tk.begin = lst[lst.count - matched].tokens[0].begin
					tk.end = lst[lst.count - 1].tokens[0].end
					for (j in (lst.count - 1)..(lst.count - matched)) {
						tk.text = lst[j].toCode(gen, 0, debug) + tk.text
						atom.body.add(lst[j])
						lst.removeAt(j)
					}
					tk.data = tk.text
					atom.tokens.add(tk)
					lst.add(atom)
				}
			}
			if (!n.tokens.isEmpty) {
				lst.add(n)
			}
		}

		var result = ""
		for (i in 0...lst.count) {
			var n = lst[i]
			var j = 0
			if (n is TableNode) {
				j = indent + 1
			} else if (n is FunctionNode) {
				j = indent
			}
			var c = n.toCode(gen, j, debug)
			var binaries = [
				"+", "-", "*", "/", "\%", "^",
				"&", "~", "|", "<<", ">>", "//",
				"==", "~=", "<=", ">=", "<", ">"
			]
			if (i > 0 && binaries.contains(c)) {
				c = " " + c + " "
			}
			result = result + c
		}

		gen.context.pop()

		return result
	}

	tag { "EXPRESSION" }

	matchCall(lst) {
		var ops = [
			"+", "-", "*", "/", "\%", "^", "#",
			"&", "~", "|", "<<", ">>", "//",
			"==", "~=", "<=", ">=", "<", ">", "=",
			"(", ")", "{", "}", "[", "]", "::",
			";", ":", ",", ".", "..", "..."
		]
		var matchAtom = Fn.new { | n, y, d |
			if (!n is AtomNode) {
				return false
			}
			var tk = n.tokens[0]
			if (!TokenTypes.match(tk.type, y) && (d == null || Token.match(tk, d))) {
				return false
			}

			return true
		}
		if (lst.count >= 3) {
			// Na/op, sym, dot, sym, call.
			var s_1 = lst[lst.count - 1]
			var s_2 = lst[lst.count - 2]
			var s_3 = lst[lst.count - 3]
			var s_4 = lst.count >= 4 ? lst[lst.count - 4] : null
			if (!matchAtom.call(s_1, TokenTypes.Identifier, null)) {
				return 0
			}
			if (!matchAtom.call(s_2, TokenTypes.Operator, [ ".", ":" ])) {
				return 0
			}
			if (!matchAtom.call(s_3, TokenTypes.Identifier, null)) {
				return 0
			}
			if (s_4 == null) {
				return 3
			} else if (matchAtom.call(s_4, TokenTypes.Operator, ops)) {
				return 3
			} else {
				return 0
			}
		} else if (lst.count >= 1) {
			// Na/op, sym, call.
			var s_1 = lst[lst.count - 1]
			var s_2 = lst.count >= 2 ? lst[lst.count - 2] : null
			if (!matchAtom.call(s_1, TokenTypes.Identifier, null)) {
				return 0
			}
			if (s_2 == null) {
				return 1
			} else if (matchAtom.call(s_2, TokenTypes.Operator, ops)) {
				return 1
			} else {
				return 0
			}
		}

		return 0
	}
}

// Expressions that can evaluate out some value(s), eg. `21 * 2`,
// `"uno", "dos", "thres", "hola" + "mundo"`, etc.
class ExpressionsNode is Node {
	construct new(inline) {
		super()

		_inline = inline
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = ""
		if (!body.isEmpty) {
			if (!_inline) {
				result = result + space(indent)
			}
			result = result + body.map(Fn.new { | n | n.toCode(gen, 0, debug) }).join(", ")
			if (!_inline) {
				result = result + newline
			}
		}

		gen.context.pop()

		return result
	}

	tag { "EXPRESSIONS" }
}

// Declaration including `fields = expressions`.
class DeclarationNode is Node {
	construct new() {
		super()

		_scope = null
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = toDebug(gen, indent, debug)
		var params = head[0]
		var exprs = body.isEmpty ? null : body[0]
		if (params.head.count == 1) {
			var sym = params.toCode(gen, 0, debug)
			result = result + space(indent)
			if (isLocal) {
				result = result + "var "
				if (gen.getSymbol(sym) == null) {
					for (p in params.head) {
						declare(gen, p, debug)
					}
				}
				if (exprs.any is FunctionNode) {
					result = result + sym
					result = result + " = "
					result = result + "null"
					result = result + newline
					result = result + space(indent)
				}
			} else {
				if (gen.getSymbol(sym) == null) {
					for (p in params.head) {
						declare(gen, p, debug, true)
					}
				}
			}
			result = result + sym
			result = result + " = "
			if (exprs == null) {
				result = result + "null"
			} else {
				result = result + exprs.toCode(gen, 0, debug)
			}
			result = result + newline
		} else {
			gen.use("tuple") // for `LTuple`.
			var right = "LTuple.new("
			right = right + newline
			right = right + space(indent + 1)
			if (exprs == null) {
				right = right + List.filled(params.head.count, "null").join(", ")
			} else {
				right = right + exprs.toCode(gen, 0, debug)
			}
			right = right + newline
			right = right + space(indent)
			right = right + ")"

			var tmp = gen.newSymbol()
			result = result + space(indent)
			result = result + "var "
			result = result + tmp.toString
			result = result + " = "
			result = result + right
			result = result + newline

			for (i in 0...params.head.count) {
				var p = params.head[i]
				var sym = p.toCode(gen, 0, debug)
				result = result + space(indent)
				if (isLocal) {
					result = result + "var "
					if (gen.getSymbol(sym) == null) {
						declare(gen, p, debug)
					}
				} else {
					if (gen.getSymbol(sym) == null) {
						declare(gen, p, debug, true)
					}
				}
				result = result + sym
				result = result + " = "
				result = result + tmp.toString
				result = result + "["
				result = result + i.toString
				result = result + "]"
				result = result + newline
			}
		}

		gen.context.pop()

		return result
	}

	tag { "DECLARATION" }

	isLocal {
		if (_scope == null) {
			return false
		}
		if (TokenTypes.match(_scope.type, TokenTypes.Keyword) && Token.match(_scope, "local")) {
			return true
		}

		return false
	}

	scope { _scope } // Identifier scope.
	scope = (value) { _scope = value }
}

// Just a call, without previous field, eg. `(a, b, c)`.
class CallNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		var top = gen.context.peek
		gen.context.push(this)

		var result = ""
		var id = getField(top.body)
		if (id == null) {
			result = result + ".call"
		} else {
			id = id.toCode(gen, 0, debug)
			var sym = gen.getSymbol(id)
			if (sym) {
				if (sym.type == SymbolTypes.Function) {
					result = result + ".call"
				}
			}
		}
		result = result + "("
		for (n in body) {
			result = result + n.toCode(gen, 0, debug)
		}
		result = result + ")"

		gen.context.pop()

		return result
	}

	tag { "CALL" }

	getField(lst) {
		var index = -1
		for (i in 0...lst.count) {
			if (this == lst[i]) {
				index = i - 1

				break
			}
		}
		var result = null
		if (index >= 0) {
			var n = lst[index]
			if (n is AtomNode && TokenTypes.match(n.tokens[0].type, TokenTypes.Identifier)) {
				result = n
			}
		}

		return result
	}
}

class IfNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		if (head.count != body.count) {
			gen.raise(Except.SyntaxConditionAndBranchNotMatch(tokens[0].begin))
		}
		var result = toDebug(gen, indent, debug)
		result = result + space(indent)
		for (i in 0...head.count) {
			var c = head[i]
			var n = body[i]
			if (i == 0) {
				result = result + "if"
				result = result + " (" + c.toCode(gen, 0, debug) + ") "
			} else if (c is DefaultNode) {
				result = result + " else "
			} else {
				result = result + " else if"
				result = result + " (" + c.toCode(gen, 0, debug) + ") "
			}

			result = result + "{"
			result = result + newline
			gen.scopes.push(Scope.new())
			result = result + n.toCode(gen, indent + 1, debug)
			gen.scopes.pop()
			result = result + space(indent)
			result = result + "}"
		}
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "IF" }
}

class DoNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = toDebug(gen, indent, debug)
		result = result + space(indent)
		result = result + "while (true) "
		result = result + "{ // `do-end`."
		result = result + newline
		gen.scopes.push(Scope.new())
		for (n in body) {
			result = result + n.toCode(gen, indent + 1, debug)
		}
		gen.scopes.pop()
		result = result + space(indent + 1) + "break // `do-end`."
		result = result + newline
		result = result + space(indent) + "}"
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "DO" }
}

class ForNode is Node {
	static Numeric { 0 }
	static Ranged { 1 }

	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var scope = Scope.new()
		var result = toDebug(gen, indent, debug)
		var inner = null
		var params = head[0]
		var exprs = head[1]
		result = result + space(indent)
		result = result + "for"
		result = result + " ("
		if (type == ForNode.Numeric) {
			gen.scopes.push(scope)
			result = result + params.toCode(gen, 0, debug)
			for (p in params.head) {
				declare(gen, p, debug)
			}
			result = result + " in "
			if (exprs.body.count == 2) {
				result = result + exprs.body[0].toCode(gen, 0, debug)
				result = result + ".."
				result = result + exprs.body[1].toCode(gen, 0, debug)
			} else if (exprs.body.count == 3) {
				gen.use("syntax") // for `LRange`.

				result = result + "LRange.new("
				result = result + exprs.body.map(
					Fn.new { | n |
						return n.toCode(gen, 0, debug)
					}
				).join(", ")
				result = result + ")"
			} else {
				gen.raise(Except.SyntaxInvalidRange(tokens[0].begin))
			}
			gen.scopes.pop()
		} else {
			var tmp = gen.newSymbol()
			result = result + tmp.toString
			result = result + " in "
			result = result + exprs.toCode(gen, 0, debug)

			inner = ""
			for (i in 0...params.head.count) {
				var n = params.head[i]
				inner = inner + space(indent + 1)
				inner = inner + "var "
				inner = inner + n.toCode(gen, 0, debug)
				inner = inner + " = "
				inner = inner + tmp.toString
				inner = inner + "["
				inner = inner + i.toString
				inner = inner + "]"
				inner = inner + newline
			}
		}
		result = result + ") "
		result = result + "{"
		result = result + newline
		if (inner != null) {
			result = result + inner
		}
		gen.scopes.push(scope)
		for (n in body) {
			result = result + n.toCode(gen, indent + 1, debug)
		}
		gen.scopes.pop()
		result = result + space(indent) + "}"
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "FOR" }
	isLoop { true }
}

class WhileNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = toDebug(gen, indent, debug)
		result = result + space(indent)
		result = result + "while"
		result = result + " ("
		for (n in head) {
			result = result + n.toCode(gen, 0, debug)
		}
		result = result + ") "
		result = result + "{"
		result = result + newline
		gen.scopes.push(Scope.new())
		for (n in body) {
			result = result + n.toCode(gen, indent + 1, debug)
		}
		gen.scopes.pop()
		result = result + space(indent) + "}"
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "WHILE" }
	isLoop { true }
}

class RepeatNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = toDebug(gen, indent, debug)
		result = result + space(indent)
		result = result + "while (true) { // `repeat-until`."
		result = result + newline
		gen.scopes.push(Scope.new())
		for (n in body) {
			result = result + n.toCode(gen, indent + 1, debug)
		}
		result = result + newline
		result = result + space(indent + 1) + "if"
		result = result + " ("
		for (n in head) {
			result = result + n.toCode(gen, 0, debug)
		}
		result = result + ") "
		result = result + "{"
		result = result + newline
		result = result + space(indent + 2) + "break // `repeat-until`."
		result = result + newline
		result = result + space(indent + 1) + "}"
		result = result + newline
		gen.scopes.pop()
		result = result + space(indent) + "}"
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "REPEAT" }
	isLoop { true }
}

class BreakNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		var islooping = false
		for (c in gen.context) {
			if (c.isLoop) {
				islooping = true

				break
			}
		}
		if (!islooping) {
			gen.raise(Except.SyntaxBreakOutsideLoop(tokens[0].begin))

			return
		}

		gen.context.push(this)

		var result = ""
		result = result + space(indent)
		result = result + "break"
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "BREAK" }
}

class ReturnNode is Node {
	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		gen.context.push(this)

		var result = ""
		if (debug) {
			result = toDebug(gen, 0, debug)
		}
		result = result + space(indent)
		result = result + "return"
		if (!body.isEmpty) {
			var istuple = body[0].body.count > 1
			result = result + " "
			if (istuple) {
				gen.use("tuple") // for `LTuple`.
				result = result + "LTuple.new("
			}
			for (n in body) {
				result = result + n.toCode(gen, indent + 1, debug)
			}
			if (istuple) {
				result = result + ")"
			}
		}
		result = result + newline

		gen.context.pop()

		return result
	}

	tag { "RETURN" }
}

class AtomNode is Node {
	static Single { 0 }
	static Multiple { 1 }

	construct new() {
		super()
	}

	toCode(gen, indent, debug) {
		var result = ""
		for (tk in tokens) {
			var str = tk.data.toString
			if (TokenTypes.match(tk.type, TokenTypes.String)) {
				str = "\"" + str + "\""
			} else if (TokenTypes.match(tk.type, TokenTypes.Operator)) {
				if (Token.match(tk, ":")) {
					str = "."
				} else if (Token.match(tk, "..")) {
					str = "+"
				} else if (Token.match(tk, "~=")) {
					str = "!="
				} else if (Token.match(tk, "#")) {
					gen.raise(Except.SyntaxNotImplemented("'#'", tokens[0].begin))
				} else if (Token.match(tk, "~")) {
					gen.raise(Except.SyntaxNotImplemented("'~'", tokens[0].begin))
				} else if (Token.match(tk, "^")) {
					gen.raise(Except.SyntaxNotImplemented("'^'", tokens[0].begin))
				}
			} else if (TokenTypes.match(tk.type, TokenTypes.Meta)) {
				str = str.skip(2).join("") + "__" // Transforms meta signature `__*` to `*__`.
			} else if (TokenTypes.match(tk.type, TokenTypes.Keyword)) {
				if (Token.match(tk, "nil")) {
					str = "null"
				} else if (Token.match(tk, "and")) {
					str = "&&"
				} else if (Token.match(tk, "or")) {
					str = "||"
				} else if (Token.match(tk, "not")) {
					str = "!"
				}
			} else if (TokenTypes.match(tk.type, TokenTypes.Identifier)) {
				if (Token.match(tk, "self")) {
					str = "this"
				}
			}
			result = result + str
		}

		if (!tokens.isEmpty && TokenTypes.match(tokens[0].type, TokenTypes.Identifier)) {
			var entry = result.split(".")
			if (entry.count == 1) {
				entry = gen.function(null, entry[0])
			} else {
				entry = gen.function(entry[0], entry[1])
			}
			if (entry) { // Uses registered function.
				var lib = maybe(entry, "lib", null)
				var func = must(entry, "function")
				if (lib != null) {
					gen.use(lib)
				}
				result = func
			}
		}

		return result
	}

	tag { "ATOM" }
	type { tokens.count <= 1 ? AtomNode.Single : AtomNode.Multiple }
	type = (value) { Fiber.abort("Not supported.") }
}

class DefaultNode is Node {
	construct new() {
		super()
	}

	tag { "DEFAULT" }
}

class From {
	static head {
		if (__head == null) {
			__head = Fn.new { | left | left.head }
		}

		return __head
	}
	static body {
		if (__body == null) {
			__body = Fn.new { | left | left.body }
		}

		return __body
	}
}

class To {
	static nowhere {
		if (__nowhere == null) {
			__nowhere = Fn.new { | left, right | }
		}

		return __nowhere
	}

	static type {
		if (__type == null) {
			__type = Fn.new { | left, right | left.type = right }
		}

		return __type
	}
	static id {
		if (__id == null) {
			__id = Fn.new { | left, right | left.id = right }
		}

		return __id
	}
	static base {
		if (__base == null) {
			__base = Fn.new { | left, right | left.base = right }
		}

		return __base
	}
	static scope {
		if (__scope == null) {
			__scope = Fn.new { | left, right | left.scope = right }
		}

		return __scope
	}

	static head {
		if (__head == null) {
			__head = Fn.new { | left, right | add_(left.head, right) }
		}

		return __head
	}
	static body {
		if (__body == null) {
			__body = Fn.new { | left, right | add_(left.body, right) }
		}

		return __body
	}

	static condition { head }
	static branch { body }

	static add_(dst, obj) {
		if (obj is List) {
			for (o in obj) {
				dst.add(o)
			}
		} else {
			dst.add(obj)
		}
	}
}

/**
 * @brief Lua parser that consumes tokens and produces AST.
 */
class Parser {
	/**< Public. */

	construct new(raiser) {
		_raiser = raiser

		_cursor = 0
		_tokens = null
		_stack = Stack.new()
	}

	load(data) {
		_stack.clear()
		_tokens = preprocess_(data)

		parse_()
		if (_stack.count != 1) {
			raise(Except.InvalidProgram)
		}
		var ast = _stack.peek

		_tokens = null
		_stack.clear()

		return ast
	}

	/**< Private. */

	preprocess_(data) {
		var endy = TokenTypes.Space | TokenTypes.Comment

		return data.where(Fn.new { | tk | !TokenTypes.match(tk.type, endy) }).toList
	}
	parse_() {
		cursor_ = 0
		push_(ProgramNode.new(), To.body)

		newline_()
		while (cursor_ < tokens_.count) {
			statement_()
			newline_()
		}

		cursor_ = 0
	}

	raise_(err) {
		_raiser.call(err)
	}

	/**< Grammar. */

	statement_() {
		if (forward_(TokenTypes.EndOfFile)) {
			next_()

			return
		}
		if (inline_(TokenTypes.Identifier, "require")) {
			require_()
		} else if (inline_(TokenTypes.Identifier, "class")) {
			class_()
		} else if (forward_(TokenTypes.Keyword, "function")) {
			function_()
		} else if (forward_(TokenTypes.Keyword, "if")) {
			if_()
		} else if (forward_(TokenTypes.Keyword, "goto")) {
			goto_()
		} else if (forward_(TokenTypes.Keyword, "do")) {
			do_()
		} else if (forward_(TokenTypes.Keyword, "for")) {
			for_()
		} else if (forward_(TokenTypes.Keyword, "while")) {
			while_()
		} else if (forward_(TokenTypes.Keyword, "repeat")) {
			repeat_()
		} else if (forward_(TokenTypes.Keyword, "break")) {
			break_()
		} else if (forward_(TokenTypes.Keyword, "return")) {
			return_()
		} else if (forward_(TokenTypes.Keyword, "local")) {
			declaration_()
		} else if (inline_(TokenTypes.Operator, "=")) {
			declaration_()
		} else {
			expressions_(false)
		}
	}
	require_() {
		push_(RequireNode.new(), To.body)

		var id = forward_(TokenTypes.Identifier)
		if (id && id.data != "require") {
			parameters_()

			consume_(TokenTypes.Operator, "=", Except.ExpectAssign(token_.begin))
			newline_()
		}

		match_(TokenTypes.Identifier, "require")
		newline_()

		consume_(TokenTypes.String, Except.ExpectString(token_.begin))
		newline_()

		pop_()
	}
	table_() {
		var y = peek_ is ClassNode ? PrototypeNode : TableNode
		var result = push_(y.new(), To.body)

		var tksep = null
		var tkeof = null
		var forwardSeparator = Fn.new { tksep = forward_(TokenTypes.Operator, "}") }
		var forwardEof = Fn.new { tkeof = forward_(TokenTypes.EndOfFile) }

		consume_(TokenTypes.Operator, "{", Except.ExpectLBrace(token_.begin))
		newline_()

		expression_()

		assign_(TableNode.Object, To.type)

		if (forward_(TokenTypes.Operator, ",")) {
			assign_(TableNode.Array, To.type)

			match_(TokenTypes.Operator, ",")
			newline_()

			forwardSeparator.call()
			forwardEof.call()
			while (!tksep && !tkeof) {
				expression_()

				if (forward_(TokenTypes.Operator, ",")) {
					match_(TokenTypes.Operator, ",")
					newline_()
				} else {
					break
				}

				forwardSeparator.call()
				forwardEof.call()
			}
		} else if (forward_(TokenTypes.Operator, "=")) {
			while (true) {
				assign_(
					Fn.new { | left |
						var result = left.body[left.body.count - 1]
						left.body.removeAt(left.body.count - 1)

						return result
					},
					To.head
				)

				consume_(TokenTypes.Operator, "=", Except.ExpectAssign(token_.begin))
				newline_()

				expression_()

				if (forward_(TokenTypes.Operator, ",")) {
					match_(TokenTypes.Operator, ",")
					newline_()

					expression_()
				} else {
					break
				}

				forwardSeparator.call()
				forwardEof.call()
				if (tksep || tkeof) {
					break
				}
			}
		}

		consume_(TokenTypes.Operator, "}", Except.ExpectRBrace(token_.begin))
		newline_()

		pop_()

		return result
	}
	class_() {
		push_(ClassNode.new(), To.body)

		var id = match_(TokenTypes.Identifier)
		if (id) {
			newline_()
			assign_(id, To.id)
		}

		consume_(TokenTypes.Operator, "=", Except.ExpectAssign(token_.begin))
		newline_()

		match_(TokenTypes.Identifier, "class")
		newline_()

		consume_(TokenTypes.Operator, "(", Except.ExpectLParenthesis(token_.begin))
		newline_()

		var tbl = table_()
		if (tbl == null || tbl.type != TableNode.Object) {
			raise_(Except.ExpectObjectTable(token_.begin))
		}

		if (forward_(TokenTypes.Operator, ",")) {
			match_(TokenTypes.Operator, ",")
			newline_()

			var base = match_(TokenTypes.Identifier)
			if (base) {
				newline_()
				assign_(base, To.base)
			}
		}

		consume_(TokenTypes.Operator, ")", Except.ExpectRParenthesis(token_.begin))
		newline_()

		pop_()
	}
	function_() {
		push_(FunctionNode.new(), To.body)

		match_(TokenTypes.Keyword, "function")
		newline_()

		var id = match_(TokenTypes.Identifier) // TODO
		if (id) {
			newline_()
			assign_(id, To.id)
		}

		consume_(TokenTypes.Operator, "(", Except.ExpectLParenthesis(token_.begin))
		newline_()

		parameters_()

		consume_(TokenTypes.Operator, ")", Except.ExpectRParenthesis(token_.begin))
		newline_()

		while (!forward_(TokenTypes.Keyword, "end") && !forward_(TokenTypes.EndOfFile)) {
			statement_()
			newline_()
		}
		match_(TokenTypes.Keyword, "end")
		newline_()

		pop_()
	}
	parameter_() {
		push_(ParameterNode.new(), To.head)

		consume_(TokenTypes.Identifier, Token.Any, Except.ExpectIdentifier(token_.begin))
		newline_()

		pop_()
	}
	parameters_() {
		push_(ParametersNode.new(), To.head)

		while (forward_(TokenTypes.Identifier) && !forward_(TokenTypes.EndOfFile)) {
			parameter_()

			if (forward_(TokenTypes.Operator, ",")) {
				match_(TokenTypes.Operator, ",")
				newline_()
			} else {
				break
			}
		}

		pop_()
	}
	field_() {
		push_(FieldNode.new(), To.head)

		while (forward_(TokenTypes.Identifier) && !forward_(TokenTypes.EndOfFile)) {
			atom_(TokenTypes.Identifier)
			if (forward_(TokenTypes.Operator, [ ".", ":" ])) {
				atom_(TokenTypes.Operator)
			} else if (forward_(TokenTypes.Operator, "=")) {
				break
			} else {
				expression_()
			}
		}
		newline_()

		pop_()
	}
	fields_() {
		push_(FieldsNode.new(), To.head)

		while (forward_(TokenTypes.Identifier) && !forward_(TokenTypes.EndOfFile)) {
			match_(TokenTypes.Identifier)
			if (forward_(TokenTypes.Operator, [ ",", "=" ])) {
				prev_()
				parameter_()
			} else {
				prev_()
				field_()
			}

			if (forward_(TokenTypes.Operator, ",")) {
				match_(TokenTypes.Operator, ",")
				newline_()
			} else {
				break
			}
		}

		pop_()
	}
	expression_() {
		var y = TokenTypes.Meta | TokenTypes.Identifier | TokenTypes.Operator | TokenTypes.Nil | TokenTypes.False | TokenTypes.True | TokenTypes.Number | TokenTypes.String | TokenTypes.Newline

		push_(ExpressionNode.new(), To.body)

		var isCalc = Fn.new { | tk |
			return tk != null && TokenTypes.match(tk.type, TokenTypes.Operator) && Token.match(
				tk,
				[
					"+", "-", "*", "/", "\%", "^", "#",
					"&", "~", "|", "<<", ">>", "//",
					"==", "~=", "<=", ">=", "<", ">", "=",
					"("
				]
			)
		}

		var parenthesisCount = 0
		var bracketCount = 0
		var tkprev = null
		var tkkey = null
		var tkfun = null
		var tkconst = null
		var tklbrace = null
		var tkrbrace = null
		var tksep = null
		var tkeof = null
		var forwardKeyword = Fn.new { tkkey = forward_(TokenTypes.Keyword) }
		var forwardFunction = Fn.new { tkfun = forward_(TokenTypes.Keyword, "function") }
		var forwardConst = Fn.new { tkconst = forward_(TokenTypes.Keyword, [ "nil", "false", "true", "and", "or", "not" ]) }
		var forwardLBrace = Fn.new { tklbrace = forward_(TokenTypes.Operator, "{") }
		var forwardRBrace = Fn.new { tkrbrace = forward_(TokenTypes.Operator, "}") }
		var forwardSeparator = Fn.new { tksep = forward_(TokenTypes.Operator, [ "=", ",", ";" ]) }
		var forwardEof = Fn.new { tkeof = forward_(TokenTypes.EndOfFile) }

		forwardKeyword.call()
		forwardFunction.call()
		forwardConst.call()
		forwardLBrace.call()
		forwardRBrace.call()
		forwardSeparator.call()
		forwardEof.call()
		while ((!tkkey || tkfun || tkconst) && !tksep && !tkeof) {
			var tklparenthesis = forward_(TokenTypes.Operator, "(")
			var tkrparenthesis = forward_(TokenTypes.Operator, ")")
			var tklbracket = forward_(TokenTypes.Operator, "[")
			var tkrbracket = forward_(TokenTypes.Operator, "]")

			var linked = false
			if (tklparenthesis) {
				if (tkprev == null || isCalc.call(tkprev)) {
					parenthesisCount = parenthesisCount + 1
				} else {
					call_()

					tkprev = null

					linked = true
				}
			} else if (tkrparenthesis) {
				parenthesisCount = parenthesisCount - 1
				if (parenthesisCount < 0) {
					break
				}
			} else if (tklbracket) {
				bracketCount = bracketCount + 1
			} else if (tkrbracket) {
				bracketCount = bracketCount - 1
				if (bracketCount < 0) {
					raise_(Except.SyntaxRBracketNotMatch(token_.begin))
				}
			} else if (tklbrace) {
				table_()

				break
			} else if (tkrbrace) {
				break
			} else if (tkfun) {
				function_()

				break
			} else if (tkconst) {
				tkprev = atom_(TokenTypes.Keyword)

				linked = true
			}

			if (!linked) {
				var tkprev2 = tkprev
				tkprev = atom_(y)
				if (TokenTypes.match(tkprev.type, TokenTypes.Newline)) {
					var tknext = forward_(y)
					if (!isCalc.call(tkprev2) && !isCalc.call(tknext)) {
						break
					}
				}
			}

			forwardKeyword.call()
			forwardFunction.call()
			forwardConst.call()
			forwardLBrace.call()
			forwardRBrace.call()
			forwardSeparator.call()
			forwardEof.call()
		}

		if (parenthesisCount > 0) {
			raise_(Except.ExpectRParenthesis(token_.begin))
		} else if (bracketCount > 0) {
			raise_(Except.ExpectRBracket(token_.begin))
		}
		// TODO

		pop_()
	}
	expressions_(inline) {
		push_(ExpressionsNode.new(inline), To.body)

		var tkkey = null
		var tkfun = null
		var tkconst = null
		var tksep = null
		var tkeof = null
		var forwardKeyword = Fn.new { tkkey = forward_(TokenTypes.Keyword) }
		var forwardFunction = Fn.new { tkfun = forward_(TokenTypes.Keyword, "function") }
		var forwardConst = Fn.new { tkconst = forward_(TokenTypes.Keyword, [ "nil", "false", "true", "and", "or", "not" ]) }
		var forwardSeparator = Fn.new { tksep = forward_(TokenTypes.Operator, ";") }
		var forwardEof = Fn.new { tksep = forward_(TokenTypes.EndOfFile) }

		forwardKeyword.call()
		forwardFunction.call()
		forwardConst.call()
		forwardSeparator.call()
		forwardEof.call()
		while ((!tkkey || tkfun || tkconst) && !tksep && !tkeof) {
			expression_()

			if (forward_(TokenTypes.Operator, ",")) {
				match_(TokenTypes.Operator, ",")
				newline_()
			} else {
				break
			}

			forwardKeyword.call()
			forwardFunction.call()
			forwardConst.call()
			forwardSeparator.call()
			forwardEof.call()
		}

		newline_()

		pop_()
	}
	declaration_() {
		push_(DeclarationNode.new(), To.body)

		var scope = forward_(TokenTypes.Keyword, "local")
		if (scope) {
			match_(TokenTypes.Keyword, "local")
			newline_()
			assign_(scope, To.scope)
		}

		fields_()

		if (forward_(TokenTypes.Operator, "=")) {
			match_(TokenTypes.Operator, "=")
			newline_()

			expressions_(true)
		}

		pop_()
	}
	call_() {
		push_(CallNode.new(), To.body)

		consume_(TokenTypes.Operator, "(", Except.ExpectLParenthesis(token_.begin))
		newline_()

		expressions_(true)

		consume_(TokenTypes.Operator, ")", Except.ExpectRParenthesis(token_.begin))

		pop_()
	}
	if_() {
		push_(IfNode.new(), To.body)

		match_(TokenTypes.Keyword, "if")
		newline_()

		push_(Node.new(), To.nowhere)
		expression_()
		bubble_(From.body, To.condition)

		consume_(TokenTypes.Keyword, "then", Except.ExpectThen(token_.begin))
		newline_()

		var tkelseif = null
		var tkelse = null
		var tkend = null
		var tkeof = null
		var forwardElseif = Fn.new {
			var tmp = forward_(TokenTypes.Keyword, "elseif")
			if (tmp && tkelse) {
				raise_(Except.ExpectEnd(token_.begin))
			} else {
				tkelseif = tmp
			}
		}
		var forwardElse = Fn.new {
			var tmp = forward_(TokenTypes.Keyword, "else")
			if (tmp && tkelse) {
				raise_(Except.ExpectEnd(token_.begin))
			} else {
				tkelse = tmp
			}
		}
		var forwardEnd = Fn.new { tkend = forward_(TokenTypes.Keyword, "end") }
		var forwardEof = Fn.new { tkeof = forward_(TokenTypes.EndOfFile) }
		while (!tkend && !tkeof) {
			forwardElseif.call()
			forwardElse.call()
			forwardEnd.call()
			forwardEof.call()

			push_(Node.new(), To.branch)

			while (!tkelseif && !tkelse && !tkend && !tkeof) {
				statement_()
				newline_()

				forwardElseif.call()
				forwardElse.call()
				forwardEnd.call()
				forwardEof.call()
			}

			pop_()

			if (tkelseif) {
				match_(TokenTypes.Keyword, "elseif")
				newline_()

				push_(Node.new(), To.nowhere)
				expression_()
				bubble_(From.body, To.condition)

				consume_(TokenTypes.Keyword, "then", Except.ExpectThen(token_.begin))
				newline_()
			} else if (tkelse) {
				match_(TokenTypes.Keyword, "else")
				newline_()

				push_(DefaultNode.new(), To.condition)
				pop_()
			} else if (tkend) {
				// Does nothing.
			}
		}
		tkend = match_(TokenTypes.Keyword, "end")
		newline_()

		pop_()
	}
	goto_() {
		match_(TokenTypes.Keyword, "goto")
		newline_()

		raise_(Except.SyntaxNotImplemented("'goto'", token_.begin))
	}
	do_() {
		push_(DoNode.new(), To.body)

		match_(TokenTypes.Keyword, "do")
		newline_()

		var tkend = null
		while (!tkend && !forward_(TokenTypes.EndOfFile)) {
			statement_()
			newline_()

			tkend = forward_(TokenTypes.Keyword, "end")
		}
		tkend = match_(TokenTypes.Keyword, "end")
		newline_()

		pop_()
	}
	for_() {
		push_(ForNode.new(), To.body)

		match_(TokenTypes.Keyword, "for")
		newline_()

		parameters_()

		if (forward_(TokenTypes.Operator, "=")) {
			assign_(ForNode.Numeric, To.type)

			match_(TokenTypes.Operator, "=")
			newline_()
		} else if (forward_(TokenTypes.Keyword, "in")) {
			assign_(ForNode.Ranged, To.type)

			match_(TokenTypes.Keyword, "in")
			newline_()
		} else {
			raise_(Except.ExpectAssignOrIn(token_.begin))
		}

		push_(Node.new(), To.nowhere)
		expressions_(true)
		bubble_(From.body, To.head)

		consume_(TokenTypes.Keyword, "do", Except.ExpectDo(token_.begin))
		newline_()

		var tkend = null
		while (!tkend && !forward_(TokenTypes.EndOfFile)) {
			statement_()
			newline_()

			tkend = forward_(TokenTypes.Keyword, "end")
		}
		tkend = match_(TokenTypes.Keyword, "end")
		newline_()

		pop_()
	}
	while_() {
		push_(WhileNode.new(), To.body)

		match_(TokenTypes.Keyword, "while")
		newline_()

		push_(Node.new(), To.nowhere)
		expression_()
		bubble_(From.body, To.condition)

		consume_(TokenTypes.Keyword, "do", Except.ExpectDo(token_.begin))
		newline_()

		var tkend = null
		while (!tkend && !forward_(TokenTypes.EndOfFile)) {
			statement_()
			newline_()

			tkend = forward_(TokenTypes.Keyword, "end")
		}
		tkend = match_(TokenTypes.Keyword, "end")
		newline_()

		pop_()
	}
	repeat_() {
		push_(RepeatNode.new(), To.body)

		match_(TokenTypes.Keyword, "repeat")
		newline_()

		var tkuntil = null
		while (!tkuntil && !forward_(TokenTypes.EndOfFile)) {
			statement_()
			newline_()

			tkuntil = forward_(TokenTypes.Keyword, "until")
		}
		tkuntil = match_(TokenTypes.Keyword, "until")
		newline_()

		push_(Node.new(), To.nowhere)
		expression_()
		bubble_(From.body, To.condition)

		pop_()
	}
	break_() {
		push_(BreakNode.new(), To.body)

		match_(TokenTypes.Keyword, "break")
		newline_()

		pop_()
	}
	return_() {
		push_(ReturnNode.new(), To.body)

		match_(TokenTypes.Keyword, "return")
		newline_()

		if (!forward_(TokenTypes.Newline)) {
			expressions_(true)
		}

		pop_()
	}
	atom_(y) {
		push_(AtomNode.new(), To.body)

		var tk = match_(y)

		pop_()

		return tk
	}

	newline_() {
		if (!match_(TokenTypes.Newline)) {
			return false
		}

		while (match_(TokenTypes.Newline)) {
			// Does nothing.
		}

		return true
	}

	/**< AST operation. */

	peek_ {
		return _stack.peek
	}
	pop_() {
		return _stack.pop()
	}
	// Attaches an AST node to the top node of current stack,
	// then push the new node to the stack.
	push_(ast, func) {
		if (!_stack.isEmpty) {
			var top = _stack.peek
			func.call(top, ast)
		}
		_stack.push(ast)

		return ast
	}
	// Assigns an AST node the the top node of current stack.
	assign_(from, func) {
		var top = _stack.peek
		var ast = from
		if (from is Fn) {
			ast = from.call(top)
		}
		func.call(top, ast)

		return ast
	}
	// Pops the top node of current stack,
	// then assigns the popped content to the new top.
	bubble_(from, func) {
		var ast = _stack.peek
		_stack.pop()
		var top = _stack.peek
		ast = from.call(ast)
		func.call(top, ast)
	}

	/**< Token traversing. */

	tokens_ {
		return _tokens
	}
	token_ {
		if (_cursor >= _tokens.count) {
			return null
		}

		return _tokens[_cursor]
	}
	cursor_ { _cursor }
	cursor_ = (value) { _cursor = value }

	next_() {
		var tk = _tokens[_cursor]
		if (!TokenTypes.match(tk.type, TokenTypes.Newline | TokenTypes.EndOfFile)) {
			var top = _stack.peek
			top.tokens.add(tk)
		}

		_cursor = _cursor + 1
	}
	prev_() {
		_cursor = _cursor - 1
	}

	match_(y) {
		if (token_ == null) {
			return null
		}
		if (!TokenTypes.match(token_.type, y)) {
			return null
		}
		var tk = token_
		next_()

		return tk
	}
	match_(y, data) {
		if (token_ == null) {
			return null
		}
		if (!TokenTypes.match(token_.type, y) || !Token.match(token_, data)) {
			return null
		}
		var tk = token_
		next_()

		return tk
	}
	consume_(y, err) {
		var tk = token_
		next_()
		if (!TokenTypes.match(tk.type, y)) {
			raise_(err)

			return null
		}

		return tk
	}
	consume_(y, data, err) {
		var tk = token_
		next_()
		if (!TokenTypes.match(tk.type, y) || (data != Token.Any && !Token.match(tk, data))) {
			raise_(err)

			return null
		}

		return tk
	}
	forward_(y) {
		if (!TokenTypes.match(token_.type, y)) {
			return null
		}

		return token_
	}
	forward_(y, data) {
		if (!TokenTypes.match(token_.type, y) || !Token.match(token_, data)) {
			return null
		}

		return token_
	}
	inline_(y) {
		var endy = TokenTypes.Newline | TokenTypes.EndOfFile

		var c = _cursor
		while (c < _tokens.count) {
			var tk = _tokens[c]
			if (TokenTypes.match(tk.type, endy)) {
				break
			}
			if (TokenTypes.match(tk.type, y)) {
				return tk
			}

			c = c + 1
		}

		return null
	}
	inline_(y, data) {
		var endy = TokenTypes.Newline | TokenTypes.EndOfFile

		var c = _cursor
		while (c < _tokens.count) {
			var tk = _tokens[c]
			if (TokenTypes.match(tk.type, endy)) {
				break
			}
			if (TokenTypes.match(tk.type, y) && tk.data == data) {
				return tk
			}

			c = c + 1
		}

		return null
	}
}

/* ========================================================} */

/*
** {========================================================
** Generator
*/

class SymbolTypes {
	static None { 0 }
	static Temporary { 1 << 0 }
	static Variable { 1 << 1 }
	static Function { 1 << 2 }
	static Class { 1 << 3 }
}

class Symbol {
	construct new(y, sym) {
		_type = y
		_symbol = sym
	}

	toString {
		if (_symbol is String) {
			return _symbol
		}

		return _symbol.data
	}

	type { _type }
	type = (value) { _type = value }
	symbol { _symbol } // `Token` | `String`.
	symbol = (value) { _symbol = value }

	merge(other) {
		type = type | other.type
	}
}

class Scope {
	construct new() {
		_map = { }
	}

	contains(key) {
		return _map.containsKey(key)
	}
	get(key) {
		return _map[key]
	}
	set(key, value) {
		_map[key] = value
	}
	clear() {
		_map.clear()
	}
}

/**
 * @brief Generated Wren code object.
 */
class Code {
	construct new(li, glb, ln) {
		_libs = li
		_globals = glb
		_lines = ln

		_tokens = null
		_ast = null
	}

	libs { _libs } // Built-in libraries that patch or implement Lua functionalities.
	globals { _globals } // Global variables.
	lines { _lines } // Translated code.

	tokens { _tokens } // Splitted tokens.
	tokens = (value) { _tokens = value }
	ast { _ast } // Parsed AST.
	ast = (value) { _ast = value }

	toString { // Concats to runnable code.
		var result = ""
		if (!_libs.isEmpty) {
			result = result + _libs + "\r\n"
		}
		if (!_globals.isEmpty) {
			result = result + "// Globals begin.\r\n"
			result = result + _globals + "\r\n"
			result = result + "// Globals end.\r\n"
			result = result + "\r\n"
		}
		result = result + _lines

		return result
	}
}

/**
 * @brief Wren code generator that serializes Lua AST to Wren source code.
 *    AST nodes do most of the emitting work, this class helps to organize that
 *    procedure.
 */
class Generator {
	/**< Public. */

	construct new(raiser) {
		_raiser = raiser

		_context = Stack.new()

		_scopes = Stack.new()
		_tmpSeed = 0

		_globals = [ ]

		_using = [ ]

		_onRequire = null
		_onFunction = null
	}

	context { _context }

	scopes { _scopes }

	getSymbol(sym) {
		for (scope in _scopes) {
			if (scope.contains(sym)) {
				return scope.get(sym)
			}
		}

		return null
	}
	setSymbol(sym, value) {
		var scope = _scopes.peek
		if (scope.contains(sym)) {
			var existing = scope.get(sym)
			existing.merge(value)
		} else {
			scope.set(sym, value)
		}

		return value
	}
	newSymbol() {
		return newSymbol(SymbolTypes.Variable)
	}
	newSymbol(y) {
		y = y | SymbolTypes.Temporary
		var prefix = (y & SymbolTypes.Class) == SymbolTypes.None ? "tmp_" : "Class_"
		while (true) {
			var sym = prefix + _tmpSeed.toString
			_tmpSeed = _tmpSeed + 1
			if (getSymbol(sym) == null) {
				return setSymbol(sym, Symbol.new(y, sym))
			}
		}
	}

	containsGlobal(sym) {
		return _globals.contains(sym)
	}
	addGlobal(sym) {
		_globals.add(sym)

		return sym
	}

	use(lib) {
		if (!_using.contains(lib)) {
			_using.add(lib)
		}
	}

	onRequire(cb) {
		_onRequire = cb
	}
	require(path, klass) {
		if (_onRequire != null) {
			return _onRequire.call(path, klass)
		}

		return null
	}

	onFunction(cb) {
		_onFunction = cb
	}
	function(module, func) {
		if (_onFunction != null) {
			var entry = _onFunction.call(module, func)
			if (entry != null) {
				return entry
			}
		}

		return Library.function(module, func)
	}

	serialize(data, debug) {
		_context.clear()

		_scopes.clear()
		_tmpSeed = 0

		_globals.clear()

		_using.clear()

		var lines = emit_(data, debug)

		var libs = [ ]
		if (_using.contains("syntax")) {
			use("tuple") // for `LTuple`.
		}
		if (_using.contains("coroutine")) {
			use("tuple") // for `LTuple`.
		}
		if (_using.contains("string")) {
			use("table") // for `LTable`.
		}
		if (_using.contains("debug")) {
			libs.add(Library.LDebug)
		} else {
			if (!containsGlobal("ldebug")) {
				addGlobal("ldebug")
			}
		}
		if (_using.contains("syntax")) {
			libs.add(Library.LSyntax)
		}
		if (_using.contains("tuple")) {
			libs.add(Library.LTuple)
		}
		if (_using.contains("coroutine")) {
			libs.add(Library.LCoroutine)
		}
		if (_using.contains("string")) {
			libs.add(Library.LString)
		}
		if (_using.contains("table")) {
			libs.add(Library.LTable)
		}
		if (_using.contains("math")) {
			libs.add(Library.LMath)
		}
		libs = libs.join("\r\n")

		var globals = _globals.map(Fn.new { | sym | "var " + sym + " = null" }).join("\r\n")

		var result = Code.new(libs, globals, lines)

		_context.clear()

		_scopes.clear()
		_tmpSeed = 0

		_globals.clear()

		_using.clear()

		return result
	}

	raise(err) {
		_raiser.call(err)
	}

	/**< Private. */

	emit_(data, debug) {
		if (debug) {
			use("debug") // for `LDebug`.
		}

		return data.toCode(this, 0, debug)
	}
}

/* ========================================================} */

/*
** {========================================================
** Libraries
*/

class Library {
	static LDebug {
		if (__debug == null) {
			// Debug patch.
			__debug = "" +
				"// Debug begin.\r\n" +
				"class LDebug {\r\n" +
				"  construct new() {\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  lastLine { _lastLine }\r\n" +
				"  lastColumn { _lastColumn }\r\n" +
				"  setLastLocation(ln, col) {\r\n" +
				"    _lastLine = ln\r\n" +
				"    _lastColumn = col\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"var ldebug = LDebug.new()\r\n" +
				"// Debug end.\r\n" // Debug patch.
		}

		return __debug
	}
	static LTuple {
		if (__tuple == null) {
			// Tuple lib.
			__tuple = "" +
				"// Tuple begin.\r\n" +
				"class LTuple {\r\n" +
				"  construct new() {\r\n" +
				"    ctor([ ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0) {\r\n" +
				"    ctor([ arg0 ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0, arg1) {\r\n" +
				"    ctor([ arg0, arg1 ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0, arg1, arg2) {\r\n" +
				"    ctor([ arg0, arg1, arg2 ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0, arg1, arg2, arg3) {\r\n" +
				"    ctor([ arg0, arg1, arg2, arg3 ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0, arg1, arg2, arg3, arg4) {\r\n" +
				"    ctor([ arg0, arg1, arg2, arg3, arg4 ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0, arg1, arg2, arg3, arg4, arg5) {\r\n" +
				"    ctor([ arg0, arg1, arg2, arg3, arg4, arg5 ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {\r\n" +
				"    ctor([ arg0, arg1, arg2, arg3, arg4, arg5, arg6 ])\r\n" +
				"  }\r\n" +
				"  construct new(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.\r\n" +
				"    ctor([ arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7 ])\r\n" +
				"  }\r\n" +
				"  ctor(argv) {\r\n" +
				"    _args = [ ]\r\n" +
				"    for (arg in argv) {\r\n" +
				"      if (arg is LTuple) {\r\n" +
				"        _args = _args + arg.toList\r\n" +
				"      } else {\r\n" +
				"        _args.add(arg)\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  toString {\r\n" +
				"    return \"< \" + _args.join(\", \") + \" >\"\r\n" +
				"  }\r\n" +
				"  toList {\r\n" +
				"    return _args.toList\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  [index] {\r\n" +
				"    return _args[index]\r\n" +
				"  }\r\n" +
				"  [index] = (value) {\r\n" +
				"    _args[index] = value\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  count {\r\n" +
				"    return _args.count\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  join(sep) {\r\n" +
				"    return _args.join(sep)\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"// Tuple end.\r\n" // Tuple lib.
		}

		return __tuple
	}
	static LSyntax {
		if (__syntax == null) {
			// Syntax lib.
			__syntax = "" +
				"// Syntax begin.\r\n" +
				"class LRange {\r\n" +
				"  construct new(b, e, s) {\r\n" +
				"    _begin = b\r\n" +
				"    _end = e\r\n" +
				"    _step = s\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  iterate(iterator) {\r\n" +
				"    if (iterator == null) {\r\n" +
				"      iterator = _begin\r\n" +
				"\r\n" +
				"      return iterator\r\n" +
				"    }\r\n" +
				"    iterator = iterator + _step\r\n" +
				"    if (_begin < _end) {\r\n" +
				"      if (iterator > _end) {\r\n" +
				"        return null\r\n" +
				"      }\r\n" +
				"    } else if (_begin > _end) {\r\n" +
				"      if (iterator < _end) {\r\n" +
				"        return null\r\n" +
				"      }\r\n" +
				"    } else if (_begin == _end) {\r\n" +
				"      return null\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return iterator\r\n" +
				"  }\r\n" +
				"  iteratorValue(iterator) {\r\n" +
				"    return iterator\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"\r\n" +
				"class LIPairs {\r\n" +
				"  construct new(tbl) {\r\n" +
				"    _table = tbl\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  iterate(iterator) {\r\n" +
				"    if (iterator == null) {\r\n" +
				"      iterator = 0 // 1-based.\r\n" +
				"    }\r\n" +
				"    iterator = iterator + 1\r\n" +
				"    if (iterator > _table.len__) {\r\n" +
				"      return null\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return iterator\r\n" +
				"  }\r\n" +
				"  iteratorValue(iterator) {\r\n" +
				"    return LTuple.new(iterator, _table[iterator])\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"\r\n" +
				"class LPairs {\r\n" +
				"  construct new(tbl) {\r\n" +
				"    _table = tbl\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  iterate(iterator) {\r\n" +
				"    iterator = _table.iterate(iterator)\r\n" +
				"\r\n" +
				"    return iterator\r\n" +
				"  }\r\n" +
				"  iteratorValue(iterator) {\r\n" +
				"    var kv = _table.iteratorValue(iterator)\r\n" +
				"\r\n" +
				"    return LTuple.new(kv.key, kv.value)\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"\r\n" +
				"class Lua {\r\n" +
				"  static len(obj) {\r\n" +
				"    return obj.len__\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  static assert(v) {\r\n" +
				"    Lua.assert(v, \"Assertion.\")\r\n" +
				"  }\r\n" +
				"  static assert(v, message) {\r\n" +
				"    if (!v) {\r\n" +
				"      Fiber.abort(message)\r\n" +
				"    }\r\n" +
				"  }\r\n" +
				"  static collectGarbage() {\r\n" +
				"    return System.gc()\r\n" +
				"  }\r\n" +
				"  static collectGarbage(opt) {\r\n" +
				"    return System.gc()\r\n" +
				"  }\r\n" +
				"  static collectGarbage(opt, arg) {\r\n" +
				"    return System.gc()\r\n" +
				"  }\r\n" +
				"  static doFile(filename) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static error(message) {\r\n" +
				"    Lua.error(message, 0)\r\n" +
				"  }\r\n" +
				"  static error(message, level) {\r\n" +
				"    Fiber.abort(message)\r\n" +
				"  }\r\n" +
				"  static getMetatable(object) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static load(chunk) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static load(chunk, chunkname) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static load(chunk, chunkname, mode) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static load(chunk, chunkname, mode, env) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static loadFile() {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static loadFile(filename) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static loadFile(filename, mode) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static loadFile(filename, mode, env) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static next(table) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static next(table, index) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static pcall(f) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static pcall(f, arg0) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static pcall(f, arg0, arg1) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static pcall(f, arg0, arg1, arg2) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static pcall(f, arg0, arg1, arg2, arg3) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static print_(argv) {\r\n" +
				"    for (i in 0...argv.count) {\r\n" +
				"      if (argv[i] == null) {\r\n" +
				"        argv[i] = \"nil\"\r\n" +
				"      } else if (argv[i] is LTuple) {\r\n" +
				"        argv[i] = argv[i].join(\"\t\")\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    System.print(argv.join(\"\t\"))\r\n" +
				"  }\r\n" +
				"  static print(arg0) {\r\n" +
				"    Lua.print_([ arg0 ])\r\n" +
				"  }\r\n" +
				"  static print(arg0, arg1) {\r\n" +
				"    Lua.print_([ arg0, arg1 ])\r\n" +
				"  }\r\n" +
				"  static print(arg0, arg1, arg2) {\r\n" +
				"    Lua.print_([ arg0, arg1, arg2 ])\r\n" +
				"  }\r\n" +
				"  static print(arg0, arg1, arg2, arg3) {\r\n" +
				"    Lua.print_([ arg0, arg1, arg2, arg3 ])\r\n" +
				"  }\r\n" +
				"  static print(arg0, arg1, arg2, arg3, arg4) {\r\n" +
				"    Lua.print_([ arg0, arg1, arg2, arg3, arg4 ])\r\n" +
				"  }\r\n" +
				"  static print(arg0, arg1, arg2, arg3, arg4, arg5) {\r\n" +
				"    Lua.print_([ arg0, arg1, arg2, arg3, arg4, arg5 ])\r\n" +
				"  }\r\n" +
				"  static print(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {\r\n" +
				"    Lua.print_([ arg0, arg1, arg2, arg3, arg4, arg5, arg6 ])\r\n" +
				"  }\r\n" +
				"  static print(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.\r\n" +
				"    Lua.print_([ arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7 ])\r\n" +
				"  }\r\n" +
				"  static rawEqual(v1, v2) {\r\n" +
				"    return v1 == v2\r\n" +
				"  }\r\n" +
				"  static rawGet(table, index) {\r\n" +
				"    return table[index]\r\n" +
				"  }\r\n" +
				"  static rawLen(v) {\r\n" +
				"    return v.len__\r\n" +
				"  }\r\n" +
				"  static rawSet(table, index, value) {\r\n" +
				"    table[index] = value\r\n" +
				"  }\r\n" +
				"  static select(index, arg0) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static select(index, arg0, arg1) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static select(index, arg0, arg1, arg2) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static select(index, arg0, arg1, arg2, arg3) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static setMetatable(table, metatable) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static toNumber(e) {\r\n" +
				"    return Num.fromString(e)\r\n" +
				"  }\r\n" +
				"  static toNumber(e, base) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static toString(v) {\r\n" +
				"    return v.toString\r\n" +
				"  }\r\n" +
				"  static type(v) {\r\n" +
				"    if (v == null) {\r\n" +
				"      return \"nil\"\r\n" +
				"    }\r\n" +
				"    if (v is Num) {\r\n" +
				"      return \"number\"\r\n" +
				"    }\r\n" +
				"    if (v is String) {\r\n" +
				"      return \"string\"\r\n" +
				"    }\r\n" +
				"    if (v is Bool) {\r\n" +
				"      return \"boolean\"\r\n" +
				"    }\r\n" +
				"    if (v is Fn) {\r\n" +
				"      return \"function\"\r\n" +
				"    }\r\n" +
				"    if (v is Fiber) {\r\n" +
				"      return \"function\"\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return \"table\"\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  static new(y) {\r\n" +
				"    return y.new()\r\n" +
				"  }\r\n" +
				"  static new(y, arg0) {\r\n" +
				"    return y.new(arg0)\r\n" +
				"  }\r\n" +
				"  static new(y, arg0, arg1) {\r\n" +
				"    return y.new(arg0, arg1)\r\n" +
				"  }\r\n" +
				"  static new(y, arg0, arg1, arg2) {\r\n" +
				"    return y.new(arg0, arg1, arg2)\r\n" +
				"  }\r\n" +
				"  static new(y, arg0, arg1, arg2, arg3) {\r\n" +
				"    return y.new(arg0, arg1, arg2, arg3)\r\n" +
				"  }\r\n" +
				"  static new(y, arg0, arg1, arg2, arg3, arg4) {\r\n" +
				"    return y.new(arg0, arg1, arg2, arg3, arg4)\r\n" +
				"  }\r\n" +
				"  static new(y, arg0, arg1, arg2, arg3, arg4, arg5) {\r\n" +
				"    return y.new(arg0, arg1, arg2, arg3, arg4, arg5)\r\n" +
				"  }\r\n" +
				"  static new(y, arg0, arg1, arg2, arg3, arg4, arg5, arg6) {\r\n" +
				"    return y.new(arg0, arg1, arg2, arg3, arg4, arg5, arg6)\r\n" +
				"  }\r\n" +
				"  static new(y, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.\r\n" +
				"    return y.new(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  static call(func) {\r\n" +
				"    return func.call()\r\n" +
				"  }\r\n" +
				"  static call(func, arg0) {\r\n" +
				"    return func.call(arg0)\r\n" +
				"  }\r\n" +
				"  static call(func, arg0, arg1) {\r\n" +
				"    return func.call(arg0, arg1)\r\n" +
				"  }\r\n" +
				"  static call(func, arg0, arg1, arg2) {\r\n" +
				"    return func.call(arg0, arg1, arg2)\r\n" +
				"  }\r\n" +
				"  static call(func, arg0, arg1, arg2, arg3) {\r\n" +
				"    return func.call(arg0, arg1, arg2, arg3)\r\n" +
				"  }\r\n" +
				"  static call(func, arg0, arg1, arg2, arg3, arg4) {\r\n" +
				"    return func.call(arg0, arg1, arg2, arg3, arg4)\r\n" +
				"  }\r\n" +
				"  static call(func, arg0, arg1, arg2, arg3, arg4, arg5) {\r\n" +
				"    return func.call(arg0, arg1, arg2, arg3, arg4, arg5)\r\n" +
				"  }\r\n" +
				"  static call(func, arg0, arg1, arg2, arg3, arg4, arg5, arg6) {\r\n" +
				"    return func.call(arg0, arg1, arg2, arg3, arg4, arg5, arg6)\r\n" +
				"  }\r\n" +
				"  static call(func, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.\r\n" +
				"    return func.call(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"// Syntax end.\r\n" // Syntax lib.
		}

		return __syntax
	}
	static LCoroutine {
		if (__coroutine == null) {
			// Coroutine lib.
			__coroutine = "" +
				"// Coroutine begin.\r\n" +
				"class LCoroutine {\r\n" +
				"  static temporary_ {\r\n" +
				"    var result = __temporary\r\n" +
				"    __temporary = null\r\n" +
				"\r\n" +
				"    return result\r\n" +
				"  }\r\n" +
				"  static temporary_ = (value) {\r\n" +
				"    __temporary = value\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  static create(fiber) {\r\n" +
				"    var result = fiber\r\n" +
				"    if (fiber is Fn) {\r\n" +
				"      if (fiber.arity == 0) {\r\n" +
				"        result = Fiber.new { fiber.call() }\r\n" +
				"      } else if (fiber.arity == 1) {\r\n" +
				"        result = Fiber.new { | arg0 | fiber.call(arg0) }\r\n" +
				"      } else if (fiber.arity == 2) {\r\n" +
				"        result = Fiber.new { | argv | fiber.call(argv[0], argv[1]) }\r\n" +
				"      } else if (fiber.arity == 3) {\r\n" +
				"        result = Fiber.new { | argv | fiber.call(argv[0], argv[1], argv[2]) }\r\n" +
				"      } else if (fiber.arity == 4) {\r\n" +
				"        result = Fiber.new { | argv | fiber.call(argv[0], argv[1], argv[2], argv[3]) }\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return result\r\n" +
				"  }\r\n" +
				"  static wrap(f) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  static resume(co) {\r\n" +
				"    if (co.isDone) {\r\n" +
				"      return LTuple.new(false, \"Cannot resume dead coroutine.\")\r\n" +
				"    }\r\n" +
				"    temporary_ = null\r\n" +
				"\r\n" +
				"    return LTuple.new(true, co.call())\r\n" +
				"  }\r\n" +
				"  static resume(co, arg0) {\r\n" +
				"    if (co.isDone) {\r\n" +
				"      return LTuple.new(false, \"Cannot resume dead coroutine.\")\r\n" +
				"    }\r\n" +
				"    temporary_ = arg0\r\n" +
				"\r\n" +
				"    return LTuple.new(true, co.call(arg0))\r\n" +
				"  }\r\n" +
				"  static resume(co, arg0, arg1) {\r\n" +
				"    if (co.isDone) {\r\n" +
				"      return LTuple.new(false, \"Cannot resume dead coroutine.\")\r\n" +
				"    }\r\n" +
				"    temporary_ = LTuple.new(arg0, arg1)\r\n" +
				"\r\n" +
				"    return LTuple.new(true, co.call([ arg0, arg1 ]))\r\n" +
				"  }\r\n" +
				"  static resume(co, arg0, arg1, arg2) {\r\n" +
				"    if (co.isDone) {\r\n" +
				"      return LTuple.new(false, \"Cannot resume dead coroutine.\")\r\n" +
				"    }\r\n" +
				"    temporary_ = LTuple.new(arg0, arg1, arg2)\r\n" +
				"\r\n" +
				"    return LTuple.new(true, co.call([ arg0, arg1, arg2 ]))\r\n" +
				"  }\r\n" +
				"  static resume(co, arg0, arg1, arg2, arg3) { // Supports up to 4 parameters.\r\n" +
				"    if (co.isDone) {\r\n" +
				"      return LTuple.new(false, \"Cannot resume dead coroutine.\")\r\n" +
				"    }\r\n" +
				"    temporary_ = LTuple.new(arg0, arg1, arg2, arg3)\r\n" +
				"\r\n" +
				"    return LTuple.new(true, co.call([ arg0, arg1, arg2, arg3 ]))\r\n" +
				"  }\r\n" +
				"  static yield() {\r\n" +
				"    Fiber.yield()\r\n" +
				"\r\n" +
				"    return temporary_\r\n" +
				"  }\r\n" +
				"  static yield(arg0) {\r\n" +
				"    Fiber.yield(arg0)\r\n" +
				"\r\n" +
				"    return temporary_\r\n" +
				"  }\r\n" +
				"  static yield(arg0, arg1) {\r\n" +
				"    Fiber.yield(LTuple.new(arg0, arg1))\r\n" +
				"\r\n" +
				"    return temporary_\r\n" +
				"  }\r\n" +
				"  static yield(arg0, arg1, arg2) {\r\n" +
				"    Fiber.yield(LTuple.new(arg0, arg1, arg2))\r\n" +
				"\r\n" +
				"    return temporary_\r\n" +
				"  }\r\n" +
				"  static yield(arg0, arg1, arg2, arg3) { // Supports up to 4 parameters.\r\n" +
				"    Fiber.yield(LTuple.new(arg0, arg1, arg2, arg3))\r\n" +
				"\r\n" +
				"    return temporary_\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  static isYieldable() {\r\n" +
				"    return true\r\n" +
				"  }\r\n" +
				"  static running() {\r\n" +
				"    return Fiber.current\r\n" +
				"  }\r\n" +
				"  static status(co) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"// Coroutine end.\r\n" // Coroutine lib.
		}

		return __coroutine
	}
	static LString {
		if (__string == null) {
			// String lib.
			__string = "" +
				"// String begin.\r\n" +
				"class LString {\r\n" +
				"  static byte(s) {\r\n" +
				"    return LString.byte(s, 1)\r\n" +
				"  }\r\n" +
				"  static byte(s, i) {\r\n" +
				"    return LString.byte(s, i, i)[1]\r\n" +
				"  }\r\n" +
				"  static byte(s, i, j) {\r\n" +
				"    return LTable.new(\r\n" +
				"      s.bytes.take(j).skip(i - 1).toList\r\n" +
				"    )\r\n" +
				"  }\r\n" +
				"  static char() {\r\n" +
				"    return \"\"\r\n" +
				"  }\r\n" +
				"  static char(arg0) {\r\n" +
				"    return String.fromCodePoint(arg0)\r\n" +
				"  }\r\n" +
				"  static char(arg0, arg1) {\r\n" +
				"    return LString.char(arg0) + String.fromCodePoint(arg1)\r\n" +
				"  }\r\n" +
				"  static char(arg0, arg1, arg2) {\r\n" +
				"    return LString.char(arg0, arg1) + String.fromCodePoint(arg2)\r\n" +
				"  }\r\n" +
				"  static char(arg0, arg1, arg2, arg3) {\r\n" +
				"    return LString.char(arg0, arg1, arg2) + String.fromCodePoint(arg3)\r\n" +
				"  }\r\n" +
				"  static char(arg0, arg1, arg2, arg3, arg4) {\r\n" +
				"    return LString.char(arg0, arg1, arg2, arg3) + String.fromCodePoint(arg4)\r\n" +
				"  }\r\n" +
				"  static char(arg0, arg1, arg2, arg3, arg4, arg5) {\r\n" +
				"    return LString.char(arg0, arg1, arg2, arg3, arg4) + String.fromCodePoint(arg5)\r\n" +
				"  }\r\n" +
				"  static char(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {\r\n" +
				"    return LString.char(arg0, arg1, arg2, arg3, arg4, arg5) + String.fromCodePoint(arg6)\r\n" +
				"  }\r\n" +
				"  static char(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.\r\n" +
				"    return LString.char(arg0, arg1, arg2, arg3, arg4, arg5, arg6) + String.fromCodePoint(arg7)\r\n" +
				"  }\r\n" +
				"  static dump(function) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static dump(function, strip) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static find(s, pattern) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static find(s, pattern, init) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static find(s, pattern, init, plain) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static format(formatstring) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static format(formatstring, arg0) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static format(formatstring, arg0, arg1) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static format(formatstring, arg0, arg1, arg2) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static format(formatstring, arg0, arg1, arg2, arg3) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static gmatch(s, pattern) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static gsub(s, pattern, repl) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static gsub(s, pattern, repl, n) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static len(s) {\r\n" +
				"    return s.count\r\n" +
				"  }\r\n" +
				"  static lower(s) {\r\n" +
				"    return s.map(\r\n" +
				"      Fn.new { | ch |\r\n" +
				"        if (ch.codePoints[0] >= \"A\".codePoints[0] && ch.codePoints[0] <= \"Z\".codePoints[0]) {\r\n" +
				"          return String.fromCodePoint(ch.codePoints[0] + (\"a\".codePoints[0] - \"A\".codePoints[0]))\r\n" +
				"        }\r\n" +
				"\r\n" +
				"        return ch\r\n" +
				"      }\r\n" +
				"    ).join(\"\")\r\n" +
				"  }\r\n" +
				"  static match(s, pattern) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static match(s, pattern, init) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static pack(fmt, v1, v2) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static packsize(fmt) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static rep(s, n) {\r\n" +
				"    return LString.rep(s, n, \"\")\r\n" +
				"  }\r\n" +
				"  static rep(s, n, sep) {\r\n" +
				"    var result = \"\"\r\n" +
				"    for (i in 0...n) {\r\n" +
				"      result = result + s\r\n" +
				"      if (i != n - 1) {\r\n" +
				"        result = result + sep\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return result\r\n" +
				"  }\r\n" +
				"  static reverse(s) {\r\n" +
				"    var result = \"\"\r\n" +
				"    for (i in (s.count - 1)..0) {\r\n" +
				"      result = result + s[i]\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return result\r\n" +
				"  }\r\n" +
				"  static sub(s, i) {\r\n" +
				"    return LString.sub(s, i, s.count)\r\n" +
				"  }\r\n" +
				"  static sub(s, i, j) {\r\n" +
				"    return s.take(j).skip(i - 1).join(\"\")\r\n" +
				"  }\r\n" +
				"  static unpack(fmt, s) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static unpack(fmt, s, pos) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static upper(s) {\r\n" +
				"    return s.map(\r\n" +
				"      Fn.new { | ch |\r\n" +
				"        if (ch.codePoints[0] >= \"a\".codePoints[0] && ch.codePoints[0] <= \"z\".codePoints[0]) {\r\n" +
				"          return String.fromCodePoint(ch.codePoints[0] + (\"A\".codePoints[0] - \"a\".codePoints[0]))\r\n" +
				"        }\r\n" +
				"\r\n" +
				"        return ch\r\n" +
				"      }\r\n" +
				"    ).join(\"\")\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"// String end.\r\n" // String lib.
		}

		return __string
	}
	static LTable {
		if (__table == null) {
			// Table lib.
			__table = "" +
				"// Table begin.\r\n" +
				"class LTable {\r\n" +
				"  static concat(list) {\r\n" +
				"    return LTable.concat(list, \"\")\r\n" +
				"  }\r\n" +
				"  static concat(list, sep) {\r\n" +
				"    return LTable.concat(list, sep, 1)\r\n" +
				"  }\r\n" +
				"  static concat(list, sep, i) {\r\n" +
				"    return LTable.concat(list, sep, i, list.len__)\r\n" +
				"  }\r\n" +
				"  static concat(list, sep, i, j) {\r\n" +
				"    var result = \"\"\r\n" +
				"    for (k in i..j) {\r\n" +
				"      result = result + list[k]\r\n" +
				"      if (k != j) {\r\n" +
				"        result = result + sep\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return result\r\n" +
				"  }\r\n" +
				"  static insert(list, value) {\r\n" +
				"    return LTable.insert(list, list.len__ + 1, value)\r\n" +
				"  }\r\n" +
				"  static insert(list, pos, value) {\r\n" +
				"    list[pos] = value\r\n" +
				"  }\r\n" +
				"  static move(a1, f, e, t) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static move(a1, f, e, t, a2) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static pack(arg0) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static remove(list) {\r\n" +
				"    return LTable.remove(list, list.len__)\r\n" +
				"  }\r\n" +
				"  static remove(list, pos) {\r\n" +
				"    var len = list.len__\r\n" +
				"    if (pos <= 0 || pos > len) {\r\n" +
				"      return null\r\n" +
				"    }\r\n" +
				"    var result = list[pos]\r\n" +
				"    for (i in (pos + 1)...len) {\r\n" +
				"      list[i - 1] = list[i]\r\n" +
				"    }\r\n" +
				"    list[len] = null\r\n" +
				"\r\n" +
				"    return result\r\n" +
				"  }\r\n" +
				"  static sort(list) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static sort(list, comp) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static unpack(list) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static unpack(list, i) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static unpack(list, i, j) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  construct new() {\r\n" +
				"    _length = 0\r\n" +
				"  }\r\n" +
				"  construct new(obj) {\r\n" +
				"    _length = 0\r\n" +
				"\r\n" +
				"    if (obj is List) {\r\n" +
				"      for (i in 0...obj.count) {\r\n" +
				"        this[i + 1] = obj[i] // 1-based.\r\n" +
				"      }\r\n" +
				"    } else if (obj is Map) {\r\n" +
				"      for (kv in obj) {\r\n" +
				"        this[kv.key] = kv.value\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  toString {\r\n" +
				"    if (len__ == raw_.count) {\r\n" +
				"      var result = \"\"\r\n" +
				"      for (i in 1..len__) {\r\n" +
				"        result = result + raw_[i].toString\r\n" +
				"        if (i != len__) {\r\n" +
				"          result = result + \", \"\r\n" +
				"        }\r\n" +
				"      }\r\n" +
				"\r\n" +
				"      return \"{ \" + result + \" }\"\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return raw_.toString\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  raw_ {\r\n" +
				"    if (_raw == null) {\r\n" +
				"      _raw = { }\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return _raw\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  [index] {\r\n" +
				"    if (raw_.containsKey(index)) {\r\n" +
				"      return raw_[index]\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return null\r\n" +
				"  }\r\n" +
				"  [index] = (value) {\r\n" +
				"    if (value == null) {\r\n" +
				"      if (raw_.containsKey(index)) {\r\n" +
				"        raw_.remove(index)\r\n" +
				"      }\r\n" +
				"    } else {\r\n" +
				"      raw_[index] = value\r\n" +
				"      _length = -1\r\n" +
				"    }\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  count { raw_.count }\r\n" +
				"\r\n" +
				"  len__ {\r\n" +
				"    if (_length == -1) {\r\n" +
				"      for (i in 1..raw_.count) {\r\n" +
				"        if (raw_.containsKey(i)) {\r\n" +
				"          _length = i // 1-based.\r\n" +
				"        } else {\r\n" +
				"          break\r\n" +
				"        }\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return _length == -1 ? 0 : _length\r\n" +
				"  }\r\n" +
				"\r\n" +
				"  iterate(iterator) {\r\n" +
				"    iterator = raw_.iterate(iterator)\r\n" +
				"\r\n" +
				"    return iterator\r\n" +
				"  }\r\n" +
				"  iteratorValue(iterator) {\r\n" +
				"    return raw_.iteratorValue(iterator)\r\n" +
				"  }\r\n" +
				"} // `LTable`.\r\n" +
				"// Table end.\r\n" // Table lib.
		}

		return __table
	}
	static LMath {
		if (__math == null) {
			// Math lib.
			__math = "" +
				"// Math begin.\r\n" +
				"import \"random\" for Random\r\n" +
				"\r\n" +
				"class LMath {\r\n" +
				"  static abs(x) {\r\n" +
				"    return x.abs\r\n" +
				"  }\r\n" +
				"  static acos(x) {\r\n" +
				"    return x.acos\r\n" +
				"  }\r\n" +
				"  static asin(x) {\r\n" +
				"    return x.asin\r\n" +
				"  }\r\n" +
				"  static atan(y) {\r\n" +
				"    return y.atan\r\n" +
				"  }\r\n" +
				"  static atan(y, x) {\r\n" +
				"    return y.atan(x)\r\n" +
				"  }\r\n" +
				"  static ceil(x) {\r\n" +
				"    return x.ceil\r\n" +
				"  }\r\n" +
				"  static cos(x) {\r\n" +
				"    return x.cos\r\n" +
				"  }\r\n" +
				"  static deg(x) {\r\n" +
				"    return x / Num.pi * 180\r\n" +
				"  }\r\n" +
				"  static exp(x) {\r\n" +
				"    var e = 2.7182818284590452353602874713527\r\n" +
				"\r\n" +
				"    return e.pow(x)\r\n" +
				"  }\r\n" +
				"  static floor(x) {\r\n" +
				"    return x.floor\r\n" +
				"  }\r\n" +
				"  static fmod(x, y) {\r\n" +
				"    return x - y * (x / y).floor\r\n" +
				"  }\r\n" +
				"  static huge {\r\n" +
				"    return 1 / 0\r\n" +
				"  }\r\n" +
				"  static log(x) {\r\n" +
				"    return x.log\r\n" +
				"  }\r\n" +
				"  static log(x, base) {\r\n" +
				"    return x.log / base.log\r\n" +
				"  }\r\n" +
				"  static max(arg0, arg1) {\r\n" +
				"    return arg0 > arg1 ? arg0 : arg1\r\n" +
				"  }\r\n" +
				"  static max(arg0, arg1, arg2) {\r\n" +
				"    return max(max(arg0, arg1), arg2)\r\n" +
				"  }\r\n" +
				"  static max(arg0, arg1, arg2, arg3) { // Supports up to 4 parameters.\r\n" +
				"    return max(max(max(arg0, arg1), arg2), arg3)\r\n" +
				"  }\r\n" +
				"  static maxInteger {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static min(arg0, arg1) {\r\n" +
				"    return arg0 < arg1 ? arg0 : arg1\r\n" +
				"  }\r\n" +
				"  static min(arg0, arg1, arg2) {\r\n" +
				"    return min(min(arg0, arg1), arg2)\r\n" +
				"  }\r\n" +
				"  static min(arg0, arg1, arg2, arg3) { // Supports up to 4 parameters.\r\n" +
				"    return min(min(min(arg0, arg1), arg2), arg3)\r\n" +
				"  }\r\n" +
				"  static minInteger {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"  static modf(x) {\r\n" +
				"    if (x < 0) {\r\n" +
				"      return [ -(-x).floor, x + (-x).floor ]\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return [ x.floor, x - x.floor ]\r\n" +
				"  }\r\n" +
				"  static pi {\r\n" +
				"    return Num.pi\r\n" +
				"  }\r\n" +
				"  static pow(x, y) {\r\n" +
				"    return x.pow(y)\r\n" +
				"  }\r\n" +
				"  static rad(x) {\r\n" +
				"    return x / 180 * Num.pi\r\n" +
				"  }\r\n" +
				"  static random {\r\n" +
				"    if (__random == null) {\r\n" +
				"      __random = Random.new()\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return __random\r\n" +
				"  }\r\n" +
				"  static random() {\r\n" +
				"    return LMath.random.float()\r\n" +
				"  }\r\n" +
				"  static random(n) {\r\n" +
				"    return LMath.random(1, n)\r\n" +
				"  }\r\n" +
				"  static random(m, n) {\r\n" +
				"    return LMath.random.int(m, n + 1)\r\n" +
				"  }\r\n" +
				"  static randomSeed(x) {\r\n" +
				"    __random = Random.new(x)\r\n" +
				"  }\r\n" +
				"  static sin(x) {\r\n" +
				"    return x.sin\r\n" +
				"  }\r\n" +
				"  static sqrt(x) {\r\n" +
				"    return x.sqrt\r\n" +
				"  }\r\n" +
				"  static tan(x) {\r\n" +
				"    return x.tan\r\n" +
				"  }\r\n" +
				"  static toInteger(x) {\r\n" +
				"    if (x is String) {\r\n" +
				"      x = Num.fromString(x)\r\n" +
				"    }\r\n" +
				"    if (x is Num && x.isInteger) {\r\n" +
				"      return x\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return null\r\n" +
				"  }\r\n" +
				"  static type(x) {\r\n" +
				"    if (x is Num) {\r\n" +
				"      if (x.isInteger) {\r\n" +
				"        return \"integer\"\r\n" +
				"      } else {\r\n" +
				"        return \"float\"\r\n" +
				"      }\r\n" +
				"    }\r\n" +
				"\r\n" +
				"    return null\r\n" +
				"  }\r\n" +
				"  static ult(m, n) {\r\n" +
				"    Fiber.abort(\"Not implemented.\")\r\n" +
				"  }\r\n" +
				"}\r\n" +
				"\r\n" +
				"class math {\r\n" +
				"  static huge { LMath.huge }\r\n" +
				"  static maxInteger { LMath.maxInteger }\r\n" +
				"  static minInteger { LMath.minInteger }\r\n" +
				"  static pi { LMath.pi }\r\n" +
				"}\r\n" +
				"// Math end.\r\n" // Math lib.
		}

		return __math
	}

	static function(module, func) {
		if (__entries == null) {
			__entries = {
				null: {
					"length": { "lib": "syntax", "function": "Lua.len" },

					"assert": { "lib": "syntax", "function": "Lua.assert" },
					"collectgarbage": { "lib": "syntax", "function": "Lua.collectGarbage" },
					"dofile": { "lib": "syntax", "function": "Lua.doFile" },
					"error": { "lib": "syntax", "function": "Lua.error" },
					"getmetatable": { "lib": "syntax", "function": "Lua.getmetatable" },
					"ipairs": { "lib": "syntax", "function": "LIPairs.new" },
					"load": { "lib": "syntax", "function": "Lua.load" },
					"loadfile": { "lib": "syntax", "function": "Lua.loadFile" },
					"next": { "lib": "syntax", "function": "Lua.next" },
					"pairs": { "lib": "syntax", "function": "LPairs.new" },
					"pcall": { "lib": "syntax", "function": "Lua.pcall" },
					"print": { "lib": "syntax", "function": "Lua.print" },
					"rawequal": { "lib": "syntax", "function": "Lua.rawEqual" },
					"rawget": { "lib": "syntax", "function": "Lua.rawGet" },
					"rawlen": { "lib": "syntax", "function": "Lua.rawLen" },
					"rawset": { "lib": "syntax", "function": "Lua.rawSet" },
					"select": { "lib": "syntax", "function": "Lua.select" },
					"setmetatable": { "lib": "syntax", "function": "Lua.setMetatable" },
					"tonumber": { "lib": "syntax", "function": "Lua.toNumber" },
					"tostring": { "lib": "syntax", "function": "Lua.toString" },
					"type": { "lib": "syntax", "function": "Lua.type" },

					"new": { "lib": "syntax", "function": "Lua.new" },
					"call": { "lib": "syntax", "function": "Lua.call" },

					// TODO
					"huge": { "lib": "math", "function": "huge" },
					"maxinteger": { "lib": "math", "function": "maxInteger" },
					"mininteger": { "lib": "math", "function": "minInteger" },
					"pi": { "lib": "math", "function": "pi" }
				},
				"coroutine": {
					"create": { "lib": "coroutine", "function": "LCoroutine.create" },
					"isyieldable": { "lib": "coroutine", "function": "LCoroutine.isYieldable" },
					"resume": { "lib": "coroutine", "function": "LCoroutine.resume" },
					"running": { "lib": "coroutine", "function": "LCoroutine.running" },
					"status": { "lib": "coroutine", "function": "LCoroutine.status" },
					"wrap": { "lib": "coroutine", "function": "LCoroutine.wrap" },
					"yield": { "lib": "coroutine", "function": "LCoroutine.yield" }
				},
				"string": {
					"byte": { "lib": "string", "function": "LString.byte" },
					"char": { "lib": "string", "function": "LString.char" },
					"dump": { "lib": "string", "function": "LString.dump" },
					"find": { "lib": "string", "function": "LString.find" },
					"format": { "lib": "string", "function": "LString.format" },
					"gmatch": { "lib": "string", "function": "LString.gmatch" },
					"gsub": { "lib": "string", "function": "LString.gsub" },
					"len": { "lib": "string", "function": "LString.len" },
					"lower": { "lib": "string", "function": "LString.lower" },
					"match": { "lib": "string", "function": "LString.match" },
					"pack": { "lib": "string", "function": "LString.pack" },
					"packsize": { "lib": "string", "function": "LString.packsize" },
					"rep": { "lib": "string", "function": "LString.rep" },
					"reverse": { "lib": "string", "function": "LString.reverse" },
					"sub": { "lib": "string", "function": "LString.sub" },
					"unpack": { "lib": "string", "function": "LString.unpack" },
					"upper": { "lib": "string", "function": "LString.upper" }
				},
				"table": {
					"concat": { "lib": "table", "function": "LTable.concat" },
					"insert": { "lib": "table", "function": "LTable.insert" },
					"move": { "lib": "table", "function": "LTable.move" },
					"pack": { "lib": "table", "function": "LTable.pack" },
					"remove": { "lib": "table", "function": "LTable.remove" },
					"sort": { "lib": "table", "function": "LTable.sort" },
					"unpack": { "lib": "table", "function": "LTable.unpack" }
				},
				"math": {
					"abs": { "lib": "math", "function": "LMath.abs" },
					"acos": { "lib": "math", "function": "LMath.acos" },
					"asin": { "lib": "math", "function": "LMath.asin" },
					"atan": { "lib": "math", "function": "LMath.atan" },
					"ceil": { "lib": "math", "function": "LMath.ceil" },
					"cos": { "lib": "math", "function": "LMath.cos" },
					"deg": { "lib": "math", "function": "LMath.deg" },
					"exp": { "lib": "math", "function": "LMath.exp" },
					"floor": { "lib": "math", "function": "LMath.floor" },
					"fmod": { "lib": "math", "function": "LMath.fmod" },
					"huge": { "lib": "math", "function": "LMath.huge" },
					"log": { "lib": "math", "function": "LMath.log" },
					"max": { "lib": "math", "function": "LMath.max" },
					"maxinteger": { "lib": "math", "function": "LMath.maxInteger" },
					"min": { "lib": "math", "function": "LMath.min" },
					"mininteger": { "lib": "math", "function": "LMath.minInteger" },
					"modf": { "lib": "math", "function": "LMath.modf" },
					"pi": { "lib": "math", "function": "LMath.pi" },
					"rad": { "lib": "math", "function": "LMath.rad" },
					"random": { "lib": "math", "function": "LMath.random" },
					"randomseed": { "lib": "math", "function": "LMath.randomSeed" },
					"sin": { "lib": "math", "function": "LMath.sin" },
					"sqrt": { "lib": "math", "function": "LMath.sqrt" },
					"tan": { "lib": "math", "function": "LMath.tan" },
					"tointeger": { "lib": "math", "function": "LMath.toInteger" },
					"type": { "lib": "math", "function": "LMath.type" },
					"ult": { "lib": "math", "function": "LMath.ult" }
				}
			}
		}
		if (__entries.containsKey(module) && __entries[module].containsKey(func)) {
			return __entries[module][func]
		}

		return null
	}
}

/* ========================================================} */

/*
** {========================================================
** Main class
*/

class B95 {
	/**< Constructor. */

	construct new() {
		var raise = Fn.new { | msg | Fiber.abort(msg) }

		_lexer = Lexer.new(raise)
		_parser = Parser.new(raise)
		_generator = Generator.new(raise)
	}
	construct new(raise) {
		_lexer = Lexer.new(raise)
		_parser = Parser.new(raise)
		_generator = Generator.new(raise)
	}

	/**< Compile. */

	compile(code) {
		return compile(code, false)
	}
	compile(code, debug) {
		var tks = tokenise(code)
		var ast = parse(tks)
		var ops = generate(ast, debug)
		ops.tokens = tks
		ops.ast = ast

		return ops
	}

	/**< Callbacks. */

	onRequire(cb) {
		_generator.onRequire(cb)

		return this
	}

	onFunction(cb) {
		_generator.onFunction(cb)

		return this
	}

	/**< Procedure. */

	tokenise(code) {
		return _lexer.load(code)
	}
	parse(tokens) {
		return _parser.load(tokens)
	}
	generate(ast, debug) {
		return _generator.serialize(ast, debug)
	}
}

/* ========================================================} */
