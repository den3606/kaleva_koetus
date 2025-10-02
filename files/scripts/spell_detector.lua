local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")

local SpellDetector = {}

local log = Logger:new("spell_detector.lua")

function SpellDetector:init(called_from)
  self.tag_name = "kk_card_detected" .. "_" .. called_from
  log:debug("Initialized")
end

function SpellDetector:get_unprocessed_spells()
  if self.latest_entity_id == EntitiesGetMaxID() then
    return {}
  end
  self.latest_entity_id = EntitiesGetMaxID()

  local all_spells = EntityGetWithTag("card_action")
  if #all_spells == 0 then
    return {}
  end

  local unprocessed_cards = {}
  for _, entity_id in ipairs(all_spells) do
    if not EntityHasTag(entity_id, self.tag_name) then
      EntityAddTag(entity_id, self.tag_name)

      unprocessed_cards[#unprocessed_cards + 1] = {
        id = entity_id,
      }
    end
  end

  return unprocessed_cards
end

return SpellDetector
