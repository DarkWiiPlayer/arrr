package = "arrr"
version = "dev-1"
source = {
   url = "git+https://github.com/darkwiiplayer/arrr",
}
description = {
   homepage = "https://github.com/darkwiiplayer/arrr",
   license = "Public Domain"
}
build = {
   type = "builtin",
   modules = {
      arrr = "src/arrr.lua",
   }
}
