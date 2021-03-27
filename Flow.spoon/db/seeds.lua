local luactiverecord = ...
local set = require('lua-utils/orderedset')
return {
  tokens = {
    { keyset = set{"cmd", "c"} },
    { keyset = set{"cmd", "v"} },
    { keyset = set{"cmd", "tab"} },
  }
}
