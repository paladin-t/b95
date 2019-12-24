// Utf8 begin.
class LUtf8 {
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
	static charPattern {
		Fiber.abort("Not implemented.")
	}
	static codes(s) {
		return LIPairs.new(LTable.new(s.codePoints))
	}
	static codepoint(s) {
		return codepoint(s, 1)
	}
	static codepoint(s, i) {
		return codepoint(s, i, i)[1]
	}
	static codepoint(s, i, j) {
		return LTable.new(s.codePoints.take(j).skip(i - 1))
	}
	static len(s) {
		return s.count
	}
	static len(s, i) {
		return s.skip(i - 1).count
	}
	static len(s, i, j) {
		return s.take(j).skip(i - 1).count
	}
	static offset(s, n) {
		Fiber.abort("Not implemented.")
	}
	static offset(s, n, i) {
		Fiber.abort("Not implemented.")
	}
}
// Utf8 end.
