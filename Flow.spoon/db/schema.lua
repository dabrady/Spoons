local luactiverecord = ...
local START_OVER = true
-- print('[DEBUG] loading schema')
-- print(luactiverecord)
-----

-- TODO(dabrady) Add null constraints when ready to use

--[[

  A Token is a set of keys that, when pressed together, mean something.
  Without some context, however, we cannot say what is meant.

]]
Token = luactiverecord{
  table_name = 'tokens',
  schema = {
    keyset = 'TEXT NOT NULL'
  },
  recreate = START_OVER
}

--[[

  An AppContext is all meaningful data pertaining to a running application at a
  given instant in time.

  An AppContext can be combined with a Token to create meaning, but without a
  Token, an AppContext is simply a meaningless snapshot of a running application.

]]
AppContext = luactiverecord{
  table_name = 'app_contexts',
  schema = {
    now = 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    bundle_id = 'TEXT'--[[..' NOT NULL']],
    moment_id = 'TEXT'--[[..' NOT NULL']],
    focused = 'BOOLEAN DEFAULT false CHECK(focused in (false, true))'--[[..' NOT NULL']],
    hidden = 'BOOLEAN DEFAULT false CHECK(hidden in (false, true))'--[[..' NOT NULL']],
    visible_windows = 'TEXT',
    focused_window = 'TEXT'
  },
  recreate = START_OVER
}

Action = luactiverecord{
  table_name = 'actions',
  schema = {
    short_name = 'TEXT'--[[ ..'NOT NULL' ]],
    token_seq = 'TEXT'--[[ ..'NOT NULL' ]],
    taken_at = 'TIMESTAMP TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    app_context_id = 'TEXT'
  },
  references = {
    app_context_id = AppContext.table_name
  },
  recreate = START_OVER
}

AppWindow = luactiverecord{
  table_name = 'app_windows',
  schema = {
    app_bundle_id = 'TEXT'--[[..' NOT NULL']],
    fullscreen = 'BOOLEAN DEFAULT false CHECK(fullscreen in (false,true))'--[[..' NOT NULL']],
    width = 'TEXT'--[[..' NOT_NULL']],
    height = 'TEXT'--[[..' NOT_NULL']],
    visible = 'BOOLEAN DEFAULT false CHECK(visible in (false,true))'--[[..' NOT NULL']],
    minimized = 'BOOLEAN DEFAULT false CHECK(minimized in (false,true))'--[[..' NOT NULL']],
    standard = 'BOOLEAN DEFAULT false CHECK(standard in (false,true))'--[[..' NOT NULL']],
  },
  recreate = START_OVER
}

Moment = luactiverecord{
  table_name = 'moments',
  schema = {
    app_context_id = 'TEXT'--[[..' NOT_NULL']],
    open_app_ids = 'TEXT'--[[..' NOT_NULL']],
    previous_moment_id = 'TEXT'--[[..' NOT_NULL']],
    connected_input_devices = 'TEXT'--[[..' NOT_NULL']],
    connected_output_devices = 'TEXT'--[[..' NOT_NULL']],
    volume_level = 'TEXT'--[[..' NOT_NULL']],
    last_action_id = 'TEXT'--[[..' NOT_NULL']],
    timestamp = 'TIMESTAMP TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
  },
  references = {
    app_context_id = AppContext.table_name,
    previous_moment_id = 'moments',
    last_action_id = Action.table_name
  },
  recreate = START_OVER
}

return true
