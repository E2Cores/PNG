E2Lib.RegisterExtension("PNG", true, "PNG E2 Core")

---@type PNG
local PNG = include("libpng.lua")

local MaxRes = CreateConVar("e2_pngcore_max_res", tostring(2048 ^ 2), nil, "Maximum resolution allowed to create an E2 PNG with (default 2048^2).")

E2Lib.registerConstant( "PNG_RGB", PNG.RGB )
E2Lib.registerConstant( "PNG_RGBA", PNG.RGBA )

registerType("png", "xpn", nil, nil, nil,
	function(ret)
		if not istable(ret) then return end
		if not PNG.instanceof(ret) then
			error("Return value is neither nil nor a PNG, but a " .. type(ret) .. "!")
		end
	end,
	PNG.instanceof
)

local exception = E2Lib.raiseException
local function assertE2(condition, msg, trace)
	if not condition then exception(msg, nil, trace) end
end

__e2setcost(1)
registerOperator("ass", "xpn", "xpn", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

registerOperator("eq", "xpnxpn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local v1, v2 = op1[1](self, op1), op2[1](self, op2)
	if v1 == v2 then return 1 else return 0 end
end)

registerOperator("neq", "xpnxpn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local v1, v2 = op1[1](self, op1), op2[1](self, op2)
	if v1 ~= v2 then return 1 else return 0 end
end)

registerOperator("is", "xpn", "n", function(self, args)
	local op1 = args[2]
	local v1 = op1[1](self, op1)
	if IsValid(v1) then return 1 else return 0 end
end)

__e2setcost(40)
registerFunction("png", "nnn", "xpn", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local width, height, mode = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	assertE2(mode == PNG.RGB or mode == PNG.RGBA, "Invalid color mode. Use _PNG_RGB or _PNG_RGBA", self.trace)
	assertE2(width > 0 and height > 0, "Invalid size. Width and height must be greater than 0.", self.trace)

	local max_res = MaxRes:GetInt()
	assertE2((width * height) <= max_res, "Invalid size" .. width * height .. ". Maximum combined is " .. max_res, self.trace)

	return PNG.new(width, height, mode)
end)

__e2setcost(3)
registerFunction("writeVector", "xpn:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local this, vec = op1[1](self, op1), op2[1](self, op2)

	assertE2(not this.done, "PNG is already done!", self.trace)
	this:write(vec)
end)

registerFunction("writeVector4", "xpn:v4", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local this, vec = op1[1](self, op1), op2[1](self, op2)

	assertE2(not this.done, "PNG is already done!", self.trace)
	this:write(vec)
end)

registerFunction("write", "xpn:nnn", "", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local this, r, g, b = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)

	assertE2(not this.done, "PNG is already done!", self.trace)

	if this.type == PNG.RGB then
		this:write { r, g, b }
	else
		this:write { r, g, b, 255 }
	end
end)

__e2setcost(5)
registerFunction("write", "xpn:nnnn", "", function(self, args)
	local op1, op2, op3, op4, op5 = args[2], args[3], args[4], args[5], args[6]
	local this, r, g, b, a = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4), op5[1](self, op5)

	assertE2(not this.done, "PNG is already done!", self.trace)

	if this.type == PNG.RGBA then
		this:write { r, g, b, a }
	else
		this:write { r, g, b }
	end
end)

__e2setcost(10)
registerFunction("output", "xpn:", "s", function(self, args)
	local op1 = args[2]

	---@type PNG
	local this = op1[1](self, op1)

	-- ~8000 ops for a 2048x2048 render.
	self.prf = self.prf + (this.width * this.height) / 500

	return table.concat(this.output)
end)

__e2setcost(1)
registerFunction("done", "xpn:", "n", function(self, args)
	local op1 = args[2]
	local this = op1[1](self, op1)

	if this.done then return 1 else return 0 end
end)
