Arrr
================================================================================

A simple library to parse commandline arguments in Lua.

	local arrr = require 'arrr'
	local parser = arrr {
		{"Foos two bars", "--foo", "-f", {'bar 1', 'bar 2'}};
	}
	local options = parser {...}
