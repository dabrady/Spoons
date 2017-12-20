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

function Flow:init()
  -- Load some base utilities
  hs.loadSpoon('Utilities')

  -- Load base flow
  local BaseWorkflow = dofile(self.spoonPath..'/base_workflow.lua')
  function Flow:current()
    return BaseWorkflow.current()
  end

  -- Load all flows
  local flowRoot = self.spoonPath..'flows/'
  local _,flows = hs.fs.dir(flowRoot)
  repeat
    local filename = flows:next()
    if filename and filename ~= '.' and filename ~= '..' then
      local basename = filename:match("^(.+)%.") -- Matches everything up to the first '.'
      print('\t-- loading '..basename..' flow')

      -- Load the flow, passing the base workflow as a parameter to the Lua chunk.
      assert(loadfile(flowRoot..filename))(BaseWorkflow)
    end
  until filename == nil

  return self
end

function Flow:start() end
function Flow:stop() end

function Flow:bindHotkeys(mapping)
  local spec = {
    showFlowPalette = function()
      if Flow:current() then
        return Flow:current():showActionPalette()
      else
        return false
      end
    end
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)
end
----

return Flow
