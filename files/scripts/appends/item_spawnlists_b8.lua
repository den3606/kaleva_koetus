local ITEM_SPAWN_CHANCE = 0.5

-- selene: allow(undefined_variable)
local _spawn_from_list = spawn_from_list

-- selene: allow(unused_variable)
function spawn_from_list(listname, x, y, ...)
  if type(listname) == "table" then
    return _spawn_from_list(listname, x, y, ...)
  end

  SetRandomSeed(x + 200, y + 800)
  if Random() < ITEM_SPAWN_CHANCE then
    return _spawn_from_list(listname, x, y, ...)
  end
end
