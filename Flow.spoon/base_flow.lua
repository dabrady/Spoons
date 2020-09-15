local Universe = ...
local BaseFlow = {name = 'Abstract Base Flow'}

BaseFlow.create_chooser =(function()
    local count = 0;
    return function(fn)
      count = count + 1
      return Universe._create_chooser(count, fn)
    end
end)()

-- 'action_list' is a table in the format of:
-- {
--   {
--     name = 'a string',
--     command = function() ... end
--   },
--   ...
-- }
local function _set_action_palette(state, this, action_list)
  if action_list == nil then return false end

  -- Build a new palette
  local action_map = {}
  local action_palette = {}
  for i,action in ipairs(action_list) do
    local action_id = i -- Very simple, let's see how it works.
    action_map[action_id] = action.command
    table.insert(action_palette, {
      id = action_id,
      text = action.name
    })
  end

  -- Insert an 'exit' action
  local exit_id = #action_palette + 1
  action_palette[exit_id] = { id = exit_id, text = '(Exit '..this.name..')'}
  action_map[exit_id] = hs.fnutils.partial(this.exit, this)

  -- Create a chooser for this flow's action palette
  state.action_chooser = BaseFlow.create_chooser(
    -- Invoke the chosen action
    function(action)
      if action then
        -- hs.timer.doAfter(0, action_map[action.id])
        action_map[action.id]()
      end
    end)
    -- Set the choices
    :choices(action_palette)
    -- Size the chooser according to the number of choices (up to the default max)
    :rows(#action_palette)

  return this
end

local function _show_action_palette(state, this)
  if not (state and state.action_chooser) then return false end

  state.action_chooser:show()

  return this
end

local function _enter(_, this)
  -- No need to do anything if already in this flow.
  if Universe.current_flow() == this then return this end
  -- hs.alert(this.name.." flow activated")

  if Universe.current_flow() then Universe.current_flow():exit() end
  Universe.set_current_flow(this)

  return this
end

local function _exit(_, this)
  -- hs.alert("Exiting "..this.name.." flow")

  Universe.set_current_flow(nil)

  return this
end

function BaseFlow.new(name)
  -- Create a new flow object and state table to close over.
  local new_flow
  local state = setmetatable({}, {__index = new_flow}) -- Link to new flow

  new_flow = {
    name = name,
    enter = hs.fnutils.partial(_enter, state),
    exit = hs.fnutils.partial(_exit, state),
    set_action_palette = hs.fnutils.partial(_set_action_palette, state),
    show_action_palette = hs.fnutils.partial(_show_action_palette, state),
    --- Expose internal state for debugging purposes
    -- __state__ = state
  }
  return setmetatable(new_flow, {__index = BaseFlow}) -- Link to BaseFlow
end

--------
return BaseFlow
