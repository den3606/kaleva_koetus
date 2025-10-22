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

local function wither_pool(image_path)
  local id, w, h = ModImageMakeEditable(image_path, 0, 0)
  for i = 0, w - 1 do
    for j = 0, h - 1 do
      local color = ModImageGetPixel(id, i, j)
      -- water & mud & spawn_fish
      if bit.bxor(color, 0xff4c552f) == 0 or bit.bxor(color, 0xff213e36) == 0 or bit.bxor(color, 0xffafde03) == 0 then
        ModImageSetPixel(id, i, j, 0xff000000)
      end
    end
  end
end

function ascension:on_activate()
  -- log:info("Temple Alter's water withered")
  wither_pool("data/biome_impl/temple/altar.png")
  wither_pool("data/biome_impl/temple/altar_left.png")
end

return ascension
