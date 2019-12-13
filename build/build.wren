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
	code = code.replace("\\\"", "__squote__").replace("\"", "\\\"").replace("__squote__", "\\\\\\\"") // Escapes.
	code = code.replace("\t", "  ") // Indent with space.
	var lns = code.split("\r\n")
	if (lns[lns.count - 1] == "") {
		lns = lns.take(lns.count - 1)
	}
	code = "\t\t\t" + lib["var"] + " = \"\" +\r\n"
	code = code + lns.map(Fn.new { | ln | "\t\t\t\t\"" + ln + "\\r\\n\"" }).join(" +\r\n")

	var begin = src.indexOf(lib["tag"])
	var end = src.indexOf(lib["tag"], begin + 1)
	var head = src.take(begin + lib["tag"].count).join("") + "\r\n"
	var tail = " " + src.skip(end).join("")

	return head + code + tail
}

// Embeds './lib/*.wren' into './b95.wren'.
var src = File.read("b95.wren")
libs.each(
	Fn.new { | lib |
		var n = "\"" + lib["path"] + "\""
		System.print("Embed library %(n).")

		src = embed.call(src, lib)
	}
)
File.openWithFlags(
	"b95.wren", FileFlags.writeOnly | FileFlags.create | FileFlags.truncate,
	Fn.new { | file |
		file.writeBytes(src)
	}
)
