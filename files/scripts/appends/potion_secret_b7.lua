local MAGIC_REPLACE_CHANCE = 0.9

local extra_materials = {
  ["blood_worm"] = true,
  ["gold"] = true,
}
local magic_prefix = "magic_liquid_"
local function is_magic_material(material)
  if extra_materials[material] then
    return true
  end
  if string.sub(material, 1, #magic_prefix) == magic_prefix then
    return true
  end
  return false
end

-- selene: allow(undefined_variable)
local potions = potions
-- selene: allow(undefined_variable)
local _init = init

if not (potions and _init) then
  return
end

-- selene: allow(unused_variable)
function init(entity_id, ...)
  local x, y = EntityGetTransform(entity_id)
  SetRandomSeed(x + 200, y + 700)

  local magic_indexes = {}
  local materials_standard = {}

  for i, v in ipairs(potions) do
    local material = v.material
    if material ~= nil then
      if is_magic_material(material) then
        table.insert(magic_indexes, i)
      else
        table.insert(materials_standard, v)
      end
    end
  end

  local standard_count = #materials_standard
  if standard_count > 0 then
    for _, index in ipairs(magic_indexes) do
      if Random() < MAGIC_REPLACE_CHANCE then
        local replace_index = Random(1, standard_count)
        potions[index] = materials_standard[replace_index]
      end
    end
  end

  return _init(entity_id, ...)
end
