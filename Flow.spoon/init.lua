local Flow = {
  name = 'Flow',
  version = '0.0.1',
  author = 'Daniel Brady <daniel.13rady@gmail.com>',
  license = 'https://opensource.org/licenses/MIT',

  -- Absolute path to root of spoon
  spoon_path = (function()
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

local function with_spoon_in_path(fn)
  -- Temporarily modify loadpath
  local old_path = package.path
  local old_cpath = package.cpath
  package.path = string.format('%s?.lua;%s', Flow.spoon_path, old_path)
  package.cpath = string.format('%s?.so;%s', Flow.spoon_path, old_cpath)

  fn()

  -- Reset loadpath
  package.path = old_path
  package.cpath = old_cpath
end

local function show_flow_palette()
  local my = { table = require('lib/lua-utils/table') }

  if Flow:current_flow() then
    Flow:current_flow():show_action_palette()
  else
    local choices = my.table.map(
      my.table.keys(Flow:available_flows()),
      function(i, flow_name)
        return i, { text = flow_name }
    end)

    Flow._create_chooser('flows', function(action)
        if action then
          hs.timer.doAfter(0, function()
            Flow:available_flows()[action.text]:enter():show_action_palette()
          end)
        end
    end)
      :choices(choices)
      :rows(#choices)
      :show()
  end

  return
end

Flow.current_flow, Flow.set_current_flow = (function()
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

local available_flows = {}
function Flow:available_flows()
  return available_flows
end

Flow._registered_choosers = {}
function Flow._create_chooser(id, ...)
  local chooser = hs.chooser.new(...)
  getmetatable(chooser).__flow_id = id
  Flow._registered_choosers[id] = chooser
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
  with_spoon_in_path(function()
    -- Load base flow
    local BaseWorkflow = assert(loadfile(self.spoon_path..'base_flow.lua'))(self)

    -- Load all flows
    local flow_root = self.spoon_path..'flows/'
    local _,flows = hs.fs.dir(flow_root)
    repeat
      local filename = flows:next()
      if filename and filename ~= '.' and filename ~= '..' then
        local basename = filename:match("^(.+)%.") -- Matches everything up to the first '.'
        print('\t-- loading '..basename..' flow')

        -- Load the flow, passing the base workflow as a parameter to the Lua chunk.
        local flow = assert(loadfile(flow_root..filename))(BaseWorkflow)
        available_flows[flow.name] = flow
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
  with_spoon_in_path(function()
    -- Initialize the Flow database
    assert(loadfile(self.spoon_path..'db/init.lua'))(self)
  end)

  ---
  return self
end
function Flow:stop() return self end

function Flow:bind_hotkeys(mapping)
  local spec = {
    show_flow_palette = show_flow_palette
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)

  ---
  return self
end

function Flow:configure(desired_config)
  if not desired_config then
    return self
  end
  __checks__('?', 'table') -- since this is an "instance method", first arg is the implicit 'self', so gotta skip it

  if not self.__config then
    self.__config = {}
  end

  -- Configure database
  self.__config.database_location = typecheck(desired_config.database_location, 'string') -- required

  -- Configure keymap
  hotkeys = typecheck(desired_config.hotkeys, '?table')
  if hotkeys then
    self:bind_hotkeys(desired_config.hotkeys)
    self.__config.hotkeys = hotkeys
  end

  return self
end
----

return Flow
