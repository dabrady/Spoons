local chooser_ext = {}

-- Takes a list of strings and creates a choice table formatted such that
-- it is acceptable by hs.chooser:choices
function chooser_ext.generateChoiceTable(list)
  if list == nil or #list == 0 then
    return {}
  end

  local choiceTable = {}
  for _,item in ipairs(list) do
    table.insert(choiceTable, { text = item..'' })
  end

  return choiceTable
end

------

return chooser_ext
