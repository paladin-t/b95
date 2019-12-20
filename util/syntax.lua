function class(kls, base)
	if not base then
		base = { }
	end
	kls.__index = function (self, key)
		local get = function (this, key)
			local t = rawget(this, key)
			if t then return t end

			t = kls[key]
			if t then return t end

			return base[key]
		end

		local t = get(self, 'get_' .. key)
		if t then return t(self) end

		return get(self, key)
	end
	kls.__newindex = function (self, key, value)
		local t = rawget(self, 'set_' .. key)
		if t then return t(self, value) end

		rawset(self, key, value)
	end
	setmetatable(kls, base)

	return kls
end

function new(kls, ...)
	local obj = { }
	setmetatable(obj, kls)
	obj:new(...)

	return obj
end

function is(obj, kls)
	repeat
		if obj == kls then
			return true
		end
		obj = getmetatable(obj)
	until not obj

	return false
end

function call(fn, ...)
	return fn(...)
end

function length(obj)
	return #obj
end
