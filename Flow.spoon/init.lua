local Flow = {
  name = 'Flow',
  version = '0.0.9001',
  author = 'Daniel Brady <daniel.13rady@gmail.com>',
  license = 'https://opensource.org/licenses/MIT',
  -- TODO(dabrady) Consider supplementing all `asserts` with `pcalls` and error logging.
  __logger = hs.logger.new('Flow', 'debug') -- TODO(dabrady) Change to 'info' before shipping
}

-- TODO(dabrady) Consider typechecking via 'shape':
-- @see https://github.com/leafo/tableshape
-- For type-checking
-- __checks__ = require('checks')
-- local function typecheck(val, t)
--   __checks__(t)
--   return val
-- end

local function with_spoon_in_path(fn)
  -- Temporarily modify loadpath
  local old_path = package.path
  local old_cpath = package.cpath
  package.path = string.format('%s?.lua;%s', Flow.spoonPath, old_path)
  package.cpath = string.format('%s?.so;%s', Flow.spoonPath, old_cpath)

  fn()

  -- Reset loadpath
  package.path = old_path
  package.cpath = old_cpath
end

local function show_flow_palette()
  Flow.__logger.d("showing flow palette")
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
      Flow.__logger.d("getting current flow")
      return CURRENT_FLOW
    end,
    -- A setter
    function(flow)
      Flow.__logger.f("changing to %s", flow)
      CURRENT_FLOW = flow
      return CURRENT_FLOW
    end
end)()

local available_flows = {}
function Flow:available_flows()
  Flow.__logger.d("getting available flows")
  return available_flows
end

Flow._registered_choosers = {}
function Flow._create_chooser(id, ...)
  Flow.__logger.d("creating new chooser")
  local chooser = hs.chooser.new(...)
  getmetatable(chooser).__flow_id = id
  Flow._registered_choosers[id] = chooser
  return chooser
end

function Flow:init()
  Flow.__logger.d("initializing")
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

  -- TODO(dabrady) Should this move to `start`? Reread Spoon conventions.

  -- Load base flow
  local BaseWorkflow = assert(loadfile(hs.spoons.resourcePath('base_flow.lua')))(self)

  -- Load all the things
  with_spoon_in_path(function()
    -- Load all flows
    local flow_root = self.spoonPath..'flows/'
    local _,flows = hs.fs.dir(flow_root)
    repeat
      local filename = flows:next()
      if filename and filename ~= '.' and filename ~= '..' then
        local basename = filename:match("^[^%.]*") -- Matches everything up to the first '.'
        Flow.__logger.i('loading '..basename..' flow')

        -- Load the flow, passing the base workflow as a parameter to the Lua chunk.
        local flow = assert(loadfile(flow_root..filename))(BaseWorkflow)
        available_flows[flow.name] = flow
      end
    until filename == nil
    flows:close() -- Necessary to make sure the directory stream is closed
  end)

  ---
  return self
end

function Flow:start()
  Flow.__logger.i("starting")
  -- Don't do anything if started more than once
  if self.__started then
    Flow.__logger.d("just kidding, already started")
    return self
  end

  -- NOTE(dabrady) Deferring database initialization until the last possible moment,
  -- mostly because it requires some config and the `init` method of a Spoon does not
  -- accept arguments by convention.
  with_spoon_in_path(function()
    -- Initialize the Flow database
    local ledgers = assert(loadfile(self.spoonPath.."db/init.lua"))(self)

    -- TODO(dabrady) move to a better location after testing
    local tokenizer = require("src/tokenizer")
    local key_logger = require("src/key_logger")

    flow_tokenizer = tokenizer.make(ledgers['Token']:all())
    action_logger = key_logger.make(function(keys, mods)
      local token = flow_tokenizer:tokenize(keys, mods)
      if not token then
        return
      end

      ledgers["Action"]:add_entry({ token_seq = token.id })
    end)

    -- TODO(dabrady) Would promises be usable here?
    -- @see https://devforum.roblox.com/t/promises-and-why-you-should-use-them/350825
    self.__key_watcher = hs.eventtap.new(
      {
        hs.eventtap.event.types.keyDown,
        hs.eventtap.event.types.keyUp,
      },
      function(event)
        -- NOTE(dabrady) Don't allow errors to happen here, otherwise the event
        -- doesn't propagate and is lost.
        local res, err = pcall(action_logger.log, action_logger, event)
        if not res then
          Flow.__logger.ef("😱\n%s", table.format(err))
        end
        return false
      end
    ):start()
    ---
  end)

  self.__started = true
  ---
  return self
end
function Flow:stop()
  Flow.__logger.i("stopping")

  if self.__key_watcher then
    self.__key_watcher:stop()
  end

  self.__started = false
  ---
  return self
end

function Flow:bind_hotkeys(mapping)
  Flow.__logger.i("binding hotkeys")

  local spec = {
    show_flow_palette = show_flow_palette
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)

  ---
  return self
end

function Flow:configure(desired_config)
  Flow.__logger.i("configuring")

  if not desired_config then
    return self
  end

  if not self.__config then
    self.__config = {}
  end

  -- Configure database
  self.__config.database_location = desired_config.database_location

  -- Configure keymap
  hotkeys = desired_config.hotkeys
  if hotkeys then
    self:bind_hotkeys(hotkeys)
    self.__config.hotkeys = hotkeys
  end

  return self
end
----

return Flow
