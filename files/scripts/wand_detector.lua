-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

local WandDetector = {}

-- local log = Logger:new("wand_detector.lua")

function WandDetector:init(called_from)
  self.tag_name = "kk_wand_detected" .. "_" .. called_from
  -- log:debug("Initialized")
end

function WandDetector:get_unprocessed_wands()
  if self.latest_entity_id == EntitiesGetMaxID() then
    return {}
  end
  self.latest_entity_id = EntitiesGetMaxID()

  local all_wands = EntityGetWithTag("wand")
  if #all_wands == 0 then
    return {}
  end

  local unprocessed_wands = {}
  for _, entity_id in ipairs(all_wands) do
    if not EntityHasTag(entity_id, self.tag_name) then
      EntityAddTag(entity_id, self.tag_name)

      unprocessed_wands[#unprocessed_wands + 1] = {
        id = entity_id,
      }
    end
  end

  return unprocessed_wands
end

return WandDetector
