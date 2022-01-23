---@diagnostic disable-next-line
local Descriptions = E2Helper.Descriptions
local format = string.format

local function desc(Name,Descript)
	Descriptions[Name] = format("%s. [Base]",Descript)
end

desc("foo(n)", "Returns the number you give back, n.")