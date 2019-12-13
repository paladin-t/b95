n = 99999

x = n * 2 - 1
a = 1 - 1 / 3
w = (x - 5) / 2 + 1
u = 0
v = 100 / w

for y = 5, x, 2 do
	iy = (y - 1) / 4
	iy = math.floor(iy)
	if iy == (y - 1) / 4 then
		a = a + 1 / y
	else
		a = a - 1 / y
	end
	u = u + v
end
a = a * 4

print("Pi = ", a)
