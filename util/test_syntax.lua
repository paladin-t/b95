require 'syntax'

Base = class(
	{
		new = function (self, name)
			self.name = name
		end,

		name = 'Base',
		get_age = function (self)
			return 16
		end,

		bark = function (self)
			print('Hello, I\'m ' .. self.name)
		end
	}
)
Derived = class(
	{
		new = function (self, name)
			self.name = name
		end,

		name = 'Derived',
		age_ = 16,
		get_age = function (self)
			return self.age_
		end,
		set_age = function (self, value)
			self.age_ = value
		end,

		fly = function (self)
			print('I can fly!')
		end
	},
	Base
)

local b = new(Base, 'Bob')
local d = new(Derived, 'David')
b:bark()
d:bark()
d:fly()

print(is(b, Base), is(b, Derived))
print(is(d, Base), is(d, Derived))

print(b.age); b.age = 18; print(b.age)
print(d.age); d.age = 18; print(d.age)

call(function (a, b) print(a / b) end, 22, 7)

print(length({ 1, 2, 3 }))
