local Universe = ... -- Expect spoon to be passed in when file is loaded
local BaseMode = {name = 'Abstract Base Mode'}
local logger = hs.logger.new('BaseMode', 'debug')

local bindingMods = {'ctrl', 'shift'}
local activeHotkeys = {}
local function _bindHotkeysToFlows(flows)
  for i,flow in ipairs(flows) do
    -- Only bind the first 9 workflows
    if i > 9 then break end
    table.insert(
      activeHotkeys,
      hs.hotkey.bind(bindingMods, tostring(i), hs.fnutils.partial(flow.enter, flow))
    )
  end
end
local function _unbindActiveHotkeys()
  for i,hotkey in ipairs(activeHotkeys) do
    hotkey:delete()
    activeHotkeys[i] = nil
  end
end

local function _enter(state, startFn, this)
  if Universe.currentMode() == this then return this end
  logger.d(this.name.." mode activated")

  if Universe.currentMode() then Universe.currentMode():exit() end
  Universe.setCurrentMode(this)

  _bindHotkeysToFlows(state.flows)
  startFn(state.flows)

  return this
end

local function _exit(state, stopFn, this)
  logger.d("Exiting "..this.name.." mode")

  Universe.setCurrentMode(nil)

  -- NOTE:
  -- No need to exit the current flow: flows exist independent of,
  -- and can be shared between, modes.

  _unbindActiveHotkeys()
  stopFn(state.flows)

  return this
end

function BaseMode.new(name, flows, options)
  local newMode
  local state = setmetatable({}, {__index = newMode})

  state.flows = flows or {}
  startFn = options.start or function() end
  stopFn = options.stop or function() end

  newMode = {
    name = name,
    enter = hs.fnutils.partial(_enter, state, startFn),
    exit = hs.fnutils.partial(_exit, state, stopFn),
    --- Expose internal state for debugging purposes
    -- __state__ = state
  }

  return setmetatable(newMode, {__index = BaseMode}) -- Link to base Mode
end

--------
return BaseMode
