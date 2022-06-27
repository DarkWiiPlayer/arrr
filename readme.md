Arrr
================================================================================

A simple library to parse commandline arguments in Lua.

	local arrr = require 'arrr'
	local parser = arrr {
		{"Foos two bars", "--foo", "-f", {'first', 'second'}};
	}
	local options = parser {...}

	print(options.foo.first, options.foo.second)

The library is intentionally simple and doesn't provide any advanced features.
Its main goal is to be portable, usable as a rock or just a copy-in Lua file,
easy to understand and maintain and easy to hack.

Structure of an argument description:

	- Description
	- Long name
	- Short name (can be nil for none)
	- Argument count or names
		- Nil for a boolean flag
		- A string for single argument
		- Number to collect that many arguments in a sequence
		- Array of keys to collect arguments into a table
		- An Asterisk * for a variable length of arguments that don't start with -
	- Whether or not the argument is repeatable

Long argument names work as expected. Short ones can be combined into one, and
if they take arguments, they will be read in order:

	lua my_script -f foo -b bar
	lua my_script -fb foo bar # identical to above

Unknown arguments and extra positional arguments will simply be returned at
integer positions.

Setting the `unknown` field on a parser to a callback will make it call its
value for every unknown parameter that it encounters and drop the parameter,
should the callback return a truthy value.

	local parser = arrr { --[[ parses nothing ]] }
	function parser.unknown(token, data)
		table.insert(data, token:gsub("^--?", "")) -- Remove leading dash(es)
		return true -- Drop the parameter, because it was already handled
	end
	parser { "--unknown" } -- returns { "unknown" }

At any position where a new argument is expected, a `--` will immediately stop
parsing arguments and return all following arguments unmodified as positional
arguments.
