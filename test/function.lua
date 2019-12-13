function fib(n)
	if n <= 1 then
		return n
	else
		return fib(n - 1) + fib(n - 2)
	end
end

n = 10
for i = 0, 10 do
	print(fib(i))
end
