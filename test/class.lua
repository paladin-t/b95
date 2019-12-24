Base = class(
	{
		new = function (self)
		end,

		field0 = 0,
		get_field1 = function (self)
			if self._field1 == nil then
				self._field1 = 0
			end

			return self._field1
		end,
		set_field1 = function (self, value)
			self._field1 = value
		end,

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
		new = function (self)
		end
	},
	Base
)

foo = new(Base)
bar = new(Derived)

foo:func1(1, 2)
bar:func1('1', '2')

print(Base.func0(22, 7))
