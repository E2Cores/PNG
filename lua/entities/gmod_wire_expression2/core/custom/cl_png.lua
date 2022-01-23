---@diagnostic disable-next-line
local Descriptions = E2Helper.Descriptions
local format = string.format

local function desc(Name, Descript)
	Descriptions[Name] = format("%s. [PNG]", Descript)
end

desc("png(nnn)", "Creates a PNG Object, first two arguments being width / height, third is either _PNG_RGB or _PNG_RGBA")
desc("write(xpn:nnn)", "Writes rgb data to the PNG. Works for both RGB and RGBA pngs. Note the components need to be rounded. You cannot have decimals for pixels, it will break the png.")
desc("write(xpn:nnnn)", "Writes rgba data to the PNG. Works for both RGB and RGBA pngs. Note the components need to be rounded. You cannot have decimals for pixels, it will break the png.")
desc("writeVector(xpn:v)", "Writes a vector to the PNG. Works for both RGB and RGBA pngs. Note the components need to be rounded. You cannot have decimals for pixels, it will break the png.")
desc("writeVector4(xpn:xv4)", "Writes a vector4 to the PNG. Works for both RGB and RGBA pngs. Note the components need to be rounded. You cannot have decimals for pixels, it will break the png.")
desc("done(xpn:)", "Returns if the PNG is done writing.")
desc("output(xpn:)", "Gets the output of the PNG. Use this when the PNG is done writing, to save to a file.")