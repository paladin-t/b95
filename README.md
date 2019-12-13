## B95

**A [Lua](http://www.lua.org/) to [Wren](http://wren.io/) compiler in Wren**

This library was born from the idea of using Lua in a Wren project. There are not many ways possible:

Making both Lua and Wren bindings at the native side. Requires extra coding; cannot use Wren objects from Lua, vice versa.

Compiling Lua code to an intermediate denotion, then running it at the scripting side. Slow.

Compiling Lua code to Wren VM instructions, then running it on the VM. Need to stick tightly to specific version of Wren implementation.

Compiling Lua code to Wren source code, then running it through Wren. Why not.

### 1. How it works

Wren's dynamic typing and scripting nature is quite similar to Lua. The typing system, execution flow and memory management part can be straightforward migrated. The main difference is that Wren uses a classy object model, Lua uses prototyping. But it's still translatable with a little bit wrought work.

#### 1.1 Syntax translation

**Multi assignment**

B95 introduced an internal helper tuple for multi assignment. Eg.

```lua
a, b = b, a
```

compiles to

```wren
var tmp_0 = LTuple.new(b, a)
a = tmp_0[0]
b = tmp_0[1]
```

Note: to unpack proper values of a tuple returned by some functions (eg. `coroutine.yield`), add an extra variable on the left side of assign operator to hint a tuple unpacking. Eg. `dummy` in `somevar, dummy = coroutine.yield(1, 2)`. Otherwise a single variable gets tuple object.

**Function definition**

`function func() end` in class compiles to `static func() { }`.

`function func(self) end` in class compiles to `func() { }`.

`function func() end` compiles to `func = Fn.new { | | }`.

`function () end` compiles to `Fn.new { | | }`.

**Function call**

`Kls.func()` compiles to `Kls.func()`.

`obj:func()` compiles to `obj.func()`.

`obj.func()` compiles to `obj.func.call()`.

Otherwise eg. with `obj["func"]()`, compiles to `obj.func.call()`.

Note: use `call(func, args)` to hint for `func.call(args)`.

#### 1.2 Library port

Lua standard library is ported to Wren for B95's referencing. The source code of the port is in the "[lib](lib)" directory, and has been already built by "[build/build.wren](build/build.wren)", so generally you do not need to build it manually.

#### 1.3 External registration

Like many scripting languages, B95 allows external function registration to extend the language.

### 2. How to use

"[b95.wren](b95.wren)" is the only file of this compiler, just copy it to your project.

#### 2.1 Dependency

Wren 0.2.0 or above.

There's a Windows executable "wren.exe" in the root directory of this repository, which was prebuilt via VC++ 2015 without modification to the official code.

#### 2.2 Simple

```wren
import "b95" for B95

var b95 = B95.new()
var code = b95.compile("print('hello')")
System.print(code.lines)
```

#### 2.3 Eval it

```wren
import "io" for File
import "meta" for Meta
import "b95" for B95

var b95 = B95.new()
var code = b95.compile(File.read("tests/hello.lua"))
System.print(code.lines)
Meta.eval(code.toString)
```

See `class Code` in "[b95.wren](b95.wren)" for details of the returned object by `B95.compile`.

#### 2.4 Class

```lua
clz = class(
	{
		-- class body.
	} [, base]
)
obj = new(clz)
```

This is also valid Lua syntax, so that it's possible to write compatible code for both B95 and C-Lua.

#### 2.5 Table

```lua
tbl = { 1 = "uno", 2 = "dos", 3 = "thres" }
tbl["key"] = "value"
for k, v in pairs(tbl) do
	print(k, v)
end
print(length(tbl))
```

#### 2.6 Importing

```lua
obj = require "path"
```

B95 invokes callback set by `B95.onRequire` during compiling for customized importing.

#### 2.7 Registering

B95 invokes callback set by `B95.onFunction` during compiling for customized functions.

### 3. Feature list

| Syntax | Lua | B95 |
|----|----|----|
| `and`, `or`, `not` | ✓ | ✓ |
| `if-then-elseif-else-end` | ✓ | ✓ |
| `do-end` | ✓ | ✓ |
| `for-do-end` | ✓ | ✓ |
| `for-in-do-end` | ✓ | ✓ |
| `while-do-end` | ✓ | ✓ |
| `repeat-until` | ✓ | ✓ |
| `break` | ✓ | ✓ |
| `function` | ✓ | ✓ |
| `return` | ✓ | ✓ |
| `local` | ✓ | ✓ |
| `false`, `true`, `nil` | ✓ | ✓ |
| `goto` | ✓ | |
| `__add`, `__sub`, `__mul`, `__div`, `__mod` | ✓ | ✓ |
| `__pow`, `__unm`, `__idiv` | ✓ | |
| `__band`, `__bor`, `__bxor`, `__bnot` | ✓ | |
| `__shl`, `__shr` | ✓ | |
| `__concat`, `__len` | ✓ | |
| `__eq`, `__lt`, `__le` | ✓ | ✓ |
| `__index` | ✓ | |
| `__newindex` | ✓ | |
| `__call` | ✓ | |
| `=`, `+`, `-`, `*`, `/`, `%` | ✓ | ✓ |
| `^` | ✓ | |
| `#` | ✓ | |
| `//` | ✓ | |
| `==`, `~=`, `<=`, `>=`, `<`, `>` | ✓ | ✓ |
| `&`, `~`, `<<`, `>>` | ✓ | ✓ |
| `-- comment` | ✓ | ✓ |
| `--[[ multiline`<br />`comment --]]` | ✓ | ✓ |
| `require` | ✓ | ✓ |
| `class`, `is` | | ✓ |

| Lib | Lua | B95 |
|----|----|----|
| `assert(v [, message])` | ✓ | ✓ |
| `collectgarbage([opt [, arg]])` | ✓ | ✓ |
| `dofile([filename])` | ✓ | |
| `error(message [, level])` | ✓ | ✓ |
| `getmetatable(object)` | ✓ | |
| `ipairs(t)` | ✓ | ✓ |
| `load(chunk [, chunkname [, mode [, env]]])` | ✓ | |
| `loadfile([filename [, mode [, env]]])` | ✓ | |
| `next(table [, index])` | ✓ | |
| `pairs(t)` | ✓ | ✓ |
| `pcall(f [, arg1, ···])` | ✓ | |
| `print(···)` | ✓ | ✓ |
| `rawequal(v1, v2)` | ✓ | ✓ |
| `rawget(table, index)` | ✓ | ✓ |
| `rawlen(v)` | ✓ | ✓ |
| `rawset(table, index, value)` | ✓ | ✓ |
| `select(index, ···)` | ✓ | |
| `setmetatable(table, metatable)` | ✓ | |
| `tonumber(e [, base])` | ✓ | ✓ (partial) |
| `tostring(v)` | ✓ | ✓ |
| `type(v)` | ✓ | ✓ |
| `coroutine.create(f)` | ✓ | ✓ |
| `coroutine.isyieldable()` | ✓ | ✓ |
| `coroutine.resume(co [, val1, ···])` | ✓ | ✓ |
| `coroutine.running()` | ✓ | ✓ |
| `coroutine.status(co)` | ✓ | |
| `coroutine.wrap(f)` | ✓ | |
| `coroutine.yield(···)` | ✓ | ✓ |
| `string.byte(s [, i [, j]])` | ✓ | ✓ |
| `string.char(···)` | ✓ | ✓ |
| `string.dump(function [, strip])` | ✓ | |
| `string.find(s, pattern [, init [, plain]])` | ✓ | |
| `string.format(formatstring, ···)` | ✓ | |
| `string.gmatch(s, pattern)` | ✓ | |
| `string.gsub(s, pattern, repl [, n])` | ✓ | |
| `string.len(s)` | ✓ | ✓ |
| `string.lower(s)` | ✓ | ✓ |
| `string.match(s, pattern [, init])` | ✓ | |
| `string.pack(fmt, v1, v2, ···)` | ✓ | |
| `string.packsize(fmt)` | ✓ | |
| `string.rep(s, n [, sep])` | ✓ | ✓ |
| `string.reverse(s)` | ✓ | ✓ |
| `string.sub(s, i [, j])` | ✓ | ✓ |
| `string.unpack(fmt, s [, pos])` | ✓ | |
| `string.upper(s)` | ✓ | ✓ |
| `utf8` | ✓ | |
| `table.concat(list [, sep [, i [, j]]])` | ✓ | ✓ |
| `table.insert(list, [pos,] value)` | ✓ | ✓ |
| `table.move(a1, f, e, t [,a2])` | ✓ | |
| `table.pack(···)` | ✓ | |
| `table.remove(list [, pos])` | ✓ | ✓ |
| `table.sort(list [, comp])` | ✓ | |
| `table.unpack(list [, i [, j]])` | ✓ | |
| `math.abs(x)` | ✓ | ✓ |
| `math.acos(x)` | ✓ | ✓ |
| `math.asin(x)` | ✓ | ✓ |
| `math.atan(y [, x])` | ✓ | ✓ |
| `math.ceil(x)` | ✓ | ✓ |
| `math.cos(x)` | ✓ | ✓ |
| `math.deg(x)` | ✓ | ✓ |
| `math.exp(x)` | ✓ | ✓ |
| `math.floor(x)` | ✓ | ✓ |
| `math.fmod(x, y)` | ✓ | ✓ |
| `math.huge` | ✓ | ✓ |
| `math.log(x [, base])` | ✓ | ✓ |
| `math.max(x, ···)` | ✓ | ✓ |
| `math.maxinteger` | ✓ | |
| `math.min(x, ···)` | ✓ | ✓ |
| `math.mininteger` | ✓ | |
| `math.modf(x)` | ✓ | ✓ |
| `math.pi` | ✓ | ✓ |
| `math.rad(x)` | ✓ | ✓ |
| `math.random([m [, n]])` | ✓ | ✓ |
| `math.randomseed(x)` | ✓ | ✓ |
| `math.sin(x)` | ✓ | ✓ |
| `math.sqrt(x)` | ✓ | ✓ |
| `math.tan(x)` | ✓ | ✓ |
| `math.tointeger(x)` | ✓ | ✓ |
| `math.type(x)` | ✓ | ✓ |
| `math.ult(m, n)` | ✓ | |
| `io` | ✓ | |
| `file` | ✓ | |
| `os` | ✓ | |
| `debug` | ✓ | |

### 4. Who is B95

He is a [bird](https://en.wikipedia.org/wiki/B95_(bird)).
