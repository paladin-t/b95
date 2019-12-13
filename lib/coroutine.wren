// Coroutine begin.
class LCoroutine {
	static temporary {
		var result = __temporary
		__temporary = null

		return result
	}
	static temporary = (value) {
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
		temporary = null

		return LTuple.new(true, co.call())
	}
	static resume(co, arg0) {
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary = arg0

		return LTuple.new(true, co.call(arg0))
	}
	static resume(co, arg0, arg1) {
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary = LTuple.new(arg0, arg1)

		return LTuple.new(true, co.call([ arg0, arg1 ]))
	}
	static resume(co, arg0, arg1, arg2) {
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary = LTuple.new(arg0, arg1, arg2)

		return LTuple.new(true, co.call([ arg0, arg1, arg2 ]))
	}
	static resume(co, arg0, arg1, arg2, arg3) { // Now supports up to 4 parameters.
		if (co.isDone) {
			return LTuple.new(false, "Cannot resume dead coroutine.")
		}
		temporary = LTuple.new(arg0, arg1, arg2, arg3)

		return LTuple.new(true, co.call([ arg0, arg1, arg2, arg3 ]))
	}
	static yield() {
		Fiber.yield()

		return temporary
	}
	static yield(arg0) {
		Fiber.yield(arg0)

		return temporary
	}
	static yield(arg0, arg1) {
		Fiber.yield(LTuple.new(arg0, arg1))

		return temporary
	}
	static yield(arg0, arg1, arg2) {
		Fiber.yield(LTuple.new(arg0, arg1, arg2))

		return temporary
	}
	static yield(arg0, arg1, arg2, arg3) { // Now supports up to 4 parameters.
		Fiber.yield(LTuple.new(arg0, arg1, arg2, arg3))

		return temporary
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
