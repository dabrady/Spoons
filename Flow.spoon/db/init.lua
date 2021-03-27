local Universe = ...
-- print('[DEBUG] initializing Flow database')
assert(
  Universe.__config and Universe.__config.database_location,
  "no database path configured, cannot initialize database"
)
Universe.__logger.d("initializing database")

---
-- NOTE(dabrady) Exposing this globally for testing porpoises; reevaluate that decision later
luactiverecord = require('luactiverecord')
luactiverecord:configure{
  database_location = Universe.__config.database_location,
  seeds_location = Universe.spoonPath..'db/seeds.lua'
}

-- NOTE(dabrady) Need to load the schema prior to seeding the database, otherwise nothing happens.
local ledgers = assert(loadfile(Universe.spoonPath..'db/schema.lua')(Universe, luactiverecord))
luactiverecord:seed_database()

return ledgers
