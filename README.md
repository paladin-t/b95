## B95

**A [Lua](http://www.lua.org/) to [Wren](http://wren.io/) compiler in Wren**

This library was born from the idea of using Lua in Wren project. There are not many ways possible:

Making both Lua and Wren bindings at the native side. Requires extra coding; cannot use Wren objects from Lua, vice versa.

Compiling Lua code to an intermediate denotion, then running it at the scripting side. Slow.

Compiling Lua code to Wren VM instructions, then running it on the VM. Need to stick tightly to specific version of Wren implementation.

Compiling Lua code to Wren source code, then running it through Wren. Why not.

### 1. How it works

Lua's dynamic typing and scripting nature is quite similar to Wren. So the typing system, execution flow and memory management parts can be straightforward migrated. The main difference is that Wren uses a classy object model, but Lua uses prototyping. Anyway, it's still translatable with a little bit wrought work.

#### 1.1 Syntax translation

**Multiple assignment**

B95 introduced an internal tuple helper for multiple assignment. Eg.

```lua
a, b = b, a
```

compiles to

```dart
var tmp_0 = LTuple.new(b, a)
a = tmp_0[0]
b = tmp_0[1]
```

Note: to unpack values properly from a tuple returned by some functions (eg. `coroutine.yield`), add an extra variable on the left side of assign operator to hint tuple unpacking. Eg. `_` in `somevar, _ = coroutine.yield(1, 2)`. Otherwise a single variable would get returned tuple object per se.

**Function definition**

`function func() end` in class compiles to `static func() { }`.

`function func(self) end` in class compiles to `func() { }`.

`function func() end` compiles to `func = Fn.new { | | }`.

`function () end` compiles to `Fn.new { | | }`.

**Function call**

`Kls.func()` compiles to `Kls.func()`.

`obj:func()` compiles to `obj.func()`.

`obj.func()` compiles to `obj.func()`.

Otherwise eg. with `obj['func']()`, compiles to `obj['func'].call()`.

Note: use `call(func, args)` to hint for `func.call(args)`; `apply(method, args)` to hint for `method(args)`.

#### 1.2 Library port

Lua standard library is rewritten in Wren for B95's referencing. The source code of the port is in the "[lib](lib)" directory, and has been already built by "[build/build.wren](build/build.wren)", so generally you do not need to build it manually.

#### 1.3 External registration

Like widespread scripting languages, B95 allows using external function registration to extend the language.

### 2. How to use

"[b95.wren](b95.wren)" is the only file of this compiler, just copy it to your project. B95 is close to the original Lua, such as table is used for anything complex, array starts from 1, etc. Moreover, B95 offers more natural class.

#### 2.1 Dependency

Wren 0.2.0 or above.

There's a Windows executable "wren.exe" in the root directory of this repository, which was prebuilt via VC++ 2015 without modification to the official distribution.

#### 2.2 Simple

```dart
import "b95" for B95

var b95 = B95.new()
var code = b95.compile("print('hello')")
System.print(code.lines)
```

#### 2.3 Eval it

```dart
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
Klass = class(
  {
    -- Constructor `new` compiles to `construct new()`.
    new = function (self)
    end,

    -- Compiles to Wren getter/setter.
    field0 = 0,
    field1 = 1,

    -- Function without `self` compiles to static method.
    func0 = function (a, b)
      local c = a / b

      return c
    end,

    -- Function with `self` compiles to instance method.
    func1 = function (self, c, d)
      self['field0'] = c
      self.field1 = d
    end
  },
  base -- Base class, optional.
)

obj = new(Klass) -- Instantiate a class, compiles to `Klass.new()`.
```

This is also valid Lua syntax, so that it's possible to write compatible code both in B95 and (with the help of "[util/syntax.lua](util/syntax.lua)") in C-LUA.

#### 2.5 Table

```lua
tbl = { 'uno', 'dos', 'thres' }
tbl['key'] = 'value'

for k, v in pairs(tbl) do
  print(k, v)
end

print(length(tbl))
```

#### 2.6 Importing

```lua
obj = require 'path'
```

B95 invokes callback set by `B95.onRequire` during compile time for customized importing. Eg.

```dart
b95.onRequire(
  Fn.new { | path, klass |
    if (path == "bar" && klass == "foo") {
      return "import \"path\" for module" // This replaces matched requirement.
    }

    return null
  }
)
```

#### 2.7 Registering

B95 invokes callback set by `B95.onFunction` during compile time for customized functions. Eg.

```dart
b95.onFunction(
  Fn.new { | module, func |
    if (module == "foo" && func == "bar") {
      return { "lib": null, "function": "lib.func" } // This replaces function invoking.
    }

    return null
  }
)
```

### 3. Feature list

| Syntax | Lua | B95 |
|----|----|----|
| `and`, `or`, `not` | ✓ | ✓ |
| `local` | ✓ | ✓ |
| `false`, `true` | ✓ | ✓ |
| `nil` | ✓ | ✓ |
| `if-then-elseif-else-end` | ✓ | ✓ |
| `do-end` | ✓ | ✓ |
| `for-do-end` | ✓ | ✓ |
| `for-in-do-end` | ✓ | ✓ |
| `while-do-end` | ✓ | ✓ |
| `repeat-until` | ✓ | ✓ |
| `break` | ✓ | ✓ |
| `function` | ✓ | ✓ |
| `return` | ✓ | ✓ |
| `goto` | ✓ | |
| `__add`, `__sub`, `__mul`, `__div`, `__mod` | ✓ | ✓ |
| `__unm` | ✓ | ✓ |
| `__idiv` | ✓ | |
| `__pow` | ✓ | |
| `__band` | ✓ | ✓ |
| `__bor` | ✓ | ✓ |
| `__bxor` | ✓ | ✓ |
| `__bnot` | ✓ | |
| `__shl`, `__shr` | ✓ | ✓ |
| `__concat` | ✓ | ✓ |
| `__len` | ✓ | |
| `__eq`, `__lt`, `__le` | ✓ | ✓ |
| `__index` | ✓ | |
| `__newindex` | ✓ | |
| `__call` | ✓ | |
| `=` | ✓ | ✓ |
| `+`, `-`, `*`, `/`, `%` | ✓ | ✓ |
| `//` | ✓ | |
| `^` | ✓ | |
| `&` | ✓ | ✓ |
| `|` | ✓ | ✓ |
| `~` | ✓ | ✓ (binary XOR only) |
| `<<`, `>>` | ✓ | ✓ |
| `#` | ✓ | |
| `==`, `~=`, `<=`, `>=`, `<`, `>` | ✓ | ✓ |
| `..` | ✓ | ✓ |
| `...` | ✓ | |
| `-- comment` | ✓ | ✓ |
| `--[[ multiline`<br />`comment --]]` | ✓ | ✓ |
| `require` | ✓ | ✓ |
| `class` | | ✓ |
| `new` | | ✓ |
| `is` | | ✓ |

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
| `next(table [, index])` | ✓ | ✓ (not recommended) |
| `pairs(t)` | ✓ | ✓ |
| `pcall(f [, arg1, ...])` | ✓ | |
| `print(...)` | ✓ | ✓ |
| `rawequal(v1, v2)` | ✓ | ✓ |
| `rawget(table, index)` | ✓ | ✓ |
| `rawlen(v)` | ✓ | ✓ |
| `rawset(table, index, value)` | ✓ | ✓ |
| `select(index, ...)` | ✓ | ✓ (partial) |
| `setmetatable(table, metatable)` | ✓ | |
| `tonumber(e [, base])` | ✓ | ✓ (partial) |
| `tostring(v)` | ✓ | ✓ |
| `type(v)` | ✓ | ✓ |
| `coroutine.create(f)` | ✓ | ✓ |
| `coroutine.isyieldable()` | ✓ | ✓ |
| `coroutine.resume(co [, val1, ...])` | ✓ | ✓ |
| `coroutine.running()` | ✓ | ✓ |
| `coroutine.status(co)` | ✓ | |
| `coroutine.wrap(f)` | ✓ | |
| `coroutine.yield(...)` | ✓ | ✓ |
| `string.byte(s [, i [, j]])` | ✓ | ✓ |
| `string.char(...)` | ✓ | ✓ |
| `string.dump(function [, strip])` | ✓ | |
| `string.find(s, pattern [, init [, plain]])` | ✓ | |
| `string.format(formatstring, ...)` | ✓ | |
| `string.gmatch(s, pattern)` | ✓ | |
| `string.gsub(s, pattern, repl [, n])` | ✓ | |
| `string.len(s)` | ✓ | ✓ |
| `string.lower(s)` | ✓ | ✓ |
| `string.match(s, pattern [, init])` | ✓ | |
| `string.pack(fmt, v1, v2, ...)` | ✓ | |
| `string.packsize(fmt)` | ✓ | |
| `string.rep(s, n [, sep])` | ✓ | ✓ |
| `string.reverse(s)` | ✓ | ✓ |
| `string.sub(s, i [, j])` | ✓ | ✓ |
| `string.unpack(fmt, s [, pos])` | ✓ | |
| `string.upper(s)` | ✓ | ✓ |
| `utf8` | ✓ | |
| `table.concat(list [, sep [, i [, j]]])` | ✓ | ✓ |
| `table.insert(list, [pos,] value)` | ✓ | ✓ |
| `table.move(a1, f, e, t [, a2])` | ✓ | |
| `table.pack(...)` | ✓ | |
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
| `math.max(x, ...)` | ✓ | ✓ |
| `math.maxinteger` | ✓ | |
| `math.min(x, ...)` | ✓ | ✓ |
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
