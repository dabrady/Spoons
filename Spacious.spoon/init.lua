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

local function withSpoonInPath(fn)
  -- Temporarily modify loadpath
  local oldPath = package.path
  local oldCPath = package.cpath
  package.path = string.format('%s?.lua;%s', Spacious.spoonPath, oldPath)
  package.cpath = string.format('%s?.so;%s', Spacious.spoonPath, oldCPath)

  fn()

  -- Reset loadpath
  package.path = oldPath
  package.cpath = oldCPath
end

Spacious.currentLayout, Spacious.setCurrentLayout = (function()
  -- Creating a closure instead of a global to avoid collisions when this spoon
  -- is loaded multiple times.
  local CURRENT_LAYOUT = nil
  return
    -- A getter
    function()
      return CURRENT_LAYOUT
    end,
    -- A setter
    function(layout)
      CURRENT_LAYOUT = layout
      return CURRENT_LAYOUT
    end
end)()

function Spacious:start() end
function Spacious:stop() end

function Spacious:bindHotkeys(mapping)
  local spec = {}
  hs.spoons.bindHotkeysToSpec(spec, mapping)
end

function Spacious:init()
  withSpoonInPath(function()
    Spacious.layout = dofile(Spacious.spoonPath..'layout.lua')
    Spacious.spaces = dofile(Spacious.spoonPath..'hs/_asm/undocumented/spaces/init.lua')
  end)

  return self
end

----

return Spacious
