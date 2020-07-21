package = "arrr"
version = "dev-1"
source = {
   url = "git+https://github.com/darkwiiplayer/arrr",
}
description = {
	summary = "A minimalistic commandline argument parser for Lua",
   homepage = "https://github.com/darkwiiplayer/arrr",
   license = "Public Domain"
}
build = {
   type = "builtin",
   modules = {
      arrr = "src/arrr.lua",
   }
}
