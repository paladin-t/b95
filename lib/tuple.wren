// Tuple begin.
class LTuple {
	construct new() {
		_args = [ ]
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
	construct new(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) { // Now supports up to 8 parameters.
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

	count {
		return _args.count
	}

	join(sep) {
		return _args.join(sep)
	}
}
// Tuple end.
