local luactiverecord, START_OVER = ...
--[[

  An AppContext is all meaningful data pertaining to a running application at a
  given instant in time.

  An AppContext can be combined with a Token to create meaning, but without a
  Token, an AppContext is simply a meaningless snapshot of a running application.

]]
return luactiverecord{
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
