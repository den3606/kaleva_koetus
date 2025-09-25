local Logger = dofile_once("mods/kaleva_koetus/files/scripts/lib/logger.lua")
local AscensionBase = dofile_once("mods/kaleva_koetus/files/scripts/ascensions/ascension_subscriber.lua")
dofile_once("mods/kaleva_koetus/files/scripts/lib/utils/variable_storage.lua")

local ascension = setmetatable({}, { __index = AscensionBase })

local log = Logger:bind("A20")

local AIR_MATERIAL = CellFactory_GetType("air")

local MOUNTAIN_BREAKER_RADIUS = 130
local MOUNTAIN_BREAKER_Y = -140
local MOUNTAIN_BREAK_FRAMES = 30
local BOSS_HP_MULTIPLIER = 2.5

ascension.level = 20
ascension.name = "最終試練"
ascension.description = "コルミが5オーブ状態で出現し、山頂が崩壊する"
ascension.tag_name = "kaleva_a20_buffed"

ascension._mountain_broken = false
ascension._boss_buffed = {}

local function break_mountain_top()
  local breaker = EntityCreateNew("kaleva_a20_mountain_breaker")
  EntitySetTransform(breaker, 0, MOUNTAIN_BREAKER_Y)

  EntityAddComponent2(breaker, "MagicConvertMaterialComponent", {
    radius = MOUNTAIN_BREAKER_RADIUS,
    steps_per_frame = 12,
    loop = false,
    kill_when_finished = true,
    from_any_material = true,
    to_material = AIR_MATERIAL,
    is_circle = true,
  })

  EntityAddComponent2(breaker, "LifetimeComponent", {
    lifetime = 4,
  })

  GamePrintImportant("The holy mountain trembles", "The summit collapses under the strain!")
  log:info("Holy Mountain summit collapsed")
end

local function buff_boss(enemy_entity_id)
  if ascension._boss_buffed[enemy_entity_id] then
    return
  end

  local damage_model = EntityGetFirstComponentIncludingDisabled(enemy_entity_id, "DamageModelComponent")
  if damage_model then
    local hp = ComponentGetValue2(damage_model, "hp") or 0
    local max_hp = ComponentGetValue2(damage_model, "max_hp") or 0
    local new_hp = hp * BOSS_HP_MULTIPLIER
    local new_max_hp = max_hp * BOSS_HP_MULTIPLIER
    ComponentSetValue2(damage_model, "hp", new_hp)
    ComponentSetValue2(damage_model, "max_hp", new_max_hp)
  end

  AddNewInternalVariable(enemy_entity_id, "kaleva_a20_orb_count", "value_int", 5)
  EntityAddTag(enemy_entity_id, ascension.tag_name)
  ascension._boss_buffed[enemy_entity_id] = true

  GamePrintImportant("Kolmi awakens empowered", "The final trial begins!")
  log:info("Buffed Kolmi (entity %d) with %d× HP", enemy_entity_id, BOSS_HP_MULTIPLIER)
end

function ascension:on_activate()
  log:info("Final trial engaged")
  GlobalsSetValue("TEMPLE_BOSS_ORB_COUNT", "5")
end

function ascension:on_update()
  if self._mountain_broken then
    return
  end

  if GameGetFrameNum() > MOUNTAIN_BREAK_FRAMES then
    break_mountain_top()
    self._mountain_broken = true
  end
end

function ascension:on_enemy_spawn(payload)
  local enemy_entity_id = tonumber(payload[1])
  if not enemy_entity_id or enemy_entity_id == 0 then
    return
  end

  if EntityHasTag(enemy_entity_id, "boss_centipede") then
    buff_boss(enemy_entity_id)
  end
end

return ascension
