--- A simple commandline argument parser.
-- This module tries to provide a good approximation of how most programs
-- interpret commandline flags while keeping the logic and rules simple.
-- @module arrr
-- @usage
-- 	local arrr = require 'arrr'
-- 	parser = arrr { {"Foos a bar", "--foo", "-f", 'bar'} }

--- Parses a list of argument descriptors.
-- The format is: `{Description, Longhand, Shorthand, parameters, repeatable}`.
-- All members except the longhand can be nil.
local function parse(descriptors)
	local register = {}
	for _, descriptor in ipairs(descriptors) do
		local current = {
			name = descriptor[2]:gsub("^%-%-", ''):gsub("-", "");
			description = descriptor[1];
			params = descriptor[4];
			long = descriptor[2];
			short = descriptor[3];
			repeatable = descriptor.repeatable;
			filter = descriptor.filter;
		}

		if descriptor[2] then register[descriptor[2]] = current end
		if descriptor[3] then register[descriptor[3]] = current end
		table.insert(register, current)
	end
	return register
end

--- Argument descriptor
-- @table Argument
-- @tfield string name The name of the parameter without dashes
-- @tfield string long The long form of the parameter
-- @tfield string short The short form of the parameter if present
-- @tfield string description
-- @field params The parameter(s) of the argument
-- @tfield boolean repeatable Whether the argument should be collected into a table

--- Handles a command
-- @treturn Number the position of the first unhandled element in the list
local function handle_command(data, token, list, start, descriptor, unknown_callback)
	local result
	if descriptor then
		local params = descriptor.params
		if type(params) == "nil" then
			result = true
		elseif params == '*' then
			result = {}
			for i=1,math.huge do
				if list[start] and not list[start]:find("^-") then
					result[i] = list[start]
					start = start+1
				else
					break
				end
			end
		elseif params == true then
			result = list[start]
			start = start + 1
		elseif type(params) == "string" then
			result = {}
			while list[start] and list[start] ~= params do
				table.insert(result, list[start])
				start = start + 1
			end
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
			result = descriptor.filter(result)
		else
			result = result
		end

		if descriptor.repeatable then
			data[descriptor.name] = data[descriptor.name] or {}
			table.insert(data[descriptor.name], result)
		else
			data[descriptor.name] = result
		end
	else
		-- Run callback if there is one
		if not (unknown_callback and unknown_callback(token, data)) then
			-- Insert as a positional argument so it can maybe be parsed later on
			table.insert(data, token)
		end
	end
	return start
end

local __parser = {__index = {}}

function __parser:__call(...)
	return self:evaluate(...)
end

--- Evaluates a chain of arguments.
-- Known arguments (and their parameters) will be read into string keys.
-- Extra arguments will be read into ascending integer keys.
-- A single `--` causes the parser to abort and read all remaining elements into integer keys.
function __parser.__index:evaluate(list)
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
		elseif current:find '^%-%-.+$' then
			local descriptor = self[current]
			index = handle_command(data, current, list, index, descriptor, self.unknown)
		elseif current:find '^%-%a+$' then
			for new in current:sub(2):gmatch(".") do
				new = '-'..new
				local descriptor = self[new]
				index = handle_command(data, new, list, index, descriptor, self.unknown)
			end
		else
			table.insert(data, current)
		end
	end
	return data
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
	return register
end

return parser
