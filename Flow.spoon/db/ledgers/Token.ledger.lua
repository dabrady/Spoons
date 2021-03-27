local luactiverecord, START_OVER = ...
--[[

  A Token is a set of keys that, when pressed together, mean something.
  Without some context, however, we cannot say what is meant.

]]
return luactiverecord{
  table_name = 'tokens',
  schema = {
    keyset = 'TEXT NOT NULL'
  },
  recreate = START_OVER
}
