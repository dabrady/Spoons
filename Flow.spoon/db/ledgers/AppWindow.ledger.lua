local luactiverecord, START_OVER = ...

return luactiverecord{
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
