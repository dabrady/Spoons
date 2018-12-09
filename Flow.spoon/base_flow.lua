local Universe = ...
local BaseFlow = {name = 'Abstract Base Flow'}

-- 'actionList' is a table in the format of:
-- {
--   {
--     name = 'a string',
--     command = function() ... end
--   },
--   ...
-- }
local function _setActionPalette(state, this, actionList)
  if actionList == nil then return false end

  -- Clear any existing palette
  state.actionPalette = {}
  state.actionMap = {}

  -- Build a new palette
  for i,action in ipairs(actionList) do
    local actionId = i -- Very simple, let's see how it works.
    state.actionMap[actionId] = action.command
    table.insert(state.actionPalette, {
      text = action.name,
      id = actionId
    })
  end

  -- Insert an 'exit' action
  local exitId = #state.actionPalette + 1
  state.actionPalette[exitId] = { id = exitId, text = '(Exit '..this.name..')'}
  state.actionMap[exitId] = hs.fnutils.partial(this.exit, this)

  return this
end

local function _showActionPalette(state, this)
  if not state or #state.actionPalette == 0 then return false end

  local palette = hs.chooser.new(function(action)
      if action then
        state.actionMap[action.id]()
      end
    end)
    :choices(state.actionPalette)
    :rows(#state.actionPalette)
    :show()

  return this
end

local function _enter(_, this)
  -- No need to do anything if already in this flow.
  if Universe.currentFlow() == this then return this end
  -- hs.alert(this.name.." flow activated")

  if Universe.currentFlow() then Universe.currentFlow():exit() end
  Universe.setCurrentFlow(this)

  return this
end

local function _exit(_, this)
  -- hs.alert("Exiting "..this.name.." flow")

  Universe.setCurrentFlow(nil)

  return this
end

function BaseFlow.new(name)
  -- Create a new flow object and state table to close over.
  local newFlow
  local state = setmetatable({}, {__index = newFlow}) -- Link to new flow

  state.actionPalette = {}
  state.actionMap = {}

  newFlow = {
    name = name,
    enter = hs.fnutils.partial(_enter, state),
    exit = hs.fnutils.partial(_exit, state),
    setActionPalette = hs.fnutils.partial(_setActionPalette, state),
    showActionPalette = hs.fnutils.partial(_showActionPalette, state),
    --- Expose internal state for debugging purposes
    -- __state__ = state
  }
  return setmetatable(newFlow, {__index = BaseFlow}) -- Link to BaseFlow
end

--------
return BaseFlow
