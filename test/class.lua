Base = class(
	{
		new = function ()
		end,

		field0 = 0,
		field1 = 1,

		func0 = function (a, b)
			local c = a / b
			return c
		end,
		func1 = function (self, c, d)
			self['field0'] = c
			self.field1 = d
		end
	}
)

Derived = class(
	{
		new = function()
		end
	},
	Base
)

foo = new(Base)
bar = new(Derived)

foo:func1(1, 2)
bar:func1('1', '2')

print(Base.func0(22, 7))
