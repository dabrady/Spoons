-- TODO(dabrady) This could conceivably move to the Token ledger.
-- Consider.

require("lua-utils/table")

local tokenizer = {}

function tokenizer.make(tokens)
  assert(type(tokens) == "table")

  local self = {
    -- TODO(dabrady) Potential optimization: order by frequency (once known) to
    -- speed up identification
    KNOWN_TOKENS = tokens
  }
  return setmetatable(self, { __index = tokenizer })
end

function tokenizer:tokenize(keys, mods)
  assert(type(keys) == "table")
  assert(type(mods) == "table")

  local keyset = table.merge(
    -- Convert keycodes to their human-readable characters
    table.map(keys, function(k,v) return hs.keycodes.map[k],v end),
    mods
  )

  local identified_token
  for _,token in ipairs(self.KNOWN_TOKENS) do
    if table.basically_the_same(token.keyset, keyset) then
      identified_token = token
      break
    end
  end

  return identified_token
end

return tokenizer
