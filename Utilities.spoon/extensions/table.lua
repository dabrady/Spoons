local table_ext = {}

-- Handy (shallow) table print function
function table_ext.print(t)
  if type(t) ~= 'table' then return nil end

  for k,v in pairs(t) do
    print(tostring(k)..' \t'..tostring(v))
  end
end

-- Returns a list of the keys of the given table.
function table_ext.keys(t)
  if type(t) ~= 'table' then return nil end

  local keys = {}
  for k,_ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end


-----------------
--
-- Functions of varying complexity levels to achieve
-- a table copy in Lua.
--


-- 1. The Problem.
--
-- Here's an example to see why deep copies are useful.
-- Let's say function f receives a table parameter t,
-- and it wants to locally modify that table without
-- affecting the caller. This code fails:
--
-- function f(t)
--  t.a = 3
-- end
--
-- local my_t = {a = 5}
-- f(my_t)
-- print(my_t.a)  --> 3
--
-- This behavior can be hard to work with because, in
-- general, side effects such as input modifications
-- make it more difficult to reason about program
-- behavior.


-- 2. The easy solution.

function table_ext.copy(obj)
  if type(obj) ~= 'table' then return obj end

  -- Preserve metatables.
  local res = setmetatable({}, getmetatable(obj))

  for k, v in pairs(obj) do res[table_ext.copy(k)] = table_ext.copy(v) end
  return res
end

-- This functions works well for simple tables. Since
-- it is a clear, concise function, and since I most
-- often work with simple tables, this is my favorite
-- version.

-- 3. Supporting recursive structures.
--
-- The issue here is that the following code will
-- get stuck in an infinite loop:
--
-- local my_t = {}
-- my_t.a = my_t
-- local t_copy = table.simpleCopy(my_t, true)
--
-- This happens when trying to make a copy of my_t.a,
-- which involves making a copy of my_t.a.a, which
-- involves making a copy of my_t.a.a.a, etc. The
-- recursive table my_t is perfectly legal, and it's
-- possible to make a deep_copy function that can
-- handle this by tracking which tables it has already
-- started to copy.

function table_ext.deepCopy(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen an copy recursively.
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table_ext.deepCopy(k, s)] = table_ext.deepCopy(v, s) end
  return res
end

-- Simple utility for mergint two tables.
function table_ext.merge(t1, t2)
  for k,v in pairs(t2) do t1[k] = v end
  return t1
end

----------

return table_ext
