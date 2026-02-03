-- selene: allow(undefined_variable)
local _spawn_heart = spawn_heart

local function post_spawn_heart(x, y, max_id, ...)
  for entity_id = max_id + 1, EntitiesGetMaxID() do
    if EntityGetFilename(entity_id) == "data/entities/items/pickup/heart.xml" then
      EntityKill(entity_id)
      local _ = EntityLoad("mods/kaleva_koetus/files/entities/items/pickup/chest_fake.xml", x, y)
    end
  end
  return ...
end

-- selene: allow(unused_variable)
function spawn_heart(x, y, ...)
  local max_id = EntitiesGetMaxID()
  return post_spawn_heart(x, y, max_id, _spawn_heart(...))
end
