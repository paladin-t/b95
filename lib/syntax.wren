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
	static select(index, arg0) {
		Fiber.abort("Not implemented.")
	}
	static select(index, arg0, arg1) {
		Fiber.abort("Not implemented.")
	}
	static select(index, arg0, arg1, arg2) {
		Fiber.abort("Not implemented.")
	}
	static select(index, arg0, arg1, arg2, arg3) {
		Fiber.abort("Not implemented.")
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
