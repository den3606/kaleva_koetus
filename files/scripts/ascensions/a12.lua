-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

-- local log = Logger:new("a12.lua")

ascension.level = 12
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A12 .. "unused"

-- selene: allow(undefined_variable)
local bit = bit

local function wither_pool(image_path, should_clean)
  local id, w, h = ModImageMakeEditable(image_path, 0, 0)
  for j = h - 1, 0, -1 do
    for i = 0, w - 1 do
      local color = ModImageGetPixel(id, i, j)
      if should_clean(color) == true then
        ModImageSetPixel(id, i, j, 0xff000000)
      end
    end
  end
end

function ascension:on_activate()
  -- log:info("Temple Alter's water withered")
  local color_water = 0xff4c552f
  local color_mud = 0xff213e36
  local color_spawn_fish = 0xffafde03

  local water_to_left = 400
  local function clean_with_lease(color)
    if bit.bxor(color, color_water) == 0 then
      if water_to_left <= 0 then
        return true
      else
        water_to_left = water_to_left - 1
        return false
      end
    end
    if bit.bxor(color, color_mud) == 0 or bit.bxor(color, color_spawn_fish) == 0 then
      return true
    end
    return false
  end
  wither_pool("data/biome_impl/temple/altar.png", clean_with_lease)

  local function clean_all(color)
    if bit.bxor(color, color_water) == 0 or bit.bxor(color, color_mud) == 0 or bit.bxor(color, color_spawn_fish) == 0 then
      return true
    end
    return false
  end
  wither_pool("data/biome_impl/temple/altar_left.png", clean_all)

  ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/kaleva_koetus/files/scripts/appends/boss_arena_a12.lua")
end

return ascension
