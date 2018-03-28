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

function Flow:init()
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

  return self
end

function Flow:start() return self end
function Flow:stop() return self end

function Flow:bindHotkeys(mapping)
  local spec = {
    showFlowPalette = function()
      if self:currentFlow() then
        return self:currentFlow():showActionPalette()
      else
        hs.alert('No flow!')
        return false
      end
    end
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)
  return self
end
----

return Flow
