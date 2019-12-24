print(utf8.len('你好'))
for i, v in utf8.codes('你好') do
	print(i, v)
end
print(utf8.codepoint('hello'))
print(utf8.codepoint('hello', 2))
print(utf8.codepoint('hello', 2, 4))
