package = "flow"
version = "dev-1"
source = {
   url = "git+https://github.com/dabrady/Spoons"
}
description = {
   homepage = "https://github.com/dabrady/Spoons",
   license = "MIT"
}
supported_platforms = {
  "macosx"
}
dependencies = {
   "lua ~> 5.4",
   -- TODO(dabrady) Add dependent rocks
}
build = {
   type = "builtin",
   modules = {
      -- TODO(dabrady) Expose only public API
      key_logger = "src/key_logger.lua",
      tokenizer = "src/tokenizer.lua"
   }
}
