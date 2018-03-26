---
--- Based on https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/window/layout.lua
---
local Layout = {}

-- Load necessary utilities
local my = {
  table = require('extensions/table')
}

local Logger = require('hs.logger')
local _log = Logger.new('Spacious')

-- TODO Delete this; for testing porpoises
_log.setLogLevel('info')

Layout.setLogLevel = _log.setLogLevel
Layout.getLogLevel = _log.getLogLevel

-- Supported layout commands.
Layout.windowActions = setmetatable({
  -- TODO Add some default actions
  },{
    __index = function(action)
      _log.vf('unsupported action "%s", ignoring', action)
    end
  }
)

local _windowActionMap = {
  -- TODO Add some default actions
}

-- A buffer for pending layout actions
local _actionBuffer = {}

local function _parseCommands(commandData, parentRuleID, log)
  local function _parseCommandString(commandstring)
    return false,nil,'not yet implemented'
  end

  local function _parseCommandList(commandlist)
    local function _parse(commandData)
      if type(commandData) == string then
        -- See if its a valid, predefined action.
        local command = _windowActionMap[commmandData]
        if not command then
          return false,nil,string.format("unknown command: '%s'", commandData)
        end

        commandData = command
      elseif type(commandData) ~= 'table' then
        return false,nil,string.format("command is not a table, given '%s'", type(commandData))
      end

      return true,{
        action = commandData.action,
        windowCap = commandData.windowCap,
        ruleID = parentRuleID
      }
    end

    local commands = {}
    for i,commandData in pairs(commandlist) do
      log.vf('parsing command %d', i)
      local ok,command,msg = _parse(commandData)
      if not ok then
        return false,nil,string.format('error parsing command: %s', msg)
      end

      commands[i] = command
    end

    return true,commands
  end

  if type(commandData) == 'string' then
    local ok,commands,msg = _parseCommandString(commandData)
    if not ok then
      return false,nil,string.format('error parsing commandstring: %s', msg)
    end

    return true,commands
  elseif type(commandData) == 'table' then
    local ok,commands,msg = _parseCommandList(commandData)
    if not ok then
      return false,nil,string.format('error parsing commandlist: %s', msg)
    end

    return true,commands
  else
    return false,nil,'commands must be a command string or list'
  end
end

local function _parseRules(data, log)
  if type(data) ~= 'table' or #data == 0 then
    return false,nil,'rules must be a non-empty list of tables'
  end

  local function _parse(ruleData, ruleID)
    if type(ruleData) ~= 'table' then
      return false,nil,string.format("expected rule to be a table, given '%s'", type(ruleData))
    end

    local wf = ruleData.windowfilter
    if not wf then
      return false,nil,'rule is missing a windowfilter'
    end

    local ok,commands,msg = _parseCommands(ruleData.commands, ruleID, log)
    if not ok then
      return false,nil,string.format('error parsing commands: %s', msg)
    end

    return true,{
      windowfilter = wf,
      commands = commands
    }
  end

  local rules = {}
  for i,ruleData in ipairs(data) do
    local ruleID = i -- Give it a simple unique identififer
    log.vf('parsing rule %d', ruleID)
    local ok,rule,msg = _parse(ruleData, ruleID)
    if not ok then
      return false,nil,string.format('error parsing rule: %s', msg)
    end

    rule.id = ruleID
    rules[i] = rule
  end

  return true,rules
end

local function _bufferRule(rule, log)
  local wf = rule.windowfilter
  local commands = rule.commands
  local pendingWindows = wf:getWindows()

  -- Rule application stops when there are no more commands to apply or no more windows to command, whichever comes
  -- first.
  local windowsConsumedByCommand = 0
  local bufferedActionCount = #_actionBuffer

  -- Convenience function for popping a window off the window queue and incrementing a 'pop count'.
  local function _consumeWindow()
    local window = table.remove(pendingWindows) -- Pop from the end
    if window then
      log.vf('consumed window: %s', window:title())
      windowsConsumedByCommand = windowsConsumedByCommand + 1
    end
    return window
  end

  log.df('buffering rule %d for %d windows', rule.id, #pendingWindows)
  local i = 1
  while i <= #commands and next(pendingWindows) ~= nil do
    local command = commands[i]
    local windowSet = {}
    -- Floor the window cap at 0 and cap it at the number of windows remaining if provided, defaulting to the
    -- number of remaining windows if not.
    local windowCap = #pendingWindows
    if command.windowCap then windowCap = math.max(math.min(command.windowCap, #pendingWindows), 0) end

    -- Build up the set of windows for this command
    -- In the special case of an explicit cap of 0, we use, but don't consume, whatever's left as our window set.
    if windowCap == 0 then
      windowSet = my.table.copy(pendingWindows)
    else
      while windowsConsumedByCommand < windowCap do
        table.insert(windowSet, _consumeWindow())
      end
    end

    -- Add the action to the buffer if there were windows left to act on.
    if next(windowSet) ~= nil then
      log.v('adding action to buffer')

      -- Instead of applying actions as we extract them, store them in a buffer from which they can be applied as
      -- needed. Useful in cases where rule application might get interrupted.
      bufferedActionCount = bufferedActionCount + 1
      _actionBuffer[bufferedActionCount] = {
        action = command.action,
        windowSet = windowSet,
        commandID = i,
        ruleID = command.ruleID
      }
    end

    i = i + 1
    windowsConsumedByCommand = 0  -- Reset consumption count for next command
  end
end

local function _bufferLayout(rules, log)
  log.i('buffering layout')
  for _,rule in ipairs(rules) do
    -- Attempt to apply the rule only if it has both a windowfilter defined and a list of commands to apply.
    if rule.windowfilter and rule.commands and next(rule.commands) ~= nil then
      _bufferRule(rule, log)
    else
      log.i('missing window filter or command list for rule, skipping')
    end
  end
end

local function _applyLayout(log)
  log.i('applying layout')
  log.df('%d actions to apply', #my.table.keys(_actionBuffer))
  -- NOTE Doesn't maintain action ordering. Maybe TODO find a way to apply in insertion order?
  for i,actionItem in ipairs(_actionBuffer) do
    log.vf('applying action %d for command %d', i, actionItem.commandID)
    actionItem.action(actionItem.windowSet, log)
  end
  log.df('clearing action buffer')
  _actionBuffer = {} -- Clear the buffer
end

local function _checkArrangement(schema, log)
  log.df('checking schema arrangement')
  if next(schema) == nil then return false end -- An empty schema applies to nothing

  -- Validate current screen arrangement against schema
  local foundScreenCount = 0
  for screenQuery,screenPosition in pairs(schema) do
    local screen = hs.screen.find(screenQuery)
    if not screen then return false end
    foundScreenCount = foundScreenCount + 1

    local x,y = screen:position()
    if not (x == screenPosition.x and y == screenPosition.y) then return false end
  end

  -- All screen definitions in the schema are valid, but we may still have more screens in the current arrangement.
  if #hs.screen.allScreens() ~= foundScreenCount then return false end

  -- Current screen arrangement matches the given schema exactly
  return true
end

local function _apply(state)
  local ok = _checkArrangement(state.screenArrangement, state.log)
  if not ok then
    state.log.i('layout does not apply to current screen arrangement, ignoring')
    return state
  end

  _bufferLayout(state.rules, state.log)
  _applyLayout(state.log)

  return nil
end



--[[

A layout is composed of a set of rules and a screen arrangement definition to which those rules apply. When the
current screen arrangement does not match the definition of the layout being applied, the layout will not take
effect.

A **screen arrangement** (as per System Preferences->Displays->Arrangement) is here defined as a table where each
key is a valid argument to `hs.screen.find()` and each value can be:
  - true (implying the screen must be present for the rules to apply)
  - false (implying the screen must be absent for the rules to apply)
  - an `hs.geometry` point definition (implying the screen must be present and in this position within the current
    screen arrangement as per `hs.screen:position()`)

A **rule** consists of a windowfilter (used to obtain the window pool to which the rule is applied) and a list of
commands, evaluated in order, defining the behavior of the rule.

A rule **command** acts on one or more of the windows in the rule's window pool, consuming those windows as it
acts; rule application stops when there are no more commands to apply or no more windows to command, whichever
comes first.
]]

function Layout.new(options, logname, loglevel)
  if not options then _log.e("C'mon, gimme something to work with!") return nil end

  -- Each layout gets its own logger to avoid conflicts
  local newLayout = setmetatable({
    log = (logname and Logger.new(logname, loglevel)) or _log,
    logname = logname,
    loglevel = loglevel
    -- TODO Think about adding GC and tostring support
  }, {__index = Layout}) -- Link to base layout

  -- Convenient access to internal logger
  if logname then
    newLayout.setLogLevel = newLayout.log.setLogLevel
    newLayout.getLogLevel = newLayout.log.getLogLevel
  end

  -- TODO Enforce
  local ok,rules,msg = _parseRules(options.rules, newLayout.log)
  if not ok then
    newLayout.log.ef('error parsing rules: %s', msg)
    return nil
  end

  newLayout.rules = rules
  newLayout.screenArrangement = options.screenArrangement or {}

  -- A container to hold private state that needs managed
  local state = setmetatable({}, {__index = newLayout})
  newLayout.apply = hs.fnutils.partial(_apply, state)

  -- Let the world know of our birth
  newLayout.log.i('new window layout created')
  return newLayout
end

-- Generates a layout for the current screen arrangement that can reproduce the current window configuration.
-- NOTE
-- Stage 1: Support only active space, main monitor.
-- Stage 2: Support all spaces, main monitor.
-- Stage 3: Support only active space, all monitors.
function Layout.capture()
  -- TODO implement
end




-- local function _appID(app)
--   -- Not all applications have a bundle ID, so use the app name as a fallback
--   return app:bundleID() or app:name()
-- end
--
-- layout.savePosition = function(win)
--   local appID = appID(win:application())
--
--   -- A collection of window frames, one for each open window of the application.
--   local frames = cache.windowPositions[appID] or {}
--   local serializedFrame = win:frame().table  -- {x=X,y=Y,w=W,h=H}
--
--   -- Store the window position
--   table.insert(frames, serializedFrame)
--   -- Update the cache
--   cache.windowPositions[appID] = frames
-- end
--
-- layout.restoreWindows = function(app)
--   local appID = appID(app)
--   local frames = cache.windowPositions[appID] or {}
-- end

------
return Layout
