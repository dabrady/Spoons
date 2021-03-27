local luactiverecord, START_OVER = ...

return luactiverecord{
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
    app_context_id = "app_contexts",
    previous_moment_id = 'moments',
    last_action_id = "actions"
  },
  recreate = START_OVER
}
