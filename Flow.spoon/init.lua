local Flow = {
  name = 'Flow',
  version = '0.0.1',
  author = 'Daniel Brady <daniel.13rady@gmail.com>',
  license = 'https://opensource.org/licenses/MIT',

  -- Absolute path to root of spoon
  spoonPath = (function()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
  end)()
}

-- For type-checking
__checks__ = require('checks')
local function typecheck(val, t)
  __checks__(t)
  return val
end

local function withSpoonInPath(fn)
  -- Temporarily modify loadpath
  local oldPath = package.path
  local oldCPath = package.cpath
  package.path = string.format('%s?.lua;%s', Flow.spoonPath, oldPath)
  package.cpath = string.format('%s?.so;%s', Flow.spoonPath, oldCPath)

  fn()

  -- Reset loadpath
  package.path = oldPath
  package.cpath = oldCPath
end

local function showFlowPalette()
  local my = { table = require('lib/lua-utils/table') }

  if Flow:currentFlow() then
    Flow:currentFlow():showActionPalette()
  else
    local choices = my.table.map(
      my.table.keys(Flow:availableFlows()),
      function(i, flowName)
        return i, { text = flowName }
    end)

    Flow._createChooser('flows', function(action)
        if action then
          hs.timer.doAfter(0, function()
            Flow:availableFlows()[action.text]:enter():showActionPalette()
          end)
        end
    end)
      :choices(choices)
      :rows(#choices)
      :show()
  end

  return
end

Flow.currentFlow, Flow.setCurrentFlow = (function()
  -- Creating a closure instead of a global to avoid collisions when this spoon
  -- is loaded multiple times.
  local CURRENT_FLOW = nil
  return
    -- A getter
    function()
      return CURRENT_FLOW
    end,
    -- A setter
    function(flow)
      CURRENT_FLOW = flow
      return CURRENT_FLOW
    end
end)()

local availableFlows = {}
function Flow:availableFlows()
  return availableFlows
end

Flow._registeredChoosers = {}
function Flow._createChooser(id, ...)
  local chooser = hs.chooser.new(...)
  getmetatable(chooser).__flow_id = id
  Flow._registeredChoosers[id] = chooser
  return chooser
end

function Flow:init()
  -- TODO(dabrady) Figure out why I decided this delay was necessary.
  -- hs.chooser.globalCallback = (function()
  --     local oldDefaultChooserCallback = hs.chooser.globalCallback
  --     return function(chooser, state)
  --       if chooser.__flow_id and state == 'didClose' then
  --         hs.timer.doAfter(0.3, function()
  --                            oldDefaultChooserCallback(chooser, state)
  --         end)
  --       else
  --         oldDefaultChooserCallback(chooser, state)
  --       end
  --     end
  --   end
  -- )()

  -- Load all the things
  withSpoonInPath(function()
    -- Load base flow
    local BaseWorkflow = assert(loadfile(self.spoonPath..'base_flow.lua'))(self)

    -- Load all flows
    local flowRoot = self.spoonPath..'flows/'
    local _,flows = hs.fs.dir(flowRoot)
    repeat
      local filename = flows:next()
      if filename and filename ~= '.' and filename ~= '..' then
        local basename = filename:match("^(.+)%.") -- Matches everything up to the first '.'
        print('\t-- loading '..basename..' flow')

        -- Load the flow, passing the base workflow as a parameter to the Lua chunk.
        local flow = assert(loadfile(flowRoot..filename))(BaseWorkflow)
        availableFlows[flow.name] = flow
      end
    until filename == nil
  end)

  ---
  return self
end

function Flow:start()
  -- NOTE(dabrady) Deferring database initialization until the last possible moment,
  -- mostly because it requires some config and the `init` method of a Spoon does not
  -- accept arguments by convention.
  withSpoonInPath(function()
    -- Initialize the Flow database
    assert(loadfile(self.spoonPath..'/db/init.lua'))(self)
  end)

  ---
  return self
end
function Flow:stop() return self end

function Flow:bindHotkeys(mapping)
  local spec = {
    showFlowPalette = showFlowPalette
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)

  ---
  return self
end

function Flow:configure(desiredConfig)
  if not desiredConfig then
    return self
  end
  __checks__('?', 'table') -- since this is an "instance method", first arg is the implicit 'self', so gotta skip it

  if not self.__config then
    self.__config = {}
  end

  -- Configure database
  self.__config.databasePath = typecheck(desiredConfig.databasePath, 'string') -- required

  -- Configure keymap
  hotkeys = typecheck(desiredConfig.hotkeys, '?table')
  if hotkeys then
    self:bindHotkeys(desiredConfig.hotkeys)
    self.__config.hotkeys = hotkeys
  end

  return self
end
----

return Flow
