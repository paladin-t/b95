@echo off
call wren.exe test\test.wren test/hello.lua
call wren.exe test\test.wren test/block.lua
call wren.exe test\test.wren test/loop.lua
call wren.exe test\test.wren test/condition.lua
call wren.exe test\test.wren test/function.lua
call wren.exe test\test.wren test/class.lua
call wren.exe test\test.wren test/lib.lua
call wren.exe test\test.wren test/math.lua
call wren.exe test\test.wren test/string.lua
call wren.exe test\test.wren test/table.lua
call wren.exe test\test.wren test/coroutine.lua
echo Ready!
