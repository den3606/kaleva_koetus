local Logger = KalevaLogger
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/player.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A16")

local DRY_INTERVAL_FRAMES = 30
local CONVERT_RADIUS = 72

local WATER_MATERIAL = CellFactory_GetType("water")
local WATER_SWAMP_MATERIAL = CellFactory_GetType("swamp")
local AIR_MATERIAL = CellFactory_GetType("air")

ascension.level = 16
ascension.name = "山の水減少"
ascension.description = "ホーリーマウンテンの水が大幅に減少する"

ascension._next_dry_frame = nil
ascension._notified_levels = {}

local function spawn_water_dryer(x, y)
  local converter = EntityCreateNew("kaleva_a16_water_dryer")
  EntitySetTransform(converter, x, y)

  EntityAddComponent2(converter, "MagicConvertMaterialComponent", {
    radius = CONVERT_RADIUS,
    steps_per_frame = 4,
    is_circle = true,
    loop = false,
    kill_when_finished = true,
    from_material = WATER_MATERIAL,
    to_material = AIR_MATERIAL,
  })

  EntityAddComponent2(converter, "MagicConvertMaterialComponent", {
    radius = CONVERT_RADIUS,
    steps_per_frame = 2,
    is_circle = true,
    loop = false,
    kill_when_finished = true,
    from_material = WATER_SWAMP_MATERIAL,
    to_material = AIR_MATERIAL,
  })

  EntityAddComponent2(converter, "LifetimeComponent", {
    lifetime = 2,
  })
end

local function is_in_mountain(biome_name)
  return biome_name and string.find(biome_name, "temple", 1, true) ~= nil
end

function ascension:on_activate()
  log:info("Mountain water reduction enabled")
  self._next_dry_frame = GameGetFrameNum()
end

function ascension:on_update()
  local player_entity_id = GetPlayerEntity()
  if not player_entity_id then
    return
  end

  local current_frame = GameGetFrameNum()
  if self._next_dry_frame and current_frame < self._next_dry_frame then
    return
  end

  local px, py = EntityGetTransform(player_entity_id)
  local biome_name = BiomeMapGetName(px, py)

  if not is_in_mountain(biome_name) then
    self._next_dry_frame = current_frame + DRY_INTERVAL_FRAMES
    return
  end

  spawn_water_dryer(px - 60, py + 20)
  spawn_water_dryer(px + 60, py + 20)

  local level_key = math.floor(py / 512)
  if not self._notified_levels[level_key] then
    GamePrintImportant("Holy Mountain dries up", "The pool is only half-full now...")
    log:debug("Holy Mountain water reduced for level %d", level_key)
    self._notified_levels[level_key] = true
  end

  self._next_dry_frame = current_frame + DRY_INTERVAL_FRAMES
end

return ascension
