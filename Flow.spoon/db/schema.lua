local Universe, luactiverecord = ...
local START_OVER = true
Universe.__logger.d("loading schema")
-----

local ledgers = {}
local LEDGER_PATH = hs.spoons.resourcePath("ledgers")
for ledger_def in hs.fs.dir(LEDGER_PATH) do
  -- NOTE(dabrady) Using a custom file extension to visually separate
  -- ledgers from other Lua files.
  if ledger_def:endsWith(".ledger.lua") then
    local ledger_name = ledger_def:match("^[^%.]*") -- Matches everything up to the first '.'
    Universe.__logger.df("loading ledger: %s", ledger_name)
    ledgers[ledger_name] = assert(
      loadfile(string.format("%s/%s", LEDGER_PATH, ledger_def))
    )(luactiverecord, START_OVER)
  end
end

-- TODO(dabrady) Add null constraints when ready to use

return ledgers
