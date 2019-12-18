tbl = { 'uno', 'dos', 'thres' }
tbl['key'] = 'value'
for k, v in pairs(tbl) do
	print(k, v)
end
print(length(tbl))
