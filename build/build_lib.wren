import "io" for File, FileFlags

var libs = [
	{
		"path": "lib/debug.wren",
		"tag": "// Debug patch.",
		"var": "__debug"
	},
	{
		"path": "lib/tuple.wren",
		"tag": "// Tuple lib.",
		"var": "__tuple"
	},
	{
		"path": "lib/syntax.wren",
		"tag": "// Syntax lib.",
		"var": "__syntax"
	},
	{
		"path": "lib/coroutine.wren",
		"tag": "// Coroutine lib.",
		"var": "__coroutine"
	},
	{
		"path": "lib/string.wren",
		"tag": "// String lib.",
		"var": "__string"
	},
	{
		"path": "lib/table.wren",
		"tag": "// Table lib.",
		"var": "__table"
	},
	{
		"path": "lib/math.wren",
		"tag": "// Math lib.",
		"var": "__math"
	}
]

var embed = Fn.new { | src, lib |
	var code = File.read(lib["path"])
	var begin = src.indexOf(lib["tag"])
	var end = src.indexOf(lib["tag"], begin + 1)
	var head = src.take(begin + lib["tag"].count).join("") + "\r\n"
	var tail = src.skip(end).join("")

	return head + code + tail
}

// Embeds './lib/*.wren' into './test/test_lib.wren'.
var src = File.read("test/test_lib.wren")
libs.each(
	Fn.new { | lib |
		var n = "\"" + lib["path"] + "\""
		System.print("Embed library %(n).")

		src = embed.call(src, lib)
	}
)
File.openWithFlags(
	"test/test_lib.wren", FileFlags.writeOnly | FileFlags.create | FileFlags.truncate,
	Fn.new { | file |
		file.writeBytes(src)
	}
)
