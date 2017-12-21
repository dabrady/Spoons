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

  -------- This bit of logic dynamically updates the size of the chooser based on the
  -------- choice list, but relies on a workaround for forcing the chooser to resize
  -------- while visible which had the annoying side-effect of selecting each character
  -------- you typed into the text field, making search strings longer than a single
  -------- character unusable :P
  -- local function _filterChoices(query)
  --   -- Return full palette of choices if query is empty.
  --   if query == '' then return state.actionPalette end
  --
  --   -- Perform case-insensitive matchers by converty query and match candidate to all lowercase.
  --   query = query:lower()
  --   local filteredChoices = {}
  --   for _, choice in ipairs(state.actionPalette) do
  --     local text = choice.text
  --     if text and text:lower():find(query) then table.insert(filteredChoices, choice) end
  --   end
  --   return filteredChoices
  -- end
  --
  -- local function _updateChooser(queryString)
  --   print('updating!')
  --   local newChoiceList = _filterChoices(queryString)
  --   palette:rows(#newChoiceList)
  --   :choices(newChoiceList)
  --   :queryChangedCallback(function(queryString)
  --     print('skipping!')
  --     palette:queryChangedCallback(_updateChooser)
  --   end) -- Remove the existing callback so we don't go into an infinite loop on the next line
  --   :show():query(queryString) -- Force window to redraw itself
  --   -- :queryChangedCallback(_updateChooser) -- Register this callback with the chooser again
  -- end

  -- palette:queryChangedCallback(_updateChooser):show()
  -- return true
end

local function _enter(_, this)
  -- No need to do anything if already in this flow.
  if Universe.currentFlow() == this then return this end
  hs.alert("Entering "..this.name)

  if Universe.currentFlow() then Universe.currentFlow():exit() end
  Universe.setCurrentFlow(this)

  return this
end

local function _exit(_, this)
  hs.alert("Exiting "..this.name)

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
