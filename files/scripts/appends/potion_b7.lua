local MAGIC_REPLACE_CHANCE = 0.9

-- selene: allow(undefined_variable)
local materials_standard = materials_standard
-- selene: allow(undefined_variable)
local materials_magic = materials_magic
-- selene: allow(undefined_variable)
local _init = init

if not (materials_standard and materials_magic and _init) then
  return
end

-- selene: allow(unused_variable)
function init(entity_id, ...)
  local x, y = EntityGetTransform(entity_id)
  SetRandomSeed(x + 200, y + 700)

  local standard_count = #materials_standard
  local magic_count = #materials_magic

  if standard_count > 0 then
    for i = 1, magic_count do
      if Random() < MAGIC_REPLACE_CHANCE then
        local replace_index = Random(1, standard_count)
        materials_magic[i] = materials_standard[replace_index]
      end
    end
  end

  return _init(entity_id, ...)
end
