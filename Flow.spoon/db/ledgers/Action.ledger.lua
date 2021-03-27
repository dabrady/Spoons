local luactiverecord, START_OVER = ...

return luactiverecord{
  table_name = 'actions',
  schema = {
    short_name = 'TEXT'--[[ ..'NOT NULL' ]],
    token_seq = 'TEXT'--[[ ..'NOT NULL' ]],
    taken_at = 'TIMESTAMP TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
    app_context_id = 'TEXT'
  },
  references = {
    app_context_id = "app_contexts"
  },
  recreate = START_OVER
}
