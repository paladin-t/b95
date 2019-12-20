// Debug patch.
// Debug begin.
class LDebug {
	construct new() {
	}

	lastLine { _lastLine }
	lastColumn { _lastColumn }
	setLastLocation(ln, col) {
		_lastLine = ln
		_lastColumn = col
	}
}
var ldebug = LDebug.new()
// Debug end.
// Debug patch.
// Tuple lib.
// Tuple begin.
class LTuple {
	construct new() {
		ctor([ ])
	}
	construct new(arg0) {
		ctor([ arg0 ])
	}
	construct new(arg0, arg1) {
		ctor([ arg0, arg1 ])
	}
	construct new(arg0, arg1, arg2) {
		ctor([ arg0, arg1, arg2 ])
	}
	construct new(arg0, arg1, arg2, arg3) {
		ctor([ arg0, arg1, arg2, arg3 ])
	}
	construct new(arg0, arg1, arg2, arg3, arg4) {
		ctor([ arg0, arg1, arg2, arg3, arg4 ])
	}
	construct new(arg0, arg1, arg2, arg3, arg4, arg5) {
		ctor([ arg0, arg1, arg2, arg3, arg4, arg5 ])
	}
	construct new(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		ctor([ arg0, arg1, arg2, arg3, arg4, arg5, arg6 ])
	}
	construct new(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		ctor([ arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7 ])
	}
	ctor(argv) {
		_args = [ ]
		for (arg in argv) {
			if (arg is LTuple) {
				_args = _args + arg.toList
			} else {
				_args.add(arg)
			}
		}
	}

	toString {
		return "< " + _args.join(", ") + " >"
	}
	toList {
		return _args.toList
	}

	[index] {
		return _args[index]
	}
	[index] = (value) {
		_args[index] = value
	}

	== (other) {
		if (!(other is LTuple) || count != other.count) {
			return false
		}
		for (i in 0...count) {
			if (this[i] != other[i]) {
				return false
			}
		}

		return true
	}
	!= (other) {
		if (!(other is LTuple) || count != other.count) {
			return true
		}
		for (i in 0...count) {
			if (this[i] != other[i]) {
				return true
			}
		}

		return false
	}

	count {
		return _args.count
	}
	isEmpty {
		return _args.isEmpty
	}

	join(sep) {
		return _args.join(sep)
	}
}
// Tuple end.
// Tuple lib.
// Syntax lib.
// Syntax begin.
class LRange {
	construct new(b, e, s) {
		_begin = b
		_end = e
		_step = s
	}

	iterate(iterator) {
		if (iterator == null) {
			iterator = _begin

			return iterator
		}
		iterator = iterator + _step
		if (_begin < _end) {
			if (iterator > _end) {
				return null
			}
		} else if (_begin > _end) {
			if (iterator < _end) {
				return null
			}
		} else if (_begin == _end) {
			return null
		}

		return iterator
	}
	iteratorValue(iterator) {
		return iterator
	}
}

class LIPairs {
	construct new(tbl) {
		_table = tbl
	}

	iterate(iterator) {
		if (iterator == null) {
			iterator = 0 // 1-based.
		}
		iterator = iterator + 1
		if (iterator > _table.len__) {
			return null
		}

		return iterator
	}
	iteratorValue(iterator) {
		return LTuple.new(iterator, _table[iterator])
	}
}

class LPairs {
	construct new(tbl) {
		_table = tbl
	}

	iterate(iterator) {
		iterator = _table.iterate(iterator)

		return iterator
	}
	iteratorValue(iterator) {
		var kv = _table.iteratorValue(iterator)

		return LTuple.new(kv.key, kv.value)
	}
}

class Lua {
	static len(obj) {
		return obj.len__
	}

	static assert(v) {
		assert(v, "Assertion.")
	}
	static assert(v, message) {
		if (!v) {
			Fiber.abort(message)
		}
	}
	static collectGarbage() {
		return System.gc()
	}
	static collectGarbage(opt) {
		return System.gc()
	}
	static collectGarbage(opt, arg) {
		return System.gc()
	}
	static doFile(filename) {
		Fiber.abort("Not implemented.")
	}
	static error(message) {
		error(message, 0)
	}
	static error(message, level) {
		Fiber.abort(message)
	}
	static getMetatable(object) {
		Fiber.abort("Not implemented.")
	}
	static load(chunk) {
		Fiber.abort("Not implemented.")
	}
	static load(chunk, chunkname) {
		Fiber.abort("Not implemented.")
	}
	static load(chunk, chunkname, mode) {
		Fiber.abort("Not implemented.")
	}
	static load(chunk, chunkname, mode, env) {
		Fiber.abort("Not implemented.")
	}
	static loadFile() {
		Fiber.abort("Not implemented.")
	}
	static loadFile(filename) {
		Fiber.abort("Not implemented.")
	}
	static loadFile(filename, mode) {
		Fiber.abort("Not implemented.")
	}
	static loadFile(filename, mode, env) {
		Fiber.abort("Not implemented.")
	}
	static next(table) {
		return next(table, null)
	}
	static next(table, index) {
		var iterator = table.iterate(null)
		if (!iterator) {
			return LTuple.new(null, null)
		}
		var kv = table.iteratorValue(iterator)
		if (index != null) {
			while (kv.key != index) {
				iterator = table.iterate(iterator)
				kv = table.iteratorValue(iterator)
			}
			iterator = table.iterate(iterator)
			if (iterator) {
				kv = table.iteratorValue(iterator)
			} else {
				return LTuple.new(null, null)
			}
		}

		return LTuple.new(kv.key, kv.value)
	}
	static pcall(f) {
		Fiber.abort("Not implemented.")
	}
	static pcall(f, arg0) {
		Fiber.abort("Not implemented.")
	}
	static pcall(f, arg0, arg1) {
		Fiber.abort("Not implemented.")
	}
	static pcall(f, arg0, arg1, arg2) {
		Fiber.abort("Not implemented.")
	}
	static pcall(f, arg0, arg1, arg2, arg3) {
		Fiber.abort("Not implemented.")
	}
	static print_(argv) {
		for (i in 0...argv.count) {
			if (argv[i] == null) {
				argv[i] = "nil"
			} else if (argv[i] is LTuple) {
				argv[i] = argv[i].join("\t")
			}
		}

		System.print(argv.join("\t"))
	}
	static print(arg0) {
		print_([ arg0 ])
	}
	static print(arg0, arg1) {
		print_([ arg0, arg1 ])
	}
	static print(arg0, arg1, arg2) {
		print_([ arg0, arg1, arg2 ])
	}
	static print(arg0, arg1, arg2, arg3) {
		print_([ arg0, arg1, arg2, arg3 ])
	}
	static print(arg0, arg1, arg2, arg3, arg4) {
		print_([ arg0, arg1, arg2, arg3, arg4 ])
	}
	static print(arg0, arg1, arg2, arg3, arg4, arg5) {
		print_([ arg0, arg1, arg2, arg3, arg4, arg5 ])
	}
	static print(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		print_([ arg0, arg1, arg2, arg3, arg4, arg5, arg6 ])
	}
	static print(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		print_([ arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7 ])
	}
	static rawEqual(v1, v2) {
		return v1 == v2
	}
	static rawGet(table, index) {
		return table[index]
	}
	static rawLen(v) {
		return v.len__
	}
	static rawSet(table, index, value) {
		table[index] = value
	}
	static select_(index, argv) {
		if (index == "#") {
			return argv.count
		}
		var result = LTuple.new()
		if (index == 0) {
			return result
		}
		var s = index > 0 ? index - 1 : argv.count + index
		if (s < 0) {
			s = 0
		}
		result.ctor(argv.skip(s))

		return result
	}
	static select(index) {
		return select_(index, [ ])
	}
	static select(index, arg0) {
		return select_(index, [ arg0 ])
	}
	static select(index, arg0, arg1) {
		return select_(index, [ arg0, arg1 ])
	}
	static select(index, arg0, arg1, arg2) {
		return select_(index, [ arg0, arg1, arg2 ])
	}
	static select(index, arg0, arg1, arg2, arg3) {
		return select_(index, [ arg0, arg1, arg2, arg3 ])
	}
	static select(index, arg0, arg1, arg2, arg3, arg4) {
		return select_(index, [ arg0, arg1, arg2, arg3, arg4 ])
	}
	static select(index, arg0, arg1, arg2, arg3, arg4, arg5) {
		return select_(index, [ arg0, arg1, arg2, arg3, arg4, arg5 ])
	}
	static select(index, arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		return select_(index, [ arg0, arg1, arg2, arg3, arg4, arg5, arg6 ])
	}
	static select(index, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		return select_(index, [ arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7 ])
	}
	static setMetatable(table, metatable) {
		Fiber.abort("Not implemented.")
	}
	static toNumber(e) {
		return Num.fromString(e)
	}
	static toNumber(e, base) {
		Fiber.abort("Not implemented.")
	}
	static toString(v) {
		return v.toString
	}
	static type(v) {
		if (v == null) {
			return "nil"
		}
		if (v is Num) {
			return "number"
		}
		if (v is String) {
			return "string"
		}
		if (v is Bool) {
			return "boolean"
		}
		if (v is Fn) {
			return "function"
		}
		if (v is Fiber) {
			return "function"
		}

		return "table"
	}

	static new(y) {
		return y.new()
	}
	static new(y, arg0) {
		return y.new(arg0)
	}
	static new(y, arg0, arg1) {
		return y.new(arg0, arg1)
	}
	static new(y, arg0, arg1, arg2) {
		return y.new(arg0, arg1, arg2)
	}
	static new(y, arg0, arg1, arg2, arg3) {
		return y.new(arg0, arg1, arg2, arg3)
	}
	static new(y, arg0, arg1, arg2, arg3, arg4) {
		return y.new(arg0, arg1, arg2, arg3, arg4)
	}
	static new(y, arg0, arg1, arg2, arg3, arg4, arg5) {
		return y.new(arg0, arg1, arg2, arg3, arg4, arg5)
	}
	static new(y, arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		return y.new(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	}
	static new(y, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		return y.new(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	}

	static isa(obj, y) {
		return obj is y
	}

	static call(func) {
		return func.call()
	}
	static call(func, arg0) {
		return func.call(arg0)
	}
	static call(func, arg0, arg1) {
		return func.call(arg0, arg1)
	}
	static call(func, arg0, arg1, arg2) {
		return func.call(arg0, arg1, arg2)
	}
	static call(func, arg0, arg1, arg2, arg3) {
		return func.call(arg0, arg1, arg2, arg3)
	}
	static call(func, arg0, arg1, arg2, arg3, arg4) {
		return func.call(arg0, arg1, arg2, arg3, arg4)
	}
	static call(func, arg0, arg1, arg2, arg3, arg4, arg5) {
		return func.call(arg0, arg1, arg2, arg3, arg4, arg5)
	}
	static call(func, arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		return func.call(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	}
	static call(func, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		return func.call(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	}

	static apply(arg) {
		return arg
	}
}
// Syntax end.
// Syntax lib.
// Coroutine lib.
// Coroutine begin.
class LCoroutine {
	static temporary_ {
		var result = __temporary
		__temporary = null

		return result
	}
	static temporary_ = (value) {
		__temporary = value
	}

	static create(fiber) {
		var result = fiber
		if (fiber is Fn) {
			if (fiber.arity == 0) {
				result = Fiber.new { fiber.call() }
			} else if (fiber.arity == 1) {
				result = Fiber.new { | arg0 | fiber.call(arg0) }
			} else if (fiber.arity == 2) {
				result = Fiber.new { | argv | fiber.call(argv[0], argv[1]) }
			} else if (fiber.arity == 3) {
				result = Fiber.new { | argv | fiber.call(argv[0], argv[1], argv[2]) }
			} else if (fiber.arity == 4) {
				result = Fiber.new { | argv | fiber.call(argv[0], argv[1], argv[2], argv[3]) }
			}
		}

		return result
	}
	static wrap(f) {
		Fiber.abort("Not implemented.")
	}

	static resume(co) {
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary_ = null

		return LTuple.new(true, co.call())
	}
	static resume(co, arg0) {
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary_ = arg0

		return LTuple.new(true, co.call(arg0))
	}
	static resume(co, arg0, arg1) {
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary_ = LTuple.new(arg0, arg1)

		return LTuple.new(true, co.call([ arg0, arg1 ]))
	}
	static resume(co, arg0, arg1, arg2) {
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary_ = LTuple.new(arg0, arg1, arg2)

		return LTuple.new(true, co.call([ arg0, arg1, arg2 ]))
	}
	static resume(co, arg0, arg1, arg2, arg3) { // Supports up to 4 parameters.
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary_ = LTuple.new(arg0, arg1, arg2, arg3)

		return LTuple.new(true, co.call([ arg0, arg1, arg2, arg3 ]))
	}
	static yield() {
		Fiber.yield()

		return temporary_
	}
	static yield(arg0) {
		Fiber.yield(arg0)

		return temporary_
	}
	static yield(arg0, arg1) {
		Fiber.yield(LTuple.new(arg0, arg1))

		return temporary_
	}
	static yield(arg0, arg1, arg2) {
		Fiber.yield(LTuple.new(arg0, arg1, arg2))

		return temporary_
	}
	static yield(arg0, arg1, arg2, arg3) { // Supports up to 4 parameters.
		Fiber.yield(LTuple.new(arg0, arg1, arg2, arg3))

		return temporary_
	}

	static isYieldable() {
		return true
	}
	static running() {
		return Fiber.current
	}
	static status(co) {
		Fiber.abort("Not implemented.")
	}
}
// Coroutine end.
// Coroutine lib.
// String lib.
// String begin.
class LString {
	static byte(s) {
		return byte(s, 1)
	}
	static byte(s, i) {
		return byte(s, i, i)[1]
	}
	static byte(s, i, j) {
		return LTable.new(
			s.bytes.take(j).skip(i - 1).toList
		)
	}
	static char() {
		return ""
	}
	static char(arg0) {
		return String.fromCodePoint(arg0)
	}
	static char(arg0, arg1) {
		return char(arg0) + String.fromCodePoint(arg1)
	}
	static char(arg0, arg1, arg2) {
		return char(arg0, arg1) + String.fromCodePoint(arg2)
	}
	static char(arg0, arg1, arg2, arg3) {
		return char(arg0, arg1, arg2) + String.fromCodePoint(arg3)
	}
	static char(arg0, arg1, arg2, arg3, arg4) {
		return char(arg0, arg1, arg2, arg3) + String.fromCodePoint(arg4)
	}
	static char(arg0, arg1, arg2, arg3, arg4, arg5) {
		return char(arg0, arg1, arg2, arg3, arg4) + String.fromCodePoint(arg5)
	}
	static char(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		return char(arg0, arg1, arg2, arg3, arg4, arg5) + String.fromCodePoint(arg6)
	}
	static char(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		return char(arg0, arg1, arg2, arg3, arg4, arg5, arg6) + String.fromCodePoint(arg7)
	}
	static dump(function) {
		Fiber.abort("Not implemented.")
	}
	static dump(function, strip) {
		Fiber.abort("Not implemented.")
	}
	static find(s, pattern) {
		Fiber.abort("Not implemented.")
	}
	static find(s, pattern, init) {
		Fiber.abort("Not implemented.")
	}
	static find(s, pattern, init, plain) {
		Fiber.abort("Not implemented.")
	}
	static format(formatstring) {
		Fiber.abort("Not implemented.")
	}
	static format(formatstring, arg0) {
		Fiber.abort("Not implemented.")
	}
	static format(formatstring, arg0, arg1) {
		Fiber.abort("Not implemented.")
	}
	static format(formatstring, arg0, arg1, arg2) {
		Fiber.abort("Not implemented.")
	}
	static format(formatstring, arg0, arg1, arg2, arg3) {
		Fiber.abort("Not implemented.")
	}
	static gmatch(s, pattern) {
		Fiber.abort("Not implemented.")
	}
	static gsub(s, pattern, repl) {
		Fiber.abort("Not implemented.")
	}
	static gsub(s, pattern, repl, n) {
		Fiber.abort("Not implemented.")
	}
	static len(s) {
		return s.count
	}
	static lower(s) {
		return s.map(
			Fn.new { | ch |
				if (ch.codePoints[0] >= "A".codePoints[0] && ch.codePoints[0] <= "Z".codePoints[0]) {
					return String.fromCodePoint(ch.codePoints[0] + ("a".codePoints[0] - "A".codePoints[0]))
				}

				return ch
			}
		).join("")
	}
	static match(s, pattern) {
		Fiber.abort("Not implemented.")
	}
	static match(s, pattern, init) {
		Fiber.abort("Not implemented.")
	}
	static pack(fmt, v1, v2) {
		Fiber.abort("Not implemented.")
	}
	static packsize(fmt) {
		Fiber.abort("Not implemented.")
	}
	static rep(s, n) {
		return rep(s, n, "")
	}
	static rep(s, n, sep) {
		var result = ""
		for (i in 0...n) {
			result = result + s
			if (i != n - 1) {
				result = result + sep
			}
		}

		return result
	}
	static reverse(s) {
		var result = ""
		for (i in (s.count - 1)..0) {
			result = result + s[i]
		}

		return result
	}
	static sub(s, i) {
		return sub(s, i, s.count)
	}
	static sub(s, i, j) {
		return s.take(j).skip(i - 1).join("")
	}
	static unpack(fmt, s) {
		Fiber.abort("Not implemented.")
	}
	static unpack(fmt, s, pos) {
		Fiber.abort("Not implemented.")
	}
	static upper(s) {
		return s.map(
			Fn.new { | ch |
				if (ch.codePoints[0] >= "a".codePoints[0] && ch.codePoints[0] <= "z".codePoints[0]) {
					return String.fromCodePoint(ch.codePoints[0] + ("A".codePoints[0] - "a".codePoints[0]))
				}

				return ch
			}
		).join("")
	}
}
// String end.
// String lib.
// Table lib.
// Table begin.
class LTable {
	static concat(list) {
		return concat(list, "")
	}
	static concat(list, sep) {
		return concat(list, sep, 1)
	}
	static concat(list, sep, i) {
		return concat(list, sep, i, list.len__)
	}
	static concat(list, sep, i, j) {
		var result = ""
		for (k in i..j) {
			result = result + list[k]
			if (k != j) {
				result = result + sep
			}
		}

		return result
	}
	static insert(list, value) {
		return insert(list, list.len__ + 1, value)
	}
	static insert(list, pos, value) {
		list[pos] = value
	}
	static move(a1, f, e, t) {
		Fiber.abort("Not implemented.")
	}
	static move(a1, f, e, t, a2) {
		Fiber.abort("Not implemented.")
	}
	static pack(arg0) {
		Fiber.abort("Not implemented.")
	}
	static remove(list) {
		return remove(list, list.len__)
	}
	static remove(list, pos) {
		var len = list.len__
		if (pos <= 0 || pos > len) {
			return null
		}
		var result = list[pos]
		for (i in (pos + 1)...len) {
			list[i - 1] = list[i]
		}
		list[len] = null

		return result
	}
	static sort(list) {
		Fiber.abort("Not implemented.")
	}
	static sort(list, comp) {
		Fiber.abort("Not implemented.")
	}
	static unpack(list) {
		Fiber.abort("Not implemented.")
	}
	static unpack(list, i) {
		Fiber.abort("Not implemented.")
	}
	static unpack(list, i, j) {
		Fiber.abort("Not implemented.")
	}

	construct new() {
		_length = 0
	}
	construct new(obj) {
		_length = 0

		if (obj is List) {
			for (i in 0...obj.count) {
				this[i + 1] = obj[i] // 1-based.
			}
		} else if (obj is Map) {
			for (kv in obj) {
				this[kv.key] = kv.value
			}
		}
	}

	toString {
		if (len__ == data_.count) {
			var result = ""
			for (i in 1..len__) {
				result = result + data_[i].toString
				if (i != len__) {
					result = result + ", "
				}
			}

			return "{ " + result + " }"
		}

		return data_.toString
	}
	toWren {
		var result = null
		if (count == len__) {
			result = [ ]
			for (i in 0...count) {
				var v = this[i + 1]
				if (v is LTable) {
					v = v.toWren
				}
				result.add(v) // 1-based.
			}
		} else {
			result = { }
			for (kv in this) {
				var k = kv.key
				var v = kv.value
				if (k is LTable) {
					k = k.toWren
				}
				if (v is LTable) {
					v = v.toWren
				}
				result[k] = v
			}
		}

		return result
	}

	data_ {
		if (_data == null) {
			_data = { }
		}

		return _data
	}

	[index] {
		if (data_.containsKey(index)) {
			return data_[index]
		}

		return null
	}
	[index] = (value) {
		if (value == null) {
			if (data_.containsKey(index)) {
				data_.remove(index)
			}
		} else {
			data_[index] = value
			_length = -1
		}
	}

	count {
		return data_.count
	}
	isEmpty {
		return data_.isEmpty
	}
	clear() {
		data_.clear()
	}

	keys {
		return data_.keys
	}
	values {
		return data_.values
	}

	containsKey(key) {
		return data_.containsKey(key)
	}

	len__ {
		if (_length == -1) {
			for (i in 1..data_.count) {
				if (data_.containsKey(i)) {
					_length = i // 1-based.
				} else {
					break
				}
			}
		}

		return _length == -1 ? 0 : _length
	}

	iterate(iterator) {
		iterator = data_.iterate(iterator)

		return iterator
	}
	iteratorValue(iterator) {
		return data_.iteratorValue(iterator)
	}
} // `LTable`.
// Table end.
// Table lib.
// Math lib.
// Math begin.
import "random" for Random

class LMath {
	static abs(x) {
		return x.abs
	}
	static acos(x) {
		return x.acos
	}
	static asin(x) {
		return x.asin
	}
	static atan(y) {
		return y.atan
	}
	static atan(y, x) {
		return y.atan(x)
	}
	static ceil(x) {
		return x.ceil
	}
	static cos(x) {
		return x.cos
	}
	static deg(x) {
		return x / Num.pi * 180
	}
	static exp(x) {
		var e = 2.7182818284590452353602874713527

		return e.pow(x)
	}
	static floor(x) {
		return x.floor
	}
	static fmod(x, y) {
		return x - y * (x / y).floor
	}
	static huge {
		return 1 / 0
	}
	static log(x) {
		return x.log
	}
	static log(x, base) {
		return x.log / base.log
	}
	static max(arg0, arg1) {
		return arg0 > arg1 ? arg0 : arg1
	}
	static max(arg0, arg1, arg2) {
		return max(max(arg0, arg1), arg2)
	}
	static max(arg0, arg1, arg2, arg3) {
		return max(max(max(arg0, arg1), arg2), arg3)
	}
	static max(arg0, arg1, arg2, arg3, arg4) {
		return max(max(max(max(arg0, arg1), arg2), arg3), arg4)
	}
	static max(arg0, arg1, arg2, arg3, arg4, arg5) {
		return max(max(max(max(max(arg0, arg1), arg2), arg3), arg4), arg5)
	}
	static max(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		return max(max(max(max(max(max(arg0, arg1), arg2), arg3), arg4), arg5), arg6)
	}
	static max(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		return max(max(max(max(max(max(max(arg0, arg1), arg2), arg3), arg4), arg5), arg6), arg7)
	}
	static maxInteger {
		Fiber.abort("Not implemented.")
	}
	static min(arg0, arg1) {
		return arg0 < arg1 ? arg0 : arg1
	}
	static min(arg0, arg1, arg2) {
		return min(min(arg0, arg1), arg2)
	}
	static min(arg0, arg1, arg2, arg3) {
		return min(min(min(arg0, arg1), arg2), arg3)
	}
	static min(arg0, arg1, arg2, arg3, arg4) {
		return min(min(min(min(arg0, arg1), arg2), arg3), arg4)
	}
	static min(arg0, arg1, arg2, arg3, arg4, arg5) {
		return min(min(min(min(min(arg0, arg1), arg2), arg3), arg4), arg5)
	}
	static min(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
		return min(min(min(min(min(min(arg0, arg1), arg2), arg3), arg4), arg5), arg6)
	}
	static min(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Supports up to 8 parameters.
		return min(min(min(min(min(min(min(arg0, arg1), arg2), arg3), arg4), arg5), arg6), arg7)
	}
	static minInteger {
		Fiber.abort("Not implemented.")
	}
	static modf(x) {
		if (x < 0) {
			return [ -(-x).floor, x + (-x).floor ]
		}

		return [ x.floor, x - x.floor ]
	}
	static pi {
		return Num.pi
	}
	static pow(x, y) {
		return x.pow(y)
	}
	static rad(x) {
		return x / 180 * Num.pi
	}
	static random {
		if (__random == null) {
			__random = Random.new()
		}

		return __random
	}
	static random() {
		return random.float()
	}
	static random(n) {
		return random(1, n)
	}
	static random(m, n) {
		return random.int(m, n + 1)
	}
	static randomSeed(x) {
		__random = Random.new(x)
	}
	static sin(x) {
		return x.sin
	}
	static sqrt(x) {
		return x.sqrt
	}
	static tan(x) {
		return x.tan
	}
	static toInteger(x) {
		if (x is String) {
			x = Num.fromString(x)
		}
		if (x is Num && x.isInteger) {
			return x
		}

		return null
	}
	static type(x) {
		if (x is Num) {
			if (x.isInteger) {
				return "integer"
			} else {
				return "float"
			}
		}

		return null
	}
	static ult(m, n) {
		Fiber.abort("Not implemented.")
	}
}

class math {
	static huge { LMath.huge }
	static maxInteger { LMath.maxInteger }
	static minInteger { LMath.minInteger }
	static pi { LMath.pi }
}
// Math end.
// Math lib.

class Test {
	static run() {
		runLoop()

		runLib()

		runMath()

		runString()

		runTable()

		runCoroutine()

		System.print("OK")
	}

	static runLoop() {
		var sum = 0

		for (i in LRange.new(1, 3, 1)) {
			sum = sum + i
		}
		assert(sum == 6, "`LRange` error.")
		sum = 0
		for (i in LRange.new(6, 1, -2)) {
			sum = sum + i
		}
		assert(sum == 12, "`LRange` error.")
	}
	static runLib() {
		assert(Lua.toNumber(Lua.toString(42)) == 42, "`Lib` error.")
		assert(Lua.type(null) == "nil", "`Lib` error.")
		assert(Lua.type(22 / 7) == "number", "`Lib` error.")
		assert(Lua.type("hello") == "string", "`Lib` error.")
		assert(Lua.type({ }) == "table", "`Lib` error.")
	}
	static runMath() {
		var eq = Fn.new { | l, r | l == r }

		assert(eq.call(LMath.sin(0.5 * LMath.pi), (0.5 * Num.pi).sin), "`LMath` error.")
		assert(eq.call(LMath.rad(0.5 * 180), 0.5 * Num.pi), "`LMath` error.")
		assert(eq.call(LMath.sqrt(2), 2.sqrt), "`LMath` error.")
		assert(eq.call(LMath.max(1 + 3, 2 * 2, 1.5, -2, 42), 42), "`LMath` error.")
	}
	static runString() {
		assert(LString.lower("HeLlO") == "hello", "`LString` error.")
		assert(LString.upper("HeLlO") == "HELLO", "`LString` error.")
		assert(LString.rep("x", 5) == "xxxxx", "`LString` error.")
		assert(LString.len("hello" + "world") == 10, "`LString` error.")
		assert(LString.byte("hello") == 104, "`LString` error.")
		assert(LString.byte("hello", 2) == 101, "`LString` error.")
		assert(LString.byte("hello", 2, 4).count == 3, "`LString` error.")
		assert(LString.sub("hello", 2, 4) == "ell", "`LString` error.")
	}
	static runTable() {
		var sum = 0
		var txt = ""
		var tbl = null

		tbl = LTable.new(
			{
				1: "uno", 2: "dos", 3: "thres", 4: "cuatro",
				"key": "value"
			}
		)
		tbl[4] = null
		tbl["nil"] = "something"
		tbl["nil"] = null
		assert(tbl.len__ == 3 && tbl.count == 4, "`LTable` error.")

		sum = 0
		txt = ""
		for (t in LIPairs.new(tbl)) {
			var k = t[0]
			var v = t[1]
			sum = sum + k
			txt = txt + v
		}
		assert(sum == 6 && txt.count == 11, "`LIPairs` error.")
		txt = ""
		for (t in LPairs.new(tbl)) {
			var k = t[0]
			var v = tbl[k]
			txt = txt + v
		}
		assert(txt.count == 16, "`LPairs` error.")
	}
	static runCoroutine() {
		var co = LCoroutine.create(
			Fn.new { | n |
				LCoroutine.yield(n + 1)
				LCoroutine.yield(n + 2)
				LCoroutine.yield(n + 3)

				return n + 4
			}
		)

		assert(LCoroutine.resume(co, 42) == LTuple.new(true, 43), "`LCoroutine` error.")
		assert(LCoroutine.resume(co, 42) == LTuple.new(true, 44), "`LCoroutine` error.")
		assert(LCoroutine.resume(co, 42) == LTuple.new(true, 45), "`LCoroutine` error.")
		assert(LCoroutine.resume(co, 42) == LTuple.new(true, 46), "`LCoroutine` error.")
		assert(LCoroutine.resume(co, 42) == LTuple.new(false, "Cannot resume dead coroutine."), "`LCoroutine` error.")
	}

	static assert(cond, msg) {
		if (cond) {
			return
		}
		System.print(msg)
	}
}

Test.run()
