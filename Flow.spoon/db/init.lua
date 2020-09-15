local Universe = ...
-- print('[DEBUG] initializing Flow database')
assert(
  Universe.__config and Universe.__config.databasePath,
  "no database path configured, cannot initialize database"
)
---
-- NOTE(dabrady) Exposing this globally for testing porpoises; reevaluate that decision later
luactiverecord = require('luactiverecord')
luactiverecord:configure{
  database_location = Universe.__config.databasePath,
  seeds_location = Universe.spoonPath..'db/seeds.lua'
}
assert(loadfile(Universe.spoonPath..'db/schema.lua')(luactiverecord))

luactiverecord:seed_database()
