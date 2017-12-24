local Spacious = {
  name = 'Spacious',
  version = '0.0.1',
  author = 'Daniel Brady <daniel.13rady@gmail.com>',
  license = 'https://opensource.org/licenses/MIT',

  -- Absolute path to root of spoon
  spoonPath = (function()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
  end)()
}

function Spacious:start() end
function Spacious:stop() end

function Spacious:bindHotkeys(mapping)
  local spec = {}
  hs.spoons.bindHotkeysToSpec(spec, mapping)
end

function Spacious:init()
  -- Load some base utilities
  if not spoon['Utilities'] then
    my = hs.loadSpoon('Utilities').utils
  end

  return self
end

----

return Spacious
