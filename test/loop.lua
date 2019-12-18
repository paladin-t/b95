for i = 1, 3 do
	print(i)
end

for i = 1, 6, 2 do
	print(i)
end

for i = 3, 1 do
	print(i)
end

for i, v in ipairs({ 1 = 'uno', 2 = 'dos', 3 = 'thres', 'key' = 'value' }) do
	print(i, v)
end

for k, v in pairs({ 1 = 'uno', 2 = 'dos', 3 = 'thres', 'key' = 'value' }) do
	print(k, v)
end

i = 3
while i >= 1 do
	print(i)
	i = i - 1
end

i = 1
repeat
	print(i)
	i = i + 1
	if i > 3 then
		break
	end
until false
