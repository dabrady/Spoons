local Workflow = {name = 'Abstract Base Flow'}
local CURRENT_WORKFLOW = nil

function Workflow.current()
  return CURRENT_WORKFLOW
end

local function setActionPalette(state, this, actionList)
  if actionList == nil then return false end

  -- Clear any existing palette
  state.actionPalette = {}
  state.actionMap = {}

  -- Build a new palette
  for i,action in ipairs(actionList) do
    local actionId = i -- Very simple, let's see how it works.
    state.actionMap[actionId] = action.command
    table.insert(state.actionPalette, {
      text = action.name,-- newFlow.name..': '..action.name,
      id = actionId
    })
  end

  return true
end

local function showActionPalette(state, _)
  if not state or state.actionPalette == nil then return false end

  local palette = hs.chooser.new(function(action)
    if action then
      state.actionMap[action.id]()
    end
  end)
  :choices(state.actionPalette)
  :rows(#state.actionPalette)
  :show()

  return true

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

local function enter(_, this)
  -- No need to do anything if already in this flow.
  if CURRENT_WORKFLOW == this then return this end

  hs.alert("Entering "..this.name)
  if CURRENT_WORKFLOW then CURRENT_WORKFLOW:exit() end
  CURRENT_WORKFLOW = this
  return this
end

local function exit(_, this)
  hs.alert("Exiting "..this.name)
  CURRENT_WORKFLOW = nil
  return this
end

-- local function bindHotkeys(_, this, mapping)
--   local spec = {
--     enter = hs.fnutils.partial(enter, _, this),
--     exit = hs.fnutils.partial(exit, _, this)
--   }
--   -- TODO THIS DELETES PREVIOUS HOTKEY MAPPINGS: FIGURE OUT HOW TO NOT DO THAT
--   hs.spoons.bindHotkeysToSpec(spec, mapping)
--   return this
-- end

function Workflow.new(name)
  -- Create a new workflow object and state table to close over.
  local newFlow = setmetatable({}, {__index = Workflow}) -- Link to base Workflow
  local state = setmetatable({}, {__index = newFlow}) -- Link to new workflow

  -- 'actionList' is a table in the format of:
  -- {
  --   {
  --     name = 'a string',
  --     command = function() ... end
  --   },
  --   ...
  -- }


  -----
  newFlow = {
    name = name,
    enter = hs.fnutils.partial(enter, state),
    exit = hs.fnutils.partial(exit, state),
    -- bindHotkeys = hs.fnutils.partial(bindHotkeys, state),
    setActionPalette = hs.fnutils.partial(setActionPalette, state),
    showActionPalette = hs.fnutils.partial(showActionPalette, state),
    --- Expose internal state for debugging purposes
    -- __state__ = state
  }
  return newFlow
end

--------
return Workflow
