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
		return LMath.random.float()
	}
	static random(n) {
		return LMath.random(1, n)
	}
	static random(m, n) {
		return LMath.random.int(m, n + 1)
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
