local Mode = {
  name = 'Mode',
  version = '0.0.1',
  author = 'Daniel Brady <daniel.13rady@gmail.com>',
  license = 'https://opensource.org/licenses/MIT',

  -- Absolute path to root of spoon
  spoonPath = (function()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
  end)()
}

Mode.currentMode, Mode.setCurrentMode = (function()
  -- Creating a closure instead of a global to avoid collisions when this spoon
  -- is loaded multiple times.
  local CURRENT_MODE = nil
  return
    -- A getter
    function()
      return CURRENT_MODE
    end,
    -- A setter
    function(mode)
      CURRENT_MODE = mode
      return CURRENT_MODE
    end
end)()

local availableModes = {}
function Mode:availableModes()
  return availableModes
end

function Mode:start() end
function Mode:stop() end

function Mode:bindHotkeys(mapping)
  local spec = {}
  hs.spoons.bindHotkeysToSpec(spec, mapping)
end

function Mode:init()
  -- Load some base utilities
  hs.loadSpoon('Utilities')
  -- Load our flow system
  local Flow = hs.loadSpoon('Flow'):bindHotkeys({showFlowPalette = {{'ctrl', 'alt', 'cmd'}, 'space'}})
  -- Load base mode
  local BaseMode = assert(loadfile(self.spoonPath..'base_mode.lua'))(self)

  -- Load all modes
  local modeRoot = self.spoonPath..'modes/'
  local _,modes = hs.fs.dir(modeRoot)
  repeat
    local filename = modes:next()
    if filename and filename ~= '.' and filename ~= '..' then
      local basename = filename:match("^(.+)%.") -- Matches everything up to the first '.'
      print('\t-- loading '..basename..' mode')

      -- Load the mode, passing the base workmode as a parameter to the Lua chunk.
      local mode = assert(loadfile(modeRoot..filename))(self, BaseMode, Flow)
      availableModes[mode.name] = mode
    end
  until filename == nil

  return self
end

----

return Mode
