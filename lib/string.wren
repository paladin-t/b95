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
