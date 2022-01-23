E2Lib.RegisterExtension("PNG", true, "PNG E2 Core")

local PNG = include("png.lua")

E2Lib.registerConstant( "PNG_RGB", PNG.RGB )
E2Lib.registerConstant( "PNG_RGBA", PNG.RGBA )

registerType("png", "xpn", nil, nil, nil,
	function(ret)
		if not istable(ret) then return end
		if not PNG.instanceof(ret) then
			error("Return value is neither nil nor a PNG, but a %s!", type(ret))
		end
	end,
	PNG.instanceof
)

local floor = math.floor

local exception = E2Lib.raiseException
local function assertE2(condition, msg, trace)
	if not condition then exception(msg, nil, trace) end
end

__e2setcost(1)
e2function webaudio operator=(png lhs, png rhs) -- Wa = webAudio("...") (Rip Coroutine Core comments)
	local scope = self.Scopes[ args[4] ]
	scope[lhs] = rhs
	scope.vclk[lhs] = true
	return rhs
end

e2function number operator==(png lhs, png rhs) -- if(webAudio("...")==Wa)
	return lhs == rhs
end

e2function number operator!=(png lhs, png rhs) -- if(Wa!=Wa)
	return lhs ~= rhs
end

e2function number operator_is(png img)
	return IsValid(img) and 1 or 0
end

__e2setcost(40)
e2function png png(number width, number height, number mode)
	assertE2(mode == PNG.RGB or mode == PNG.RGBA, "Invalid color mode. Use _PNG_RGB or _PNG_RGBA", self.trace)
	assertE2(width > 0 and height > 0, "Invalid size. Width and height must be greater than 0.", self.trace)
	assertE2(width < 2048 and height < 2048, "Invalid size. Width and height must be less than 2048.", self.trace)

	return PNG.new(width, height, mode)
end

__e2setcost(3)
e2function void png:writeVector(vector v)
	---@type PNG
	local this = this
	assertE2(not this.done, "PNG is already done!", self.trace)

	this:write(v)
end

e2function void png:writeVector4(vector v)
	---@type PNG
	local this = this
	assertE2(not this.done, "PNG is already done!", self.trace)

	this:write(v)
end

e2function void png:write(number r, number g, number b)
	---@type PNG
	local this = this

	if this.type == PNG.RGB then
		this:write { r, g, b }
	else
		this:write { r, g, b, 255 }
	end
end

__e2setcost(5)
e2function void png:write(number r, number g, number b, number a)
	---@type PNG
	local this = this
	assertE2(not this.done, "PNG is already done!", self.trace)

	if this.type == PNG.RGBA then
		this:write { r, g, b }
	else
		this:write { r, g, b, a }
	end
end

__e2setcost(10)
e2function string png:output()
	return table.concat(this.output)
end

__e2setcost(1)
e2function number png:done()
	return this.done and 1 or 0
end