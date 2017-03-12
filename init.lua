mgbm = {}

local buffer_store = {}
local mg_buffers = {}
local u_buffers = {}

local function get_size(size, dims)
	local z = 0
	if dims == 3
	and size.z then
		z = size.z
	end
	return z * size.y * size.x
end

local function get_buffer_mag(size, dims)
	return math.floor(math.log(get_size(size, dims)))
end

local function release_old_mg_buffers()
	for buffer, _ in pairs(mg_buffers) do
		mgbm.return_buffer(buffer)
		mg_buffers[buffer] = nil
	end
end

local function aquire_buffer(size, dims)
	local mag = get_buffer_mag(size, dims)
	local fsize = get_size(size, dims)

	if not buffers[mag] then
		buffers[mag] = {}
	end

	local buffer = buffers[mag][#buffers[mag]] or {}
	buffers[mag][#buffers[mag]] = nil

	buffer[fsize+1] = nil
	buffer.size = size
	buffer.dims = dims

	return buffer
end

local mg_id = ""
mgbm.get_mg_buffer = function(size, dims, id)
	if mg_id ~= id then
		release_old_mg_buffers()
		mg_id = id
	end

	local buffer = aquire_buffer(size, dims)
	mg_buffers[buffer] = buffer

	return buffer
end

mgbm.get_u_buffer = function(size,dims)
	local buffer = aquire_buffer(size, dims)
	u_buffers[buffer] = buffer

	return buffer
end

mgbm.is_buffer = function(buffer)
	if not buffer
	or not (u_buffers[buffer]
	or      mg_buffers[buffer]) then
		return false
	end
	return true
end

local is_buffer = mgbm.is_buffer
mgbm.return_buffer = function(buffer)
	if not is_buffer(buffer) then
		return
	end

	-- Might be in either
	u_buffers[buffer] = nil
	mg_buffers[buffer] = nil

	local mag = get_buffer_mag(buffer.size,buffer.dims)
	buffer.size = nil
	buffer.dims = nil

	buffers[mag][#buffers[mag]+1] = buffer
end

