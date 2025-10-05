local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")
local ImageEditor = dofile_once("mods/kaleva_koetus/files/scripts/image_editor.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:new("a17.lua")

ascension.level = 17
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level
ascension.tag_name = AscensionTags.A16 .. "dummy"

function ascension:on_activate()
  log:info("follow bird")

  local target_images = {
    "data/particles/radar_enemy_faint.png",
    "data/particles/radar_enemy_medium.png",
    "data/particles/radar_enemy_strong.png",
  }

  for index, image in ipairs(target_images) do
    local id, x, y = ModImageMakeEditable(image, 0, 0)
    local a17_id = ModImageMakeEditable("kk/a17/" .. image, x, y)
    for i = 0, x, 1 do
      for j = 0, y, 1 do
        local color = ModImageGetPixel(id, i, j)
        local inverted = ImageEditor:invert_hue_abgr(color)
        ModImageSetPixel(a17_id, i, j, inverted)
      end
    end
  end

  -- NOTE:
end

function ascension:on_player_spawn(player_entity_id)
  local x, y = EntityGetTransform(player_entity_id)
  EntityAddComponent(player_entity_id, "LuaComponent", {
    _tags = "perk_component",
    script_source_file = "mods/kaleva_koetus/files/scripts/ascensions/a17_crow_radar.lua",
    execute_every_n_frame = "1",
  })
  local crow_entity_id = EntityLoad("mods/kaleva_koetus/files/entities/misc/following_crow.xml", x, y)
  EntityAddTag(crow_entity_id, "kk_a17_crow")
  EntityAddComponent(crow_entity_id, "VariableStorageComponent", {
    name = "owner_id",
    value_int = tostring(player_entity_id),
  })
end

return ascension
