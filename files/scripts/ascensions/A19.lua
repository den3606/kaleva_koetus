local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A19")

local REFRESHER_PATHS = {
  ["data/entities/items/pickup/perk_reroll.xml"] = true,
  ["data/entities/items/pickup/perk_reroll_right.xml"] = true,
}

ascension.level = 19
ascension.name = "リフレッシャーなし"
ascension.description = "ホーリーマウンテンにリフレッシャーが出現しなくなる"
ascension.tag_name = AscensionTags.A19 .. "_removed"

ascension._notified_levels = {}

local function remove_refreshers(player_entity_id)
  local px, py = EntityGetTransform(player_entity_id)
  local candidates = EntityGetInRadiusWithTag(px, py, 256, "item_pickup") or {}
  local removed = false

  for _, entity_id in ipairs(candidates) do
    local filename = EntityGetFilename(entity_id)
    if filename and REFRESHER_PATHS[filename] and not EntityHasTag(entity_id, ascension.tag_name) then
      EntityAddTag(entity_id, ascension.tag_name)
      EntityKill(entity_id)
      removed = true
    end
  end

  if removed then
    local level_key = math.floor(py / 512)
    if not ascension._notified_levels[level_key] then
      GamePrintImportant("No perk refreshers", "The shrine offers no second chances.")
      ascension._notified_levels[level_key] = true
      log:debug("Removed perk refresher for level %d", level_key)
    end
  end
end

function ascension:on_activate()
  log:info("Perk refreshers disabled")
end

function ascension:on_update()
  local player_entity_id = GetPlayerEntity()
  if not player_entity_id then
    return
  end

  local px, py = EntityGetTransform(player_entity_id)
  local biome_name = BiomeMapGetName(px, py)
  if biome_name and string.find(biome_name, "temple", 1, true) then
    remove_refreshers(player_entity_id)
  end
end

return ascension
