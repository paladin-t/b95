// Table begin.
class LTable {
	static concat(list) {
		return LTable.concat(list, "")
	}
	static concat(list, sep) {
		return LTable.concat(list, sep, 1)
	}
	static concat(list, sep, i) {
		return LTable.concat(list, sep, i, list.len__)
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
		return LTable.insert(list, list.len__ + 1, value)
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
		return LTable.remove(list, list.len__)
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
		if (len__ == raw_.count) {
			var result = ""
			for (i in 1..len__) {
				result = result + raw_[i].toString
				if (i != len__) {
					result = result + ", "
				}
			}

			return "{ " + result + " }"
		}

		return raw_.toString
	}

	raw_ {
		if (_raw == null) {
			_raw = { }
		}

		return _raw
	}

	[index] {
		if (raw_.containsKey(index)) {
			return raw_[index]
		}

		return null
	}
	[index] = (value) {
		if (value == null) {
			if (raw_.containsKey(index)) {
				raw_.remove(index)
			}
		} else {
			raw_[index] = value
			_length = -1
		}
	}

	count { raw_.count }

	len__ {
		if (_length == -1) {
			for (i in 1..raw_.count) {
				if (raw_.containsKey(i)) {
					_length = i // 1-based.
				} else {
					break
				}
			}
		}

		return _length == -1 ? 0 : _length
	}

	iterate(iterator) {
		iterator = raw_.iterate(iterator)

		return iterator
	}
	iteratorValue(iterator) {
		return raw_.iteratorValue(iterator)
	}
} // `LTable`.
// Table end.
