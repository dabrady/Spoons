local utilities = {
  name = 'Utilities',
  version = '0.0.1',
  author = 'Daniel Brady <daniel.13rady@gmail.com>',
  license = 'https://opensource.org/licenses/MIT',

  -- Absolute path to root of spoon
  spoonPath = (function()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
  end)()
}

function utilities:init()
  local extensionRoot = self.spoonPath..'extensions/'
  local _,extensionData = hs.fs.dir(extensionRoot)

  -- Load all extensions
  repeat
    local filename = extensionData:next()
    if filename and filename ~= '.' and filename ~= '..' then
      local basename = filename:match("^(.+)%.") -- Matches everything up to the first '.'
      print('\t-- loading '..basename..' extension')

      dofile(extensionRoot..filename)
    end
  until filename == nil

  return self
end

return utilities
