--- Original Source: https://github.com/wyozi/lua-pngencoder
--- Modified to be more efficient, and work with this addon.
-- Note their license on the source: https://github.com/wyozi/lua-pngencoder/blob/master/LICENSE
local DEFLATE_MAX_BLOCK_SIZE = 65535
-- Local Functions for efficiency
local char, ceil, insert = string.char, math.ceil, table.insert
local rshift, lshift, bxor, bor, band, bnot = bit.rshift, bit.lshift, bit.bxor, bit.bor, bit.band, bit.bnot

---@class PNG
---@field output table<number, string>
---@field out string # Cached output
---@field width number
---@field height number
---@field bytes_per_pixel number
---@field line_size number
---@field pos_x number
---@field pos_y number
---@field pixel_pointer number
---@field done boolean
---@field type "PNG.RGB|PNG.RGBA"
local PNG = {}
PNG.__index = PNG
PNG.RGB = 0
PNG.RGBA = 1

local function putBigUint32(val, tbl, index)
	for i = 0, 3 do
		tbl[index + i] = band(rshift(val, (3 - i) * 8), 0xFF)
	end
end

function PNG:writeBytes(data, index, len)
	index = index or 1
	len = len or #data

	for i = index, index + len - 1 do
		insert(self.output, char(data[i]))
	end
end

function PNG:write(pixels)
	local count = #pixels -- Byte count
	assert(count == self.bytes_per_pixel, "Writing an incorrect amount of bytes per pixel. You might be writing RGB data to an RGBA Image, or vice versa.")
	local pixel_pointer = 1

	while count > 0 do
		if self.pos_y >= self.height then
			error("All image pixels already written")
		end

		-- Start DEFLATE block
		if self.deflate_filled == 0 then
			local size = DEFLATE_MAX_BLOCK_SIZE

			if (self.uncomp_remain < size) then
				size = self.uncomp_remain
			end

			-- 5 bytes long
			local header = {band((self.uncomp_remain <= DEFLATE_MAX_BLOCK_SIZE and 1 or 0), 0xFF), band(rshift(size, 0), 0xFF), band(rshift(size, 8), 0xFF), band(bxor(rshift(size, 0), 0xFF), 0xFF), band(bxor(rshift(size, 8), 0xFF), 0xFF),}

			self:writeBytes(header)
			self:crc32(header, 1, #header)
		end

		assert(self.pos_x < self.line_size and self.deflate_filled < DEFLATE_MAX_BLOCK_SIZE)

		-- Beginning of line - write filter method byte
		if (self.pos_x == 0) then
			local b = {0}

			self:writeBytes(b)
			self:crc32(b, 1, 1)
			self:adler32(b, 1, 1)
			self.pos_x = self.pos_x + 1
			self.uncomp_remain = self.uncomp_remain - 1
			self.deflate_filled = self.deflate_filled + 1
		else -- Write some pixel bytes for current line
			local n = DEFLATE_MAX_BLOCK_SIZE - self.deflate_filled

			if (self.line_size - self.pos_x < n) then
				n = self.line_size - self.pos_x
			end

			if (count < n) then
				n = count
			end

			assert(n > 0)
			self:writeBytes(pixels, pixel_pointer, n)
			self:crc32(pixels, pixel_pointer, n)
			self:adler32(pixels, pixel_pointer, n)
			count = count - n
			pixel_pointer = pixel_pointer + n
			self.pos_x = self.pos_x + n
			self.uncomp_remain = self.uncomp_remain - n
			self.deflate_filled = self.deflate_filled + n
		end

		if (self.deflate_filled >= DEFLATE_MAX_BLOCK_SIZE) then
			self.deflate_filled = 0
		end

		if (self.pos_x == self.line_size) then
			self.pos_x = 0
			self.pos_y = self.pos_y + 1

			if (self.pos_y == self.height) then
				local footer = {0, 0, 0, 0, 0, 0, 0, 0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,}

				putBigUint32(self.adler, footer, 1)
				self:crc32(footer, 1, 4)
				putBigUint32(self.crc, footer, 5)
				self:writeBytes(footer)
				self.done = true
			end
		end
	end
end

function PNG:crc32(data, index, len)
	self.crc = bnot(self.crc)

	for i = index, index + len - 1 do
		local byte = data[i]

		for j = 0, 7 do
			local nbit = band(bxor(self.crc, rshift(byte, j)), 1)
			self.crc = bxor(rshift(self.crc, 1), band((-nbit), 0xEDB88320))
		end
	end

	self.crc = bnot(self.crc)
end

function PNG:adler32(data, index, len)
	local s1 = band(self.adler, 0xFFFF)
	local s2 = rshift(self.adler, 16)

	for i = index, index + len - 1 do
		s1 = (s1 + data[i]) % 65521
		s2 = (s2 + s1) % 65521
	end

	self.adler = bor(lshift(s2, 16), s1)
end

---@param width integer
---@param height integer
---@param img_type "PNG.RGB|PNG.RGBA"
function PNG.new(width, height, img_type)
	local bytes_per_pixel, colorType = 3, 2

	if img_type == PNG.RGBA then
		bytes_per_pixel, colorType = 4, 6
	end

	local instance = setmetatable({
		width = width,
		height = height,
		done = false, -- Whether the image is full or not.
		output = {}, -- PNG Data
		type = img_type,
		bytes_per_pixel = bytes_per_pixel
	}, PNG)

	instance.line_size = width * bytes_per_pixel + 1
	instance.uncomp_remain = instance.line_size * height
	local numBlocks = ceil(instance.uncomp_remain / DEFLATE_MAX_BLOCK_SIZE)
	local idatSize = numBlocks * 5 + 6
	idatSize = idatSize + instance.uncomp_remain

	local header = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0, 0, 0, 0, 0, 0, 0, 0, 0x08, colorType, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0, 0, 0, 0x49, 0x44, 0x41, 0x54, 0x08, 0x1D,}

	putBigUint32(width, header, 17)
	putBigUint32(height, header, 21)
	putBigUint32(idatSize, header, 34)
	instance.crc = 0
	instance:crc32(header, 13, 17)
	putBigUint32(instance.crc, header, 30)
	instance:writeBytes(header)
	instance.crc = 0
	instance:crc32(header, 38, 6)
	instance.adler = 1
	instance.pos_x = 0
	instance.pos_y = 0
	instance.deflate_filled = 0

	return instance
end

function PNG.instanceof(val)
	return istable(val) and getmetatable(val) == PNG
end

return PNG