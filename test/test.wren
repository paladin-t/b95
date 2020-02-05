import "io" for File
import "meta" for Meta
import "os" for Process

import "../b95" for Lua

var argv = Process.allArguments
var src = File.read(argv[2])
System.print("[%(argv[2])]")

var onreqr = Fn.new { | path, klass |
	return null
}
var onfunc = Fn.new { | module, func |
	return null
}
var lua = Lua.new().onRequire(onreqr).onFunction(onfunc)

var dst = lua.compile(src)
// System.print("[ast]\n%(dst.ast)")
// System.print("[ops]\n%(dst.lines)")
Meta.eval(dst.toString)
