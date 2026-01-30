-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local nxml = dofile_once("mods/kaleva_koetus/files/scripts/lib/luanxml/nxml.lua")

local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local EventTypes = EventDefs.Types
local LevelTags = EventDefs.Tags

---@type Beyond
local beyond = dofile("mods/kaleva_koetus/files/scripts/beyonds/base_beyond.lua")
beyond.level = 4
beyond.description = "$kaleva_koetus_description_b" .. beyond.level
beyond.specification = "$kaleva_koetus_specification_b" .. beyond.level

-- local log = Logger:new("b4.lua")

local b4_necromancer_key = LevelTags.B4 .. EventTypes.NECROMANCER_SPAWN

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

function beyond:on_mod_init()
  for content in nxml.edit_file("data/entities/buildings/workshop_guardian_spawn_pos.xml") do
    content:create_child("LuaComponent", {
      script_source_file = "mods/kaleva_koetus/files/scripts/beyonds/b4_spawn_guardian.lua",
      execute_every_n_frame = "180",
      remove_after_executed = "1",
    })
  end

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

  ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/kaleva_koetus/files/scripts/appends/boss_arena_drain.lua")
end

function beyond:on_world_initialized()
  if GlobalsGetValue(b4_necromancer_key, "0") == "1" then
    return
  end

  GlobalsSetValue("STEVARI_DEATHS", tostring(2))

  GlobalsSetValue(b4_necromancer_key, "1")
end

function beyond:on_necromancer_spawn(x, y)
  -- log:debug("Summoning guardians at %d,%d", x, y)
  local _ = EntityLoad("data/entities/animals/thunderskull.xml", x - 20, y)
  _ = EntityLoad("data/entities/animals/iceskull.xml", x + 20, y)
end

return beyond
