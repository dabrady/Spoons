local Universe = ...
-- print('[DEBUG] initializing Flow database')
assert(
  Universe.__config and Universe.__config.database_location,
  "no database path configured, cannot initialize database"
)
---
-- NOTE(dabrady) Exposing this globally for testing porpoises; reevaluate that decision later
luactiverecord = require('luactiverecord')
luactiverecord:configure{
  database_location = Universe.__config.database_location,
  seeds_location = Universe.spoon_path..'db/seeds.lua'
}
assert(loadfile(Universe.spoon_path..'db/schema.lua')(luactiverecord))

luactiverecord:seed_database()
