local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local MIN_PERK_COUNT = 1

local log = Logger:bind("A9")

ascension.level = 9
ascension.name = "パーク数減少"
ascension.description = "ホーリーマウンテンのパークが1つ減る"

ascension._target_perk_count = nil

local function determine_target_perk_count()
  local default = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3")) or 3
  local target = math.max(MIN_PERK_COUNT, default - 1)
  return target
end

local function enforce_perk_count(target)
  local current = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", tostring(target))) or target
  if current ~= target then
    GlobalsSetValue("TEMPLE_PERK_COUNT", tostring(target))
  end
end

function ascension:on_activate()
  self._target_perk_count = determine_target_perk_count()
  enforce_perk_count(self._target_perk_count)
  log:info("Temple perks limited to %d", self._target_perk_count)
end

function ascension:on_update()
  if not self._target_perk_count then
    self._target_perk_count = determine_target_perk_count()
  end
  enforce_perk_count(self._target_perk_count)
end

return ascension
