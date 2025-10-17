local get_modifier_mappings_origin = get_modifier_mappings

local function pick_random_biome_modifier_for_biomes(rnd, biome_modifiers, target_biomes)
  local biome_modifiers_left = {}
  for _, modifier in ipairs(biome_modifiers) do
    for _, biome_name in ipairs(target_biomes) do
      -- selene: allow(undefined_variable)
      if biome_modifier_applies_to_biome(modifier, biome_name) == true then
        table.insert(biome_modifiers_left, modifier)
        break
      end
    end
  end
  -- selene: allow(undefined_variable)
  return pick_random_from_table_weighted(rnd, biome_modifiers_left)
end

-- selene: allow(unused_variable)
function get_modifier_mappings()
  local result = get_modifier_mappings_origin()

  -- selene: allow(undefined_variable, unscoped_variables)
  rnd = random_create(347893, 90734)

  -- selene: allow(undefined_variable)
  for _, biome_names in ipairs(biomes) do
    while true do
      local target_biomes = {}
      for _, biome_name in ipairs(biome_names) do
        if result[biome_name] == nil then
          table.insert(target_biomes, biome_name)
        end
      end
      if #target_biomes == 0 then
        break
      end

      -- selene: allow(undefined_variable)
      local modifier = pick_random_biome_modifier_for_biomes(rnd, biome_modifiers, target_biomes)
      if modifier == nil then
        break
      end

      for _, biome_name in ipairs(target_biomes) do
        -- selene: allow(undefined_variable)
        if biome_modifier_applies_to_biome(modifier, biome_name) then
          result[biome_name] = modifier
        end
      end
    end
  end

  return result
end
