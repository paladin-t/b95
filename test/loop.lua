for i = 1, 3 do
	print(i)
end

for i = 1, 6, 2 do
	print(i)
end

for i = 3, 1 do
	print(i)
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

tbl = { 'uno', 'dos', 'thres' }
tbl['key'] = 'value'

for i, v in ipairs(tbl) do
	print(i, v)
end

for k, v in pairs(tbl) do
	print(k, v)
end

k, v = next(tbl, nil)
while k do
	print(k, v)
	k, v = next(tbl, k)
end
