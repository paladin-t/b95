import "io" for File
import "meta" for Meta
import "os" for Process

import "../b95" for B95

var argv = Process.allArguments
var src = File.read(argv[2])
System.print("[%(argv[2])]")

var onreqr = Fn.new { | path, klass |
	return null
}
var onfunc = Fn.new { | module, func |
	return null
}
var b95 = B95.new().onRequire(onreqr).onFunction(onfunc)

var dst = b95.compile(src)
// System.print("[ast]\n%(dst.ast)")
// System.print("[ops]\n%(dst.lines)")
Meta.eval(dst.toString)
