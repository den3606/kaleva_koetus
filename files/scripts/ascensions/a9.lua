-- local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_hub/event_types.lua")

local AscensionTags = EventDefs.Tags

---@type Ascension
local ascension = dofile("mods/kaleva_koetus/files/scripts/ascensions/base_ascension.lua")
ascension.level = 9
ascension.description = "$kaleva_koetus_description_a" .. ascension.level
ascension.specification = "$kaleva_koetus_specification_a" .. ascension.level

-- local log = Logger:new("a9.lua")

local MIN_PERK_COUNT = 2

local a9_reduce_perk_key = AscensionTags.A9 .. "perk_reduced"

local function determine_target_perk_count()
  local default = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3")) or 3
  return math.max(MIN_PERK_COUNT, default - 1)
end

local function enforce_perk_count(target)
  local current = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "-1")) or target

  if current ~= target then
    GlobalsSetValue("TEMPLE_PERK_COUNT", tostring(target))
    -- log:debug("Updated temple perk count %d -> %d", current, target)
  end
end

function ascension:on_mod_init()
  -- log:info("Activate Temple perks limit")
end

function ascension:on_world_initialized()
  if GlobalsGetValue(a9_reduce_perk_key, "0") == "1" then
    return
  end

  local target_perk_count = determine_target_perk_count()
  -- log:debug("Temple perks limited to %d", self._target_perk_count)

  enforce_perk_count(target_perk_count)

  GlobalsSetValue(a9_reduce_perk_key, "1")
end

return ascension
