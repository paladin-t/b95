do
	local i = 0

	function inc()
		i = i + 1

		return i
	end

	function dec()
		i = i - 1

		return i
	end

	print(inc())
	print(dec())
end
