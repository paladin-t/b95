co = coroutine.create(
	function (value1, value2)
		local tempvar1, tempvar2, tempvar3

		tempvar3 = 10
		print('Coroutine section 1', value1, value2, tempvar3)

		tempvar1, _ = coroutine.yield(value1 + 1, value2 + 1)
		tempvar3 = tempvar3 + value1
		print('Coroutine section 2', tempvar1, tempvar2, tempvar3)

		tempvar1, tempvar2 = coroutine.yield(value1 + value2, value1 - value2)
		tempvar3 = tempvar3 + value1
		print('Coroutine section 3', tempvar1, tempvar2, tempvar3)

		return value2, 'end'
	end
)

print('main', coroutine.resume(co, 3, 2))
print('main', coroutine.resume(co, 12, 14))
print('main', coroutine.resume(co, 5, 6))
print('main', coroutine.resume(co, 10, 20))

--[[
Expected:
  coroutine section 1	3	2	10
  main	true	4	3
  coroutine section 2	12	nil	13
  main	true	5	1
  coroutine section 3	5	6	16
  main	true	2	end
  main	false	cannot resume dead coroutine
--]]
