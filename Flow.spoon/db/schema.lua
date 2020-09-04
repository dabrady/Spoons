print('[DEBUG] loading schema')
ActiveRecord = require('LUActiveRecord')
ActiveRecord.setDefaultDatabase(os.getenv('FLOW_DB'))

-- TODO(dabrady) Consider something like this
-- local Type = {
--   NULL      = 'NULL',

--   BLOB      = 'BLOB',
--   RAWDATA   = 'BLOB',

--   INTEGER   = 'INTEGER',
--   REAL      = 'REAL',
--   FLOAT     = 'REAL',

--   TEXT      = 'TEXT',
--   DATE      = 'TEXT',
--   TIME      = 'TEXT',
--   TIMESTAMP = 'TEXT',

--   BOOLEAN   = function(column) return string.format('INTEGER CHECK(%s in (false, true))', column) end
-- }



-- TODO(dabrady) Add null constraints when ready to use

--[[

  A Token is a set of keys that, when pressed together, mean something.
  Without some context, however, we cannot say what is meant.

]]
Token = ActiveRecord{
  tableName = 'tokens',
  schema = {
    keyset = 'TEXT NOT NULL'
  }
}

--[[

  An AppContext is all meaningful data pertaining to a running application at a
  given instant in time.

  An AppContext can be combined with a Token to create meaning, but without a
  Token, an AppContext is simply a meaningless snapshot of a running application.

]]
AppContext = ActiveRecord{
  tableName = 'app_contexts',
  schema = {
    now = 'TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    bundle_id = 'TEXT'--[[..' NOT NULL']],
    moment_id = 'TEXT'--[[..' NOT NULL']],
    focused = 'BOOLEAN DEFAULT false CHECK(focused in (false, true))'--[[..' NOT NULL']],
    hidden = 'BOOLEAN DEFAULT false CHECK(hidden in (false, true))'--[[..' NOT NULL']],
    visible_windows = 'TEXT',
    focused_window = 'TEXT'
  }
}

Action = ActiveRecord{
  tableName = 'actions',
  schema = {
    short_name = 'TEXT'--[[ ..'NOT NULL' ]],
    token_seq = 'TEXT'--[[ ..'NOT NULL' ]],
    taken_at = 'TIMESTAMP TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    app_context_id = 'TEXT'
  },
  references = {
    app_context_id = AppContext.tableName
  },
  recreate = true
}

AppWindow = ActiveRecord{
  tableName = 'app_windows',
  schema = {
    app_bundle_id = 'TEXT'--[[..' NOT NULL']],
    fullscreen = 'BOOLEAN DEFAULT false CHECK(fullscreen in (false,true))'--[[..' NOT NULL']],
    width = 'TEXT'--[[..' NOT_NULL']],
    height = 'TEXT'--[[..' NOT_NULL']],
    visible = 'BOOLEAN DEFAULT false CHECK(visible in (false,true))'--[[..' NOT NULL']],
    minimized = 'BOOLEAN DEFAULT false CHECK(minimized in (false,true))'--[[..' NOT NULL']],
    standard = 'BOOLEAN DEFAULT false CHECK(standard in (false,true))'--[[..' NOT NULL']],
  }
}

Moment = ActiveRecord{
  tableName = 'moments',
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
    app_context_id = AppContext.tableName,
    previous_moment_id = 'moments',
    last_action_id = Action.tableName
  }
}
