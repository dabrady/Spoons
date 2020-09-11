local Universe = ...
-- print('[DEBUG] initializing Flow database')
assert(
  Universe.__config and Universe.__config.databasePath,
  "no database path configured, cannot initialize database"
)
---
-- NOTE(dabrady) Exposing this globally for testing porpoises; reevaluate that decision later
ActiveRecord = require('LUActiveRecord')
ActiveRecord.setDefaultDatabase(Universe.__config.databasePath)
assert(loadfile(Universe.spoonPath..'/db/schema.lua')(ActiveRecord))

ActiveRecord.seedDatabase(Universe.spoonPath..'/db/seeds.lua')
