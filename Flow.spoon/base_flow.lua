local Universe = ...
local BaseFlow = {name = 'Abstract Base Flow'}

BaseFlow.createChooser =(function()
    local count = 0;
    return function(fn)
      count = count + 1
      return Universe._createChooser(count, fn)
    end
end)()

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

  -- Build a new palette
  local actionMap = {}
  local actionPalette = {}
  for i,action in ipairs(actionList) do
    local actionId = i -- Very simple, let's see how it works.
    actionMap[actionId] = action.command
    table.insert(actionPalette, {
      id = actionId,
      text = action.name
    })
  end

  -- Insert an 'exit' action
  local exitId = #actionPalette + 1
  actionPalette[exitId] = { id = exitId, text = '(Exit '..this.name..')'}
  actionMap[exitId] = hs.fnutils.partial(this.exit, this)

  -- Create a chooser for this flow's action palette
  state.actionChooser = BaseFlow.createChooser(
    -- Invoke the chosen action
    function(action)
      if action then
        -- hs.timer.doAfter(0, actionMap[action.id])
        actionMap[action.id]()
      end
    end)
    -- Set the choices
    :choices(actionPalette)
    -- Size the chooser according to the number of choices (up to the default max)
    :rows(#actionPalette)

  return this
end

local function _showActionPalette(state, this)
  if not (state and state.actionChooser) then return false end

  state.actionChooser:show()

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
