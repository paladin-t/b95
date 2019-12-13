tbl = { 1 = "uno", 2 = "dos", 3 = "thres" }
tbl["key"] = "value"
for k, v in pairs(tbl) do
	print(k, v)
end
print(length(tbl))
