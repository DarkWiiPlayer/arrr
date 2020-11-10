--- A simple commandline argument parser.
-- This module tries to provide a good approximation of how most programs
-- interpret commandline flags while keeping the logic and rules simple.
-- @module arrr
-- @usage
-- 	local arrr = require 'arrr'
-- 	parser = arrr { {"Foos a bar", "--foo", "-f", {'bar'}} }

--- Parses a list of argument descriptors.
-- The format is: `{Description, Longhand, Shorthand, parameters, filter}`.
-- All members except the longhand can be nil.
local function parse(descriptors)
	local register = {}
	for i, descriptor in ipairs(descriptors) do
		local long, short =
			descriptor[2] and descriptor[2]:gsub('^%-%-', ''),
			descriptor[3] and descriptor[3]:gsub('^%-', '')

		local current = {
			name = long;
			description = descriptor[1];
			params = descriptor[4];
			filter = descriptor[5]
		}

		if long then register[long] = current end
		if short then register[short] = current end
		table.insert(register, current)
	end
	return register
end

--- Handles a command
-- @treturn Number the position of the first unhandled element in the list
local function handle_command(data, token, list, start, descriptor, raw)
	local result
	if descriptor then
		local params = descriptor.params
		if type(params) == "nil" then
			result = true
		elseif type(params) == "string" then
			result = list[start]
			start = start + 1
		elseif type(params) == "number" then
			result = {}
			for i=1,params do
				result[i] = list[start+i-1]
			end
			start = start+params
		elseif type(params) == "table" then
			result = {}
			for i=1,#params do
				result[params[i]] = list[start+i-1]
			end
			start = start+#params
		end

		if descriptor.filter then
			data[descriptor.name] = descriptor.filter(result)
		else
			data[descriptor.name] = result
		end
	else
		-- Insert as a positional argument so it can maybe be parsed later on
		table.insert(data, raw)
	end
	return start
end

local __parser = {}
function __parser:__call(...)
	return self:parse(...)
end

--- Returns a new commandline parser built from a param list.
-- @usage
-- 	local parser = arrr {
-- 		{ "Foos a bar", "--foo", "-f", {'bar'} };
-- 		{ "Foos a bar", "--bar", "-b", {'bar'} };
-- 	}
-- 	
-- 	local data = arrr {'--foo', 'bar', '--bar', 'hello', '-abc', 'baz'}
local function parser(descriptors)
	local register = setmetatable(parse(descriptors), __parser)

	function register:parse(list)
		local data = {}
		local index = 1
		while index <= #list do
			local current = list[index]
			index = index + 1
			if current == '--' then
				for i = index, #list do
					table.insert(data, list[i])
				end
				return data
			elseif current:find '^%-%-%a+$' then
				local token = current:sub(3)
				local descriptor = self[token]
				index = handle_command(data, token, list, index, descriptor, current)
			elseif current:find '^%-' then
				for token in current:sub(2):gmatch(".") do
					local descriptor = self[token]
					index = handle_command(data, token, list, index, descriptor, "-"..token)
				end
			else
				table.insert(data, current)
			end
		end
		return data
	end

	return register
end

return parser
