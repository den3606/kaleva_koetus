local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
local EventDefs = dofile_once("mods/kaleva_koetus/files/scripts/event_types.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local AscensionTags = EventDefs.Tags

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A12")

local FRAMES_PER_SECOND = 60
local LIMIT_SECONDS = 90 * 60 -- 1時間30分
local LIMIT_FRAMES = LIMIT_SECONDS * FRAMES_PER_SECOND
local DAMAGE_INTERVAL_FRAMES = FRAMES_PER_SECOND
local DAMAGE_PER_TICK = 0.04 -- 1HP相当

ascension.level = 12
ascension.name = "時間制限"
ascension.description = "1時間30分経過後、1秒ごとに1HPのスリップダメージ"
ascension.tag_name = AscensionTags.A12 .. "_exhaustion"

ascension._start_frame = nil
ascension._last_damage_frame = nil
ascension._limit_reached = false

local function apply_damage(self, current_frame)
  if not self._limit_reached then
    self._limit_reached = true
    GamePrintImportant("The world rejects your lingering...", "Slip damage begins!")
    log:info("Time limit reached; slip damage started")
  end

  if self._last_damage_frame and current_frame - self._last_damage_frame < DAMAGE_INTERVAL_FRAMES then
    return
  end

  local player_entity_id = GetPlayerEntity()
  if not player_entity_id then
    return
  end

  EntityAddTag(player_entity_id, ascension.tag_name)
  self._last_damage_frame = current_frame
  EntityInflictDamage(player_entity_id, DAMAGE_PER_TICK, "DAMAGE_POISON", "Ascension Exhaustion", "NONE", 0, 0)
end

function ascension:on_activate()
  self._start_frame = GameGetFrameNum()
  log:info("Time limit engaged (%.0f minutes)", LIMIT_SECONDS / 60)
end

function ascension:on_update()
  if not self._start_frame then
    self._start_frame = GameGetFrameNum()
  end

  local current_frame = GameGetFrameNum()
  local elapsed = current_frame - self._start_frame
  if elapsed >= LIMIT_FRAMES then
    apply_damage(self, current_frame)
  end
end

return ascension
