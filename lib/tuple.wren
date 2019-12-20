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
